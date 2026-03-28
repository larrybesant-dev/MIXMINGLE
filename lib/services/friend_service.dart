

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';

class FriendService {
  FriendService({FirebaseFirestore? firestore, AnalyticsService? analyticsService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _analyticsService = analyticsService ?? AnalyticsService();

  final FirebaseFirestore _firestore;
  final AnalyticsService _analyticsService;

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    if (fromUserId.trim().isEmpty || toUserId.trim().isEmpty || fromUserId == toUserId) {
      return;
    }

    final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
    final toUserDoc = await _firestore.collection('users').doc(toUserId).get();
    if (!fromUserDoc.exists || !toUserDoc.exists) {
      return;
    }

    final fromFriends = List<String>.from((fromUserDoc.data() ?? <String, dynamic>{})['friends'] ?? const <String>[]);
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
    final data = requestSnap.data() as Map<String, dynamic>;
    final fromUserId = data['fromUserId'] as String?;
    final toUserId = data['toUserId'] as String?;
    final status = data['status'] as String? ?? 'pending';
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

    final data = requestSnap.data() as Map<String, dynamic>;
    if ((data['status'] as String? ?? 'pending') != 'pending') {
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

    final friendsQuery = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();
    return friendsQuery.docs
        .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList(growable: false);
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
    final data = userDoc.data() as Map<String, dynamic>;
    return List<String>.from(data['friends'] ?? const <String>[]);
  }

  Future<List<String>> getIncomingRequesterIds(String userId) async {
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['fromUserId'] as String? ?? '')
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
        .map((doc) => doc.data()['toUserId'] as String? ?? '')
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

    return snapshot.docs
        .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
        .where((user) => user.id.isNotEmpty)
        .where((user) => user.id != currentUserId)
        .where((user) => !excludeUserIds.contains(user.id))
        .where((user) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return user.username.toLowerCase().contains(normalizedQuery) ||
              user.email.toLowerCase().contains(normalizedQuery);
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
              .map((doc) => doc.data()['toUserId'] as String? ?? '')
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
}
