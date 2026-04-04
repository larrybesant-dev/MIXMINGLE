import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

DateTime _parseCreatedAt(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

final followingFeedProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('follows')
      .where('followerUserId', isEqualTo: userId)
      .snapshots()
      .asyncExpand((followingSnapshot) async* {
    final followingIds = followingSnapshot.docs
        .map((doc) => doc.data()['followedUserId'] as String?)
        .whereType<String>()
        .toList();

    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    // Get posts from following users
    final batches = <QuerySnapshot<Map<String, dynamic>>>[];
    for (int i = 0; i < followingIds.length; i += 10) {
      final batch = followingIds.sublist(
        i,
        i + 10 > followingIds.length ? followingIds.length : i + 10,
      );

      final snapshot = await firestore
          .collection('posts')
          .where('authorId', whereIn: batch)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      batches.add(snapshot);
    }

    // Combine and sort all posts
    final allPosts = <Map<String, dynamic>>[];
    for (final batch in batches) {
      for (final doc in batch.docs) {
        allPosts.add({
          ...doc.data(),
          'id': doc.id,
        });
      }
    }

    allPosts.sort((a, b) {
      final aTime = _parseCreatedAt(a['createdAt']);
      final bTime = _parseCreatedAt(b['createdAt']);
      return bTime.compareTo(aTime);
    });

    yield allPosts;
  });
});
