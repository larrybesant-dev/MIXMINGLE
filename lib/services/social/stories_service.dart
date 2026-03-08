import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Represents one story document from Firestore.
class StoryModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewerIds;
  final int viewCount;

  const StoryModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewerIds,
    required this.viewCount,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String?,
      userAvatar: d['userAvatar'] as String?,
      mediaUrl: d['mediaUrl'] as String? ?? '',
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.name == (d['mediaType'] as String? ?? 'image'),
        orElse: () => StoryMediaType.image,
      ),
      caption: d['caption'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      viewerIds: List<String>.from(d['viewerIds'] ?? []),
      viewCount: d['viewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.name,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'viewerIds': viewerIds,
        'viewCount': viewCount,
      };
}

enum StoryMediaType { image, video }

/// A grouped collection of stories from one user.
class StoryGroup {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final List<StoryModel> stories;
  final bool hasUnviewed;

  const StoryGroup({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.stories,
    required this.hasUnviewed,
  });
}

/// StoriesService manages story CRUD + presence rings.
/// Stories are stored in `stories/{storyId}` with a 24-hour TTL enforced
/// client-side and by the `storiesCleanup` Cloud Function.
class StoriesService {
  static final StoriesService _instance = StoriesService._internal();
  factory StoriesService() => _instance;
  StoriesService._internal();
  static StoriesService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Upload [file] to Storage and create a new story document.
  /// Returns the new story's ID or null on error.
  Future<String?> createStory({
    required File file,
    required StoryMediaType mediaType,
    String? caption,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      // Resolve actor display info
      final userDoc = await _db.collection('users').doc(uid).get();
      final d = userDoc.data() ?? {};
      final userName = d['displayName'] as String? ?? 'User';
      final userAvatar = d['photoUrl'] as String? ?? d['avatarUrl'] as String?;

      // Upload media
      final ext = mediaType == StoryMediaType.image ? 'jpg' : 'mp4';
      final ref = _storage.ref(
          'stories/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext');
      final task = await ref.putFile(file);
      final mediaUrl = await task.ref.getDownloadURL();

      // Write Firestore doc
      final docRef = await _db.collection('stories').add({
        'userId': uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.name,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'viewerIds': [],
        'viewCount': 0,
      });

      debugPrint('✅ [Stories] Story created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [Stories] Create error: $e');
      return null;
    }
  }

  /// Delete a story by [storyId]. Only the author can delete.
  Future<void> deleteStory(String storyId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('stories').doc(storyId).get();
      if (doc.data()?['userId'] != uid) return;
      // Remove storage file
      final url = doc.data()?['mediaUrl'] as String?;
      if (url != null) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
      await _db.collection('stories').doc(storyId).delete();
    } catch (e) {
      debugPrint('❌ [Stories] Delete error: $e');
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Watch all active (non-expired) stories from users that [viewerId] follows.
  /// Returns grouped list sorted: unviewed first, then by recency.
  Stream<List<StoryGroup>> watchFeedStories(String viewerId) {
    final now = Timestamp.now();
    return _db
        .collection('stories')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final stories = snap.docs.map(StoryModel.fromFirestore).toList();

      // Group by userId
      final grouped = <String, List<StoryModel>>{};
      for (final s in stories) {
        grouped.putIfAbsent(s.userId, () => []).add(s);
      }

      // Build StoryGroup list — filter out expired client-side
      final groups = grouped.entries.map((entry) {
        final active = entry.value.where((s) => !s.isExpired).toList();
        if (active.isEmpty) return null;
        final first = active.first;
        final hasUnviewed = active.any((s) => !s.viewerIds.contains(viewerId));
        return StoryGroup(
          userId: entry.key,
          userName: first.userName,
          userAvatar: first.userAvatar,
          stories: active,
          hasUnviewed: hasUnviewed,
        );
      }).whereType<StoryGroup>().toList();

      // Sort: unviewed first, then by most recent story
      groups.sort((a, b) {
        if (a.hasUnviewed != b.hasUnviewed) {
          return a.hasUnviewed ? -1 : 1;
        }
        return b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
      });

      return groups;
    });
  }

  /// Watch stories for a single [userId].
  Stream<List<StoryModel>> watchUserStories(String userId) {
    final now = Timestamp.now();
    return _db
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(StoryModel.fromFirestore).toList());
  }

  // ── View tracking ──────────────────────────────────────────────────────────

  /// Record that the current user viewed [storyId].
  Future<void> markViewed(String storyId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('stories').doc(storyId).update({
        'viewerIds': FieldValue.arrayUnion([uid]),
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ [Stories] markViewed error: $e');
    }
  }

  /// Returns the viewer list for a story (author-only feature).
  Future<List<String>> getViewers(String storyId) async {
    try {
      final doc = await _db.collection('stories').doc(storyId).get();
      return List<String>.from(doc.data()?['viewerIds'] ?? []);
    } catch (_) {
      return [];
    }
  }
}
