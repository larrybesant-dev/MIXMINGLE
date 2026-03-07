import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/user.dart';
import '../analytics/analytics_service.dart';

/// Service for handling social features like following/unfollowing users.
/// Uses users/{uid}/following/{targetUid} and users/{uid}/followers/{followerId}
/// subcollections — the flat `followings` collection is no longer used.
class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;

  SocialService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    final existingDoc = await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .get();

    if (existingDoc.exists) {
      throw Exception('Already following this user');
    }

    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('users').doc(followerId).collection('following').doc(followingId),
      {'timestamp': FieldValue.serverTimestamp()},
    );

    batch.set(
      _firestore.collection('users').doc(followingId).collection('followers').doc(followerId),
      {'timestamp': FieldValue.serverTimestamp()},
    );

    batch.update(
      _firestore.collection('users').doc(followerId),
      {'followingCount': FieldValue.increment(1)},
    );
    batch.update(
      _firestore.collection('users').doc(followingId),
      {'followersCount': FieldValue.increment(1)},
    );

    await batch.commit();

    final notifRef = _firestore
        .collection('users')
        .doc(followingId)
        .collection('notifications')
        .doc();
    await notifRef.set({
      'id': notifRef.id,
      'userId': followingId,
      'type': 2,
      'title': 'New Follower',
      'message': 'Someone started following you',
      'senderId': followerId,
      'senderName': null,
      'roomId': null,
      'roomName': null,
      'data': null,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _analytics.trackEngagement('user_followed', parameters: {
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    final doc = await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .get();

    if (!doc.exists) {
      throw Exception('Not following this user');
    }

    final batch = _firestore.batch();

    batch.delete(
      _firestore.collection('users').doc(followerId).collection('following').doc(followingId),
    );
    batch.delete(
      _firestore.collection('users').doc(followingId).collection('followers').doc(followerId),
    );

    batch.update(
      _firestore.collection('users').doc(followerId),
      {'followingCount': FieldValue.increment(-1)},
    );
    batch.update(
      _firestore.collection('users').doc(followingId),
      {'followersCount': FieldValue.increment(-1)},
    );

    await batch.commit();

    _analytics.trackEngagement('user_unfollowed', parameters: {
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  /// Check if user A is following user B
  Future<bool> isFollowing(String followerId, String followingId) async {
    final doc = await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .get();
    return doc.exists;
  }

  /// Stream that emits true/false depending on whether [followerId] follows [followingId]
  Stream<bool> isFollowingStream(String followerId, String followingId) {
    return _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get followers of a user
  Future<List<User>> getFollowers(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();

    final followerIds = snapshot.docs.map((doc) => doc.id).toList();
    if (followerIds.isEmpty) return [];

    final usersQuery = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: followerIds)
        .get();

    return usersQuery.docs.map((doc) => User.fromMap(doc.data())).toList();
  }

  /// Get users that a user is following
  Future<List<User>> getFollowing(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();

    final followingIds = snapshot.docs.map((doc) => doc.id).toList();
    if (followingIds.isEmpty) return [];

    final usersQuery = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: followingIds)
        .get();

    return usersQuery.docs.map((doc) => User.fromMap(doc.data())).toList();
  }

  /// Get mutual followers (users who follow each other)
  Future<List<User>> getMutualFollowers(String userId) async {
    final followers = await getFollowers(userId);
    final following = await getFollowing(userId);
    final followingIds = following.map((user) => user.id).toSet();
    return followers.where((follower) => followingIds.contains(follower.id)).toList();
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['followersCount'] as int?) ?? 0;
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['followingCount'] as int?) ?? 0;
  }

  /// Real-time stream of followers
  Stream<List<User>> getFollowersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .asyncMap((snapshot) async {
      final followerIds = snapshot.docs.map((doc) => doc.id).toList();
      if (followerIds.isEmpty) return <User>[];
      final usersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followerIds)
          .get();
      return usersQuery.docs.map((doc) => User.fromMap(doc.data())).toList();
    });
  }

  /// Real-time stream of following
  Stream<List<User>> getFollowingStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .asyncMap((snapshot) async {
      final followingIds = snapshot.docs.map((doc) => doc.id).toList();
      if (followingIds.isEmpty) return <User>[];
      final usersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();
      return usersQuery.docs.map((doc) => User.fromMap(doc.data())).toList();
    });
  }
}
