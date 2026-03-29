import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
class TrendingPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final List<String> hashtags;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  TrendingPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.hashtags,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
  });

  factory TrendingPost.fromJson(Map<String, dynamic> json, String id) {
    return TrendingPost(
      id: id,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      hashtags: List<String>.from(json['hashtags'] as List? ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }
}

// Get trending hashtags
final trendingHashtagsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('hashtags')
      .orderBy('postCount', descending: true)
      .limit(20)
      .get()
      .then((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'hashtag': doc.id,
        'postCount': data['postCount'] as int? ?? 0,
        'trendScore': data['trendScore'] as double? ?? 0.0,
      };
    }).toList();
  });
});

// Get posts with specific hashtag
final hashtagPostsProvider =
    StreamProvider.family<List<TrendingPost>, String>((ref, hashtag) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('posts')
      .where('hashtags', arrayContains: hashtag)
      .orderBy('likeCount', descending: true)
      .limit(30)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TrendingPost.fromJson(doc.data(), doc.id))
          .toList());
});

// Get trending posts (top posts by engagement in last 7 days)
final trendingPostsProvider = FutureProvider<List<TrendingPost>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final sevenDaysAgo =
      DateTime.now().subtract(const Duration(days: 7));

  return firestore
      .collection('posts')
      .where('createdAt', isGreaterThan: sevenDaysAgo)
      .orderBy('createdAt', descending: true)
      .orderBy('likeCount', descending: true)
      .limit(50)
      .get()
      .then((snapshot) {
    final posts = snapshot.docs
        .map((doc) => TrendingPost.fromJson(doc.data(), doc.id))
        .toList();

    // Sort by engagement score
    posts.sort((a, b) {
      final aScore = (a.likeCount + a.commentCount) / 2;
      final bScore = (b.likeCount + b.commentCount) / 2;
      return bScore.compareTo(aScore);
    });

    return posts.take(20).toList();
  });
});
