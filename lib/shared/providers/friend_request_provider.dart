import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social/friend_service.dart';
import 'auth_providers.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

// ── Friend status with a specific user ───────────────────────────────────────

final friendStatusProvider =
    StreamProvider.family<FriendRequestStatus, String>((ref, userId) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(FriendRequestStatus.none);
  return ref.read(friendServiceProvider).watchFriendStatus(userId);
});

// ── Incoming friend requests ──────────────────────────────────────────────────

final incomingFriendRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(friendServiceProvider).watchIncomingRequests();
});

/// Count for badge indicators on nav bar / friend list tab.
final pendingFriendRequestCountProvider = Provider<int>((ref) {
  return ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (reqs) => reqs.length,
    orElse: () => 0,
  );
});

// ── Friend IDs stream ──────────────────────────────────────────────────────────

final friendIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(friendServiceProvider).watchFriendIds();
});

/// Streams friend IDs for any arbitrary [userId] (used on profile pages).
final friendIdsOfUserProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.read(friendServiceProvider).watchFriendIdsOf(userId);
});

// ── Is blocked by me ───────────────────────────────────────────────────────────
/// Streams true if the current user has blocked [targetUserId].
final isBlockedByMeProvider =
    StreamProvider.family<bool, String>((ref, targetUserId) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(false);
  return ref.read(friendServiceProvider).watchBlockedStatus(targetUserId);
});

// ── Mutual friends ─────────────────────────────────────────────────────────────
/// Fetches friend IDs shared between the current user and [otherUserId].
final mutualFriendsProvider =
    FutureProvider.family<List<String>, String>((ref, otherUserId) async {
  final myIds = await ref.watch(friendIdsProvider.future);
  final svc = ref.read(friendServiceProvider);
  final otherIds = await svc.getFriendIds(otherUserId);
  return myIds.toSet().intersection(otherIds.toSet()).toList();
});

// ── Friend suggestions ─────────────────────────────────────────────────────────
/// Friends-of-friends who are not yet friends with the current user.
final friendSuggestionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final myIds = await ref.watch(friendIdsProvider.future);
  if (myIds.isEmpty) return [];
  final svc = ref.read(friendServiceProvider);
  // Collect friends-of-friends
  final candidateCounts = <String, int>{};
  for (final friendId in myIds.take(20)) {
    final theirFriends = await svc.getFriendIds(friendId);
    for (final id in theirFriends) {
      if (id != FirebaseAuth.instance.currentUser?.uid && !myIds.contains(id)) {
        candidateCounts[id] = (candidateCounts[id] ?? 0) + 1;
      }
    }
  }
  final sorted = candidateCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted
      .take(20)
      .map((e) => {'uid': e.key, 'mutualCount': e.value})
      .toList();
});
