// lib/features/discover/providers/room_discovery_providers.dart
//
// Riverpod state for Room Discovery: vibe filter, category filter,
// search query, and derived filtered room lists.
// Phase 1 additions: trendingRoomsProvider, newRoomsProvider,
// friendsInRoomsProvider, recommendedRoomsProvider, roomDiscoveryCombinedProvider
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/room.dart';
import '../../../shared/models/friend_request.dart';
import '../../../shared/providers/friend_providers.dart';
import '../../room/providers/room_providers.dart' show liveRoomsProvider;

// ── Filter state notifiers ────────────────────────────────────────────────────

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

/// Currently selected vibe filter. Empty string = show all.
final discoveryVibeFilterProvider =
    NotifierProvider.autoDispose<_StringNotifier, String>(
        _StringNotifier.new);

/// Currently selected category filter. Empty string = show all.
final discoveryCategoryFilterProvider =
    NotifierProvider.autoDispose<_StringNotifier, String>(
        _StringNotifier.new);

/// Live search query text.
final discoverySearchQueryProvider =
    NotifierProvider.autoDispose<_StringNotifier, String>(
        _StringNotifier.new);

// ── Filtered rooms provider ───────────────────────────────────────────────────

/// All live rooms filtered by active vibe, category, and search query.
final filteredLiveRoomsProvider =
    Provider.autoDispose<AsyncValue<List<Room>>>((ref) {
  final roomsAsync = ref.watch(liveRoomsProvider);
  final vibe = ref.watch(discoveryVibeFilterProvider);
  final category = ref.watch(discoveryCategoryFilterProvider);
  final query = ref.watch(discoverySearchQueryProvider).toLowerCase().trim();

  return roomsAsync.whenData((rooms) {
    var filtered = rooms;

    // Vibe filter
    if (vibe.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.vibeTag?.toLowerCase() == vibe.toLowerCase())
          .toList();
    }

    // Category filter
    if (category.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    // Search query
    if (query.isNotEmpty) {
      filtered = filtered.where((r) {
        final title = r.title.toLowerCase();
        final desc = r.description.toLowerCase();
        final host = r.hostName?.toLowerCase() ?? '';
        final tags = r.tags.join(' ').toLowerCase();
        return title.contains(query) ||
            desc.contains(query) ||
            host.contains(query) ||
            tags.contains(query);
      }).toList();
    }

    return filtered;
  });
});

// ── Heating-up rooms ──────────────────────────────────────────────────────────

/// Top rooms by joinVelocity + viewerCount composite score.
final heatingUpRoomsProvider =
    Provider.autoDispose<List<Room>>((ref) {
  final roomsAsync = ref.watch(liveRoomsProvider);
  final rooms = roomsAsync.value ?? [];
  final sorted = [...rooms]..sort((a, b) {
      final aScore = (a.joinVelocity * 2) + a.viewerCount;
      final bScore = (b.joinVelocity * 2) + b.viewerCount;
      return bScore.compareTo(aScore);
    });
  return sorted.take(8).toList();
});

// ── Featured (boosted) rooms ──────────────────────────────────────────────────

/// Rooms with boostScore > 0, sorted by boostScore desc.
final featuredRoomsProvider =
    Provider.autoDispose<List<Room>>((ref) {
  final roomsAsync = ref.watch(liveRoomsProvider);
  final rooms = roomsAsync.value ?? [];
  final boosted = rooms.where((r) => r.boostScore > 0).toList()
    ..sort((a, b) => b.boostScore.compareTo(a.boostScore));
  return boosted.take(5).toList();
});

// ── Room count by category ────────────────────────────────────────────────────

/// Map of category → count of live rooms in that category.
final roomCountByCategoryProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final rooms = ref.watch(liveRoomsProvider).value ?? [];
  final map = <String, int>{};
  for (final room in rooms) {
    map[room.category] = (map[room.category] ?? 0) + 1;
  }
  return map;
});
// ── Friends-in-room ───────────────────────────────────────────────────────────

/// Friends of the current user who are currently in a specific room (by roomId).
/// Cross-references room.participantIds with the current user's friends list.
final friendsInRoomProvider =
    Provider.autoDispose.family<List<FriendEntry>, String>((ref, roomId) {
  final rooms = ref.watch(liveRoomsProvider).value ?? [];
  final room = rooms.cast<Room?>().firstWhere(
        (r) => r?.id == roomId,
        orElse: () => null,
      );
  if (room == null) return [];
  final friends = ref.watch(myFriendsProvider).value ?? [];
  final participantSet = Set<String>.from(room.participantIds);
  return friends.where((f) => participantSet.contains(f.uid)).toList();
});

// ── Recommended rooms ─────────────────────────────────────────────────────────

/// Rooms scored by:
///   • Friends present   → +15 pts each
///   • Join velocity      → +3 pts each join/min
///   • Viewer count       → +0.2 pts per viewer
///   • Boost score        → added directly
/// Returns up to 10 results, de-duped from heatingUpRoomsProvider.
final recommendedRoomsProvider = Provider.autoDispose<List<Room>>((ref) {
  final rooms = ref.watch(liveRoomsProvider).value ?? [];
  if (rooms.isEmpty) return [];
  final friendUids = Set<String>.from(
    (ref.watch(myFriendsProvider).value ?? []).map((f) => f.uid),
  );

  double score(Room r) {
    final friendsHere = r.participantIds.where(friendUids.contains).length;
    return (friendsHere * 15.0) +
        (r.joinVelocity * 3.0) +
        (r.viewerCount * 0.2) +
        r.boostScore;
  }

  final sorted = [...rooms]..sort((a, b) => score(b).compareTo(score(a)));
  return sorted.take(20).toList();
});

// ── Phase 1: New Discovery Section Providers ─────────────────────────────────

/// Trending rooms: top 20 by viewerCount desc.
final trendingRoomsProvider = Provider.autoDispose<List<Room>>((ref) {
  final rooms = ref.watch(liveRoomsProvider).value ?? [];
  final sorted = [...rooms]
    ..sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
  return sorted.take(20).toList();
});

/// New rooms: most recently created, limit 20.
final newRoomsProvider = Provider.autoDispose<List<Room>>((ref) {
  final rooms = ref.watch(liveRoomsProvider).value ?? [];
  final sorted = [...rooms]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.take(20).toList();
});

/// Rooms where at least one friend is in the participant list.
final friendsInRoomsProvider = Provider.autoDispose<List<Room>>((ref) {
  final rooms = ref.watch(liveRoomsProvider).value ?? [];
  final friendUids = Set<String>.from(
    (ref.watch(myFriendsProvider).value ?? []).map((f) => f.uid),
  );
  if (friendUids.isEmpty) return [];
  return rooms
      .where((r) => r.participantIds.any(friendUids.contains))
      .toList();
});

/// Combined discovery data class for the RoomDiscoveryPage.
class DiscoveryCombinedData {
  final List<Room> trending;
  final List<Room> newRooms;
  final List<Room> friendsInRooms;
  final List<Room> recommended;
  final bool isLoading;

  const DiscoveryCombinedData({
    required this.trending,
    required this.newRooms,
    required this.friendsInRooms,
    required this.recommended,
    this.isLoading = false,
  });
}

/// Merges all discovery sections into one model for the UI.
final roomDiscoveryCombinedProvider =
    Provider.autoDispose<DiscoveryCombinedData>((ref) {
  final liveAsync = ref.watch(liveRoomsProvider);
  final isLoading = liveAsync.isLoading;
  return DiscoveryCombinedData(
    trending: ref.watch(trendingRoomsProvider),
    newRooms: ref.watch(newRoomsProvider),
    friendsInRooms: ref.watch(friendsInRoomsProvider),
    recommended: ref.watch(recommendedRoomsProvider),
    isLoading: isLoading,
  );
});


// ── Filter state notifiers ────────────────────────────────────────────────────
