import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isVerified;
  final int followerCount;

  const SearchUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.followerCount = 0,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json, String docId) {
    return SearchUser(
      id: docId,
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      followerCount: json['followerCount'] as int? ?? 0,
    );
  }
}

class SearchPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final List<String> hashtags;
  final DateTime createdAt;
  final int likeCount;

  const SearchPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    this.hashtags = const [],
    required this.createdAt,
    this.likeCount = 0,
  });

  factory SearchPost.fromJson(Map<String, dynamic> json, String docId) {
    return SearchPost(
      id: docId,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      hashtags: List<String>.from((json['hashtags'] as List<dynamic>?) ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }
}

class SearchHashtag {
  final String hashtag;
  final int postCount;
  final DateTime lastUsedAt;

  const SearchHashtag({
    required this.hashtag,
    required this.postCount,
    required this.lastUsedAt,
  });

  factory SearchHashtag.fromJson(Map<String, dynamic> json, String docId) {
    return SearchHashtag(
      hashtag: docId,
      postCount: json['postCount'] as int? ?? 0,
      lastUsedAt: (json['lastUsedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Search users by name or username
final searchUsersProvider = FutureProvider.family<List<SearchUser>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final firestore = ref.watch(firestoreProvider);
  final lowerQuery = query.toLowerCase();

  final snapshot = await firestore
      .collection('users')
      .where('username', isGreaterThanOrEqualTo: lowerQuery)
      .where('username', isLessThan: '${lowerQuery}z')
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) => SearchUser.fromJson(doc.data(), doc.id))
      .toList();
});

// Search posts by content
final searchPostsProvider = FutureProvider.family<List<SearchPost>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection('posts')
      .where('tags', arrayContains: query.toLowerCase())
      .orderBy('createdAt', descending: true)
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) => SearchPost.fromJson(doc.data(), doc.id))
      .toList();
});

// Search hashtags
final searchHashtagsProvider = FutureProvider.family<List<SearchHashtag>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final firestore = ref.watch(firestoreProvider);
  final lowerQuery = query.toLowerCase().replaceAll('#', '');

  final snapshot = await firestore
      .collection('hashtags')
      .where('hashtag', isGreaterThanOrEqualTo: lowerQuery)
      .where('hashtag', isLessThan: '${lowerQuery}z')
      .orderBy('hashtag')
      .orderBy('postCount', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => SearchHashtag.fromJson(doc.data(), doc.id))
      .toList();
});

// Trending hashtags
final trendingHashtagsProvider = FutureProvider<List<SearchHashtag>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection('hashtags')
      .orderBy('postCount', descending: true)
      .orderBy('lastUsedAt', descending: true)
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) => SearchHashtag.fromJson(doc.data(), doc.id))
      .toList();
});
