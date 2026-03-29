import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class UserFollow {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isVerified;

  const UserFollow({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory UserFollow.fromJson(Map<String, dynamic> json, String docId) {
    return UserFollow(
      userId: docId,
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

// Stream of followers
final followersProvider = StreamProvider.family<List<UserFollow>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(userId)
      .collection('followers')
      .snapshots()
      .asyncMap((snapshot) async {
    final followers = <UserFollow>[];
    for (final doc in snapshot.docs) {
      try {
        final userDoc = await firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          followers.add(UserFollow.fromJson(userDoc.data()!, doc.id));
        }
      } catch (e) {
        // Silently skip followers that can't be loaded
      }
    }
    return followers;
  });
});

// Stream of following
final followingProvider = StreamProvider.family<List<UserFollow>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(userId)
      .collection('following')
      .snapshots()
      .asyncMap((snapshot) async {
    final following = <UserFollow>[];
    for (final doc in snapshot.docs) {
      try {
        final userDoc = await firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          following.add(UserFollow.fromJson(userDoc.data()!, doc.id));
        }
      } catch (e) {
        // Silently skip users that can't be loaded
      }
    }
    return following;
  });
});

// Follow count
final followCountProvider =
    FutureProvider.family<({int followers, int following}), String>((ref, userId) async {
  final firestore = ref.watch(firestoreProvider);
  final followersSnap =
      await firestore.collection('users').doc(userId).collection('followers').get();
  final followingSnap =
      await firestore.collection('users').doc(userId).collection('following').get();

  return (
    followers: followersSnap.size,
    following: followingSnap.size,
  );
});

// Check if current user follows target user
final isFollowingProvider =
    FutureProvider.family<bool, ({String currentUserId, String targetUserId})>((ref, params) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore
      .collection('users')
      .doc(params.currentUserId)
      .collection('following')
      .doc(params.targetUserId)
      .get();
  return doc.exists;
});

// Controller for follow operations
final followControllerProvider = Provider<FollowController>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FollowController(firestore: firestore);
});

class FollowController {
  final FirebaseFirestore _firestore;

  FollowController({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
    required String targetUsername,
  }) async {
    final batch = _firestore.batch();

    // Add to current user's following
    batch.set(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId),
      {'followedAt': Timestamp.fromDate(DateTime.now())},
    );

    // Add to target user's followers
    batch.set(
      _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId),
      {'followedAt': Timestamp.fromDate(DateTime.now())},
    );

    await batch.commit();
  }

  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final batch = _firestore.batch();

    // Remove from current user's following
    batch.delete(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId),
    );

    // Remove from target user's followers
    batch.delete(
      _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId),
    );

    await batch.commit();
  }
}
