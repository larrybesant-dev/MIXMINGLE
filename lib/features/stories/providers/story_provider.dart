import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Story {
  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String? content;
  final DateTime createdAt;
  final DateTime expiresAt; // 24 hours after creation
  final List<String> viewedBy;
  final bool isDeleted;

  const Story({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    this.imageUrl,
    this.videoUrl,
    this.content,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.isDeleted = false,
  });

  factory Story.fromJson(Map<String, dynamic> json, String docId) {
    return Story(
      id: docId,
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      content: json['content'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from((json['viewedBy'] as List<dynamic>?) ?? []),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
      'isDeleted': isDeleted,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream of stories from following users
final followingStoriesProvider = StreamProvider.family<List<Story>, ({String userId, List<String> followingIds})>((ref, params) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collectionGroup('stories')
      .where('userId', whereIn: params.followingIds.isNotEmpty ? params.followingIds : [params.userId])
      .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('expiresAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Story.fromJson(doc.data(), doc.id))
        .where((story) => !story.isExpired)
        .toList();
  });
});

// Stream of user's own stories
final myStoriesProvider = StreamProvider.family<List<Story>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(userId)
      .collection('stories')
      .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Story.fromJson(doc.data(), doc.id))
        .where((story) => !story.isExpired)
        .toList();
  });
});

// Controller for story operations
final storyControllerProvider = Provider<StoryController>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return StoryController(firestore: firestore);
});

class StoryController {
  final FirebaseFirestore _firestore;

  StoryController({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> createStory({
    required String userId,
    required String username,
    required String? userAvatarUrl,
    String? imageUrl,
    String? videoUrl,
    String? content,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    await _firestore.collection('users').doc(userId).collection('stories').add({
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': [userId],
      'isDeleted': false,
    });
  }

  Future<void> markStoryAsViewed({
    required String userId,
    required String storyId,
    required String viewerId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('stories')
        .doc(storyId)
        .update({
      'viewedBy': FieldValue.arrayUnion([viewerId]),
    });
  }

  Future<void> deleteStory({
    required String userId,
    required String storyId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('stories')
        .doc(storyId)
        .update({'isDeleted': true});
  }
}
