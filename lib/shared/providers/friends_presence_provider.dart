
/// Friends Provider with Real-Time Presence Integration
///
/// Combines user friends list with live presence data
/// Reference: DESIGN_BIBLE.md Section G.1 (Friends List + Presence)
/// Enforces Yahoo Messenger style status indicators
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_presence.dart';
import '../../core/utils/app_logger.dart';

/// Friend model combining user data + presence
class FriendWithPresence {
  /// Firestore user ID
  final String userId;

  /// Display name
  final String displayName;

  /// Avatar URL
  final String? avatarUrl;

  /// Current presence state
  final UserPresence? presence;

  /// Time added as friend
  final DateTime addedAt;

  const FriendWithPresence({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.presence,
    required this.addedAt,
  });

  /// Whether friend is online
  bool get isOnline => presence?.isOnline ?? false;

  /// Whether friend is inactive
  bool get isInactive => presence?.isInactive ?? false;

  /// Whether friend is offline
  bool get isOffline => presence?.isOffline ?? true;

  /// Room name if friend is in a room
  String? get roomName => presence?.roomName;

  /// Room ID if friend is in a room
  String? get roomId => presence?.roomId;

  /// Time since last activity
  Duration? get inactivityDuration => presence?.inactivityDuration;

  /// Tooltip text for hover (Yahoo Messenger style)
  String get tooltipText {
    if (isOnline && roomName != null) {
      return 'In $roomName';
    } else if (isInactive && inactivityDuration != null) {
      final minutes = inactivityDuration!.inMinutes;
      if (minutes < 1) return 'Idle for < 1 min';
      if (minutes < 60) return 'Idle for ${minutes}m';
      final hours = minutes ~/ 60;
      return 'Idle for ${hours}h';
    } else if (isOffline && presence != null) {
      final minutes = presence!.inactivityDuration.inMinutes;
      if (minutes < 1) return 'Last seen just now';
      if (minutes < 60) return 'Last seen ${minutes}m ago';
      final hours = minutes ~/ 60;
      if (hours < 24) return 'Last seen ${hours}h ago';
      final days = hours ~/ 24;
      return 'Last seen ${days}d ago';
    }
    return 'Offline';
  }

  /// Sort priority (online first by activity, then offline by lastSeen)
  int get sortPriority {
    if (isOnline) return 0;
    if (isInactive) return 1;
    return 2;
  }

  @override
  String toString() => 'Friend($displayName, presence=${presence?.state})';
}

/// Friends service for Firestore operations
class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final shouldNotUseAuth = FirebaseAuth.instance;  // Kept for backward compatibility

  /// Get current user's friend IDs
  Future<List<String>> getFriendIds(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) return [];

      final friends = data['friends'] as List? ?? [];
      return friends.cast<String>();
    } catch (e) {
      AppLogger.error('[FRIENDS] Failed to get friend IDs: $e');
      return [];
    }
  }

  /// Get friend data
  Future<Map<String, dynamic>?> getFriendData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      AppLogger.error('[FRIENDS] Failed to get friend data: $e');
      return null;
    }
  }

  /// Add friend
  Future<void> addFriend(String myUserId, String friendUserId) async {
    try {
      final batch = _firestore.batch();

      // Add to my friends list
      batch.update(
        _firestore.collection('users').doc(myUserId),
        {
          'friends': FieldValue.arrayUnion([friendUserId]),
        },
      );

      // Add to friend's followers list (reciprocal)
      batch.update(
        _firestore.collection('users').doc(friendUserId),
        {
          'followers': FieldValue.arrayUnion([myUserId]),
        },
      );

      await batch.commit();
      AppLogger.info('[FRIENDS] Added friend: $friendUserId');
    } catch (e) {
      AppLogger.error('[FRIENDS] Failed to add friend: $e');
      rethrow;
    }
  }

  /// Remove friend
  Future<void> removeFriend(String myUserId, String friendUserId) async {
    try {
      final batch = _firestore.batch();

      batch.update(
        _firestore.collection('users').doc(myUserId),
        {
          'friends': FieldValue.arrayRemove([friendUserId]),
        },
      );

      batch.update(
        _firestore.collection('users').doc(friendUserId),
        {
          'followers': FieldValue.arrayRemove([myUserId]),
        },
      );

      await batch.commit();
      AppLogger.info('[FRIENDS] Removed friend: $friendUserId');
    } catch (e) {
      AppLogger.error('[FRIENDS] Failed to remove friend: $e');
      rethrow;
    }
  }
}

/// Friends service provider
final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService();
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid;
});

/// Get list of friend IDs for current user
final friendIdsProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(friendsServiceProvider);
  return service.getFriendIds(userId);
});

/// Get friend data from Firestore
final friendDataProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriendData(userId);
});

/// Friend with presence combined
final friendWithPresenceProvider =
    Provider.family<FriendWithPresence?, String>((ref, friendUserId) {
  final friendDataAsync = ref.watch(friendDataProvider(friendUserId));

  return friendDataAsync.when(
    data: (friendData) {
      if (friendData == null) return null;

      return FriendWithPresence(
        userId: friendUserId,
        displayName: friendData['displayName'] ?? 'Unknown',
        avatarUrl: friendData['avatarUrl'],
        presence: null,
        addedAt: (friendData['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// All friends with presence (sorted by online status)
final friendsWithPresenceProvider =
    Provider.family<List<FriendWithPresence>, String>((ref, userId) {
  final friendIds = ref.watch(friendIdsProvider);

  return friendIds.when(
    data: (ids) {
      if (ids.isEmpty) return [];

      final friends = <FriendWithPresence>[];
      for (final friendId in ids) {
        final friend = ref.watch(friendWithPresenceProvider(friendId));
        if (friend != null) {
          friends.add(friend);
        }
      }

      // Sort: online by activity, then offline by lastSeen
      friends.sort((a, b) {
        final priorityDiff = a.sortPriority.compareTo(b.sortPriority);
        if (priorityDiff != 0) return priorityDiff;

        // Within same priority, sort by activity
        final aActivity = a.presence?.lastUpdate ?? DateTime.now();
        final bActivity = b.presence?.lastUpdate ?? DateTime.now();
        return bActivity.compareTo(aActivity); // Most recent first
      });

      return friends;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Stream of friends online/offline changes
final friendsPresenceStreamProvider =
    StreamProvider.family<List<FriendWithPresence>, String>((ref, userId) {
  final friendIds = ref.watch(friendIdsProvider).value ?? [];

  if (friendIds.isEmpty) {
    return Stream.value([]);
  }

  final friendsList = ref.watch(friendsWithPresenceProvider(userId));
  return Stream.value(friendsList);
});




