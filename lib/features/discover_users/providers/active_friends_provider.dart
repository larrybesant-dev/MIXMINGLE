// lib/features/discover_users/providers/active_friends_provider.dart
//
// Riverpod state for the "Active Friends" social layer on the Home tab.
//
// ─ activeFriendsProvider ── Stream<List<UserPresence>>
//     Watches myFriendsProvider and streams a real-time merged list of
//     each friend's presence from /user_presence/{uid}.  Caps at 12 entries
//     (widget only shows ~8 anyway).
//
// ─ onlineFriendCountProvider ── int
//     Convenience count for instant badge display.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/room/services/user_presence_service.dart';
import '../../../shared/models/friend_request.dart';
import '../../../shared/providers/friend_providers.dart';

// ── Firestore helpers ─────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;

/// How old a lastSeen timestamp can be and still count as "recently active".
const _kActiveWindow = Duration(hours: 2);

/// Build a UserPresence from a FriendEntry + optional live snap data.
UserPresence _presenceFromFriend(
  FriendEntry friend, [
  Map<String, dynamic>? snap,
]) {
  final statusIdx = snap?['status'] as int?;
  final lastSeenTs = snap?['lastSeen'] as Timestamp?;
  final lastSeen = lastSeenTs?.toDate() ?? friend.since;
  final isRecent = DateTime.now().difference(lastSeen) < _kActiveWindow;

  PresenceStatus status;
  if (statusIdx != null && statusIdx < PresenceStatus.values.length) {
    status = PresenceStatus.values[statusIdx];
  } else if (isRecent) {
    status = PresenceStatus.away;
  } else {
    status = PresenceStatus.offline;
  }

  return UserPresence(
    userId: friend.uid,
    displayName: snap?['displayName'] as String? ??
        friend.displayName ??
        'Friend',
    avatarUrl: snap?['avatarUrl'] as String? ?? friend.avatarUrl ?? '',
    status: status,
    lastSeen: lastSeen,
    roomId: snap?['roomId'] as String?,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Real-time stream of up to 12 friends with their presence status.
///
/// Implementation note: Firestore doesn't support range queries on doc IDs,
/// so we open one snapshot listener per friend (capped at 12).  Each listener
/// is closed when the provider is disposed.
final activeFriendsProvider = StreamProvider<List<UserPresence>>((ref) {
  final friendsAsync = ref.watch(myFriendsProvider);
  final friends = friendsAsync.value ?? [];

  // Limit to avoid too many open listeners.
  final capped = friends.take(12).toList();

  if (capped.isEmpty) {
    return Stream.value([]);
  }

  // Build a stream for each friend's presence document.
  final streams = capped.map((friend) {
    return _db
        .collection('user_presence')
        .doc(friend.uid)
        .snapshots()
        .map((snap) => _presenceFromFriend(
              friend,
              snap.exists ? snap.data() : null,
            ));
  }).toList();

  // Merge streams into a single list using StreamController + combineLatest
  // pattern (no external package needed).
  final controller = StreamController<List<UserPresence>>();
  final latest = List<UserPresence?>.filled(capped.length, null);
  final subs = <StreamSubscription>[];

  for (var i = 0; i < streams.length; i++) {
    final idx = i;
    subs.add(streams[idx].listen(
      (presence) {
        latest[idx] = presence;
        // Emit when all slots have data.
        if (latest.every((p) => p != null)) {
          final sorted = latest
              .whereType<UserPresence>()
              .toList()
            ..sort((a, b) {
              // Online first, then away, then offline.
              final order = {
                PresenceStatus.online: 0,
                PresenceStatus.away: 1,
                PresenceStatus.doNotDisturb: 2,
                PresenceStatus.offline: 3,
              };
              return (order[a.status] ?? 3)
                  .compareTo(order[b.status] ?? 3);
            });
          if (!controller.isClosed) controller.add(sorted);
        }
      },
      onError: (_) {},
    ));
  }

  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
    controller.close();
  });

  return controller.stream;
});

// ── Convenience providers ─────────────────────────────────────────────────────

/// Count of friends whose presence status is `online`.
final onlineFriendCountProvider = Provider<int>((ref) {
  final presence = ref.watch(activeFriendsProvider).value ?? [];
  return presence
      .where((p) => p.status == PresenceStatus.online)
      .length;
});

/// Sorted list — online + away (recently active) friends only.
/// Used when you only want to show "active now" rows (hides offline).
final activeOnlyFriendsProvider = Provider<List<UserPresence>>((ref) {
  final all = ref.watch(activeFriendsProvider).value ?? [];
  return all
      .where((p) =>
          p.status == PresenceStatus.online ||
          p.status == PresenceStatus.away)
      .toList();
});
