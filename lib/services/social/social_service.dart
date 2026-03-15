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

<<<<<<< HEAD
    final existingDoc = await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .get();
=======
    final relationshipId = Following.createId(followerId, followingId);

    // Check if already following
    final existingDoc =
        await _firestore.collection('followings').doc(relationshipId).get();
>>>>>>> origin/develop

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
<<<<<<< HEAD
    final doc = await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .get();
=======
    final relationshipId = Following.createId(followerId, followingId);

    // Check if following exists
    final doc =
        await _firestore.collection('followings').doc(relationshipId).get();
>>>>>>> origin/develop

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
<<<<<<< HEAD
    final doc = await _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId)
        .get();
=======
    final relationshipId = Following.createId(followerId, followingId);
    final doc =
        await _firestore.collection('followings').doc(relationshipId).get();
>>>>>>> origin/develop
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
<<<<<<< HEAD
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();
=======
    final querySnapshot = await _firestore
        .collection('followings')
        .where('followingId', isEqualTo: userId)
        .get();

    final followerIds = querySnapshot.docs
        .map((doc) => doc.data()['followerId'] as String)
        .toList();
>>>>>>> origin/develop

    final followerIds = snapshot.docs.map((doc) => doc.id).toList();
    if (followerIds.isEmpty) return [];

<<<<<<< HEAD
=======
    // Get user details for followers
>>>>>>> origin/develop
    final usersQuery = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: followerIds)
        .get();

    return usersQuery.docs.map((doc) => User.fromMap(doc.data())).toList();
  }

  /// Get users that a user is following
  Future<List<User>> getFollowing(String userId) async {
<<<<<<< HEAD
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();
=======
    final querySnapshot = await _firestore
        .collection('followings')
        .where('followerId', isEqualTo: userId)
        .get();

    final followingIds = querySnapshot.docs
        .map((doc) => doc.data()['followingId'] as String)
        .toList();
>>>>>>> origin/develop

    final followingIds = snapshot.docs.map((doc) => doc.id).toList();
    if (followingIds.isEmpty) return [];

<<<<<<< HEAD
=======
    // Get user details for following
>>>>>>> origin/develop
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
    return followers
        .where((follower) => followingIds.contains(follower.id))
        .toList();
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
<<<<<<< HEAD
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['followersCount'] as int?) ?? 0;
=======
    final querySnapshot = await _firestore
        .collection('followings')
        .where('followingId', isEqualTo: userId)
        .count()
        .get();
    return querySnapshot.count ?? 0;
>>>>>>> origin/develop
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
<<<<<<< HEAD
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['followingCount'] as int?) ?? 0;
=======
    final querySnapshot = await _firestore
        .collection('followings')
        .where('followerId', isEqualTo: userId)
        .count()
        .get();
    return querySnapshot.count ?? 0;
>>>>>>> origin/develop
  }

  /// Real-time stream of followers
  Stream<List<User>> getFollowersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .asyncMap((snapshot) async {
<<<<<<< HEAD
      final followerIds = snapshot.docs.map((doc) => doc.id).toList();
      if (followerIds.isEmpty) return <User>[];
=======
      final followerIds = snapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

>>>>>>> origin/develop
      final usersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followerIds)
          .get();
<<<<<<< HEAD
=======

>>>>>>> origin/develop
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
<<<<<<< HEAD
      final followingIds = snapshot.docs.map((doc) => doc.id).toList();
      if (followingIds.isEmpty) return <User>[];
=======
      final followingIds = snapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

>>>>>>> origin/develop
      final usersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();
<<<<<<< HEAD
=======

>>>>>>> origin/develop
      return usersQuery.docs.map((doc) => User.fromMap(doc.data())).toList();
    });
  }
}
