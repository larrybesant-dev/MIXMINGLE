

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';
import 'moderation_service.dart';

class FriendService {
  FriendService({FirebaseFirestore? firestore, AnalyticsService? analyticsService, ModerationService? moderationService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _analyticsService = analyticsService ?? AnalyticsService(),
        _moderationService = moderationService ?? ModerationService(firestore: firestore ?? FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;
  final AnalyticsService _analyticsService;
  final ModerationService _moderationService;

  List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((entry) => entry is String ? entry.trim() : '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  String? _asNullableString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    if (fromUserId.trim().isEmpty || toUserId.trim().isEmpty || fromUserId == toUserId) {
      return;
    }

    if (await _moderationService.hasBlockingRelationship(fromUserId, toUserId)) {
      return;
    }

    final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
    final toUserDoc = await _firestore.collection('users').doc(toUserId).get();
    if (!fromUserDoc.exists || !toUserDoc.exists) {
      return;
    }

    final fromFriends = _asStringList(
      (fromUserDoc.data() ?? <String, dynamic>{})['friends'],
    );
    if (fromFriends.contains(toUserId)) {
      return;
    }

    final existingRequest = await _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existingRequest.docs.isNotEmpty) {
      return;
    }

    final reversePendingRequest = await _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: fromUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (reversePendingRequest.docs.isNotEmpty) {
      await acceptFriendRequest(reversePendingRequest.docs.first.id);
      return;
    }

    final requestRef = _firestore.collection('friend_requests').doc();
    await requestRef.set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final fromUser = await getUserById(fromUserId);
    await _createNotification(
      toUserId,
      type: 'friend_request',
      content: '${fromUser?.username ?? 'Someone'} sent you a friend request.',
      actorId: fromUserId,
    );

    try {
      await _analyticsService.logEvent('friend_request_sent', params: {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'request_id': requestRef.id,
      });
    } catch (_) {
      // Keep friend request flow resilient when analytics is unavailable.
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    final requestSnap = await requestRef.get();
    if (!requestSnap.exists) return;
    final data = requestSnap.data() ?? <String, dynamic>{};
    final fromUserId = _asNullableString(data['fromUserId']);
    final toUserId = _asNullableString(data['toUserId']);
    final status = _asString(data['status'], fallback: 'pending');
    if (fromUserId == null || toUserId == null || status != 'pending') {
      return;
    }

    await _firestore.runTransaction((txn) async {
      final fromUserRef = _firestore.collection('users').doc(fromUserId);
      final toUserRef = _firestore.collection('users').doc(toUserId);

      txn.set(fromUserRef, {
        'friends': FieldValue.arrayUnion([toUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      txn.set(toUserRef, {
        'friends': FieldValue.arrayUnion([fromUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      txn.update(requestRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });

    final toUser = await getUserById(toUserId);
    await _createNotification(
      fromUserId,
      type: 'friend_accept',
      content: '${toUser?.username ?? 'Someone'} accepted your friend request.',
      actorId: toUserId,
    );

    try {
      await _analyticsService.logEvent('friend_request_accepted', params: {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'request_id': requestId,
      });
    } catch (_) {
      // Keep friend acceptance flow resilient when analytics is unavailable.
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    final requestSnap = await requestRef.get();
    if (!requestSnap.exists) {
      return;
    }

    final data = requestSnap.data() ?? <String, dynamic>{};
    if (_asString(data['status'], fallback: 'pending') != 'pending') {
      return;
    }

    await requestRef.update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<UserModel>> getFriends(String userId) async {
    final friendIds = await getFriendIds(userId);
    if (friendIds.isEmpty) return [];

    final excludedIds = await _moderationService.getExcludedUserIds(userId);
    final visibleFriendIds = friendIds.where((id) => !excludedIds.contains(id)).toList(growable: false);
    if (visibleFriendIds.isEmpty) {
      return const [];
    }

    final favoriteIds = await getFavoriteFriendIds(userId);

    final friendsQuery = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: visibleFriendIds)
        .get();
    final friends = friendsQuery.docs
        .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList(growable: false);

    // Favorites appear first, then alphabetically within each group.
    friends.sort((a, b) {
      final aFav = favoriteIds.contains(a.id) ? 0 : 1;
      final bFav = favoriteIds.contains(b.id) ? 0 : 1;
      if (aFav != bFav) return aFav.compareTo(bFav);
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return friends;
  }

  Future<UserModel?> getUserById(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (!snapshot.exists) {
      return null;
    }

    return UserModel.fromJson({'id': snapshot.id, ...?snapshot.data()});
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const [];
    }

    final uniqueIds = userIds.toSet().toList(growable: false);
    final query = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: uniqueIds)
        .get();

    return query.docs
        .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList(growable: false);
  }

  Future<List<String>> getFriendIds(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return const [];
    final data = userDoc.data() ?? <String, dynamic>{};
    return _asStringList(data['friends']);
  }

  Future<Set<String>> getFavoriteFriendIds(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return const <String>{};
    final data = userDoc.data() ?? <String, dynamic>{};
    return _asStringList(data['favoriteFriendIds']).toSet();
  }

  Future<void> setFavorite(String userId, String friendId, {required bool isFavorite}) async {
    if (userId.trim().isEmpty || friendId.trim().isEmpty) return;
    await _firestore.collection('users').doc(userId).set({
      'favoriteFriendIds': isFavorite
          ? FieldValue.arrayUnion([friendId])
          : FieldValue.arrayRemove([friendId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (isFavorite) {
      await _createNotification(
        friendId,
        type: 'friend_favorite',
        content: 'Someone added you as a favorite friend.',
        actorId: userId,
      );
    }
  }

  Future<List<String>> getIncomingRequesterIds(String userId) async {
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
      .map((doc) => _asString(doc.data()['fromUserId']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> getOutgoingPendingRequestIds(String userId) async {
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
      .map((doc) => _asString(doc.data()['toUserId']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(userId), {
      'friends': FieldValue.arrayRemove([friendId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('users').doc(friendId), {
      'friends': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<List<UserModel>> searchUsers(
    String query, {
    String? currentUserId,
    List<String> excludeUserIds = const [],
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final snapshot = await _firestore.collection('users').limit(30).get();
    final blockedIds = currentUserId == null
        ? const <String>{}
        : await _moderationService.getExcludedUserIds(currentUserId);

    return snapshot.docs
        .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
        .where((user) => user.id.isNotEmpty)
        .where((user) => user.id != currentUserId)
        .where((user) => !excludeUserIds.contains(user.id))
        .where((user) => !blockedIds.contains(user.id))
        .where((user) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return user.username.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Stream<List<FriendRequestModel>> incomingRequests(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromJson(doc.id, doc.data()))
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<List<String>> outgoingPendingRequestIds(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _asString(doc.data()['toUserId']))
              .where((id) => id.isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<void> _createNotification(
    String userId, {
    required String type,
    required String content,
    required String actorId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'actorId': actorId,
      'type': type,
      'content': content,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns up to [limit] user profiles that are friends-of-friends but are
  /// not already friends with [userId] and not blocked/muted.
  /// Scores candidates by how many mutual friends they share.
  Future<List<UserModel>> getFriendSuggestions(
    String userId, {
    int limit = 20,
  }) async {
    if (userId.trim().isEmpty) return const [];

    final myFriendIds = (await getFriendIds(userId)).toSet();
    if (myFriendIds.isEmpty) return const [];

    final excludedIds = await _moderationService.getExcludedUserIds(userId);
    final excluded = {...excludedIds, userId, ...myFriendIds};

    // Build a mutual-friend count map for candidates.
    final mutualCount = <String, int>{};
    for (final friendId in myFriendIds) {
      final theirFriendIds = await getFriendIds(friendId);
      for (final candidate in theirFriendIds) {
        if (excluded.contains(candidate)) continue;
        mutualCount[candidate] = (mutualCount[candidate] ?? 0) + 1;
      }
    }
    if (mutualCount.isEmpty) return const [];

    // Sort by mutual friend count descending, take top [limit].
    final sorted = mutualCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = sorted.take(limit).map((e) => e.key).toList();

    if (topIds.isEmpty) return const [];

    // Batch-fetch profiles (whereIn supports up to 30 per call).
    final results = <UserModel>[];
    for (var i = 0; i < topIds.length; i += 30) {
      final batch = topIds.sublist(i, i + 30 < topIds.length ? i + 30 : topIds.length);
      final snap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(
        snap.docs.map((d) => UserModel.fromJson({'id': d.id, ...d.data()})),
      );
    }
    return results;
  }
}
