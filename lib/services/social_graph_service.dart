import 'package:cloud_firestore/cloud_firestore.dart';

class SocialGraphService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> followUser(String userId, String currentUserId) async {
    final followsRef = _firestore.collection('follows');
    await followsRef.add({
      'followerId': currentUserId,
      'followingId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowUser(String userId, String currentUserId) async {
    final followsRef = _firestore.collection('follows');
    final query = await followsRef
      .where('followerId', isEqualTo: currentUserId)
      .where('followingId', isEqualTo: userId)
      .get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isFollowing(String userId, String currentUserId) async {
    final followsRef = _firestore.collection('follows');
    final query = await followsRef
      .where('followerId', isEqualTo: currentUserId)
      .where('followingId', isEqualTo: userId)
      .limit(1)
      .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> isFriend(String userId, String currentUserId) async {
    final friendsRef = _firestore.collection('friends');
    final query = await friendsRef
      .where('userA', isEqualTo: currentUserId)
      .where('userB', isEqualTo: userId)
      .limit(1)
      .get();
    if (query.docs.isNotEmpty) return true;
    final reverseQuery = await friendsRef
      .where('userA', isEqualTo: userId)
      .where('userB', isEqualTo: currentUserId)
      .limit(1)
      .get();
    return reverseQuery.docs.isNotEmpty;
  }

  Future<List<String>> getFollowers(String userId) async {
    final followsRef = _firestore.collection('follows');
    final query = await followsRef
      .where('followingId', isEqualTo: userId)
      .get();
    return query.docs.map((doc) => doc['followerId'] as String).toList();
  }

  Future<List<String>> getFollowing(String userId) async {
    final followsRef = _firestore.collection('follows');
    final query = await followsRef
      .where('followerId', isEqualTo: userId)
      .get();
    return query.docs.map((doc) => doc['followingId'] as String).toList();
  }

  Future<List<String>> getFriends(String userId) async {
    final friendsRef = _firestore.collection('friends');
    final queryA = await friendsRef
      .where('userA', isEqualTo: userId)
      .get();
    final queryB = await friendsRef
      .where('userB', isEqualTo: userId)
      .get();
    final friendIds = <String>{};
    for (final doc in queryA.docs) {
      friendIds.add(doc['userB'] as String);
    }
    for (final doc in queryB.docs) {
      friendIds.add(doc['userA'] as String);
    }
    return friendIds.toList();
  }
}
