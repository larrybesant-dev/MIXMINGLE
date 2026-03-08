import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// A short-form video document from Firestore.
class ShortVideo {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final bool isVisible;

  const ShortVideo({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.likedBy,
    required this.createdAt,
    this.isVisible = true,
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory ShortVideo.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShortVideo(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String?,
      userAvatar: d['userAvatar'] as String?,
      videoUrl: d['videoUrl'] as String? ?? '',
      thumbnailUrl: d['thumbnailUrl'] as String?,
      caption: d['caption'] as String?,
      tags: List<String>.from(d['tags'] ?? []),
      likeCount: d['likeCount'] as int? ?? 0,
      commentCount: d['commentCount'] as int? ?? 0,
      shareCount: d['shareCount'] as int? ?? 0,
      likedBy: List<String>.from(d['likedBy'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVisible: d['isVisible'] as bool? ?? true,
    );
  }
}

/// ShortVideoService manages uploads, the paginated short-video feed,
/// and per-video interactions (like, comment count).
class ShortVideoService {
  static final ShortVideoService _instance = ShortVideoService._internal();
  factory ShortVideoService() => _instance;
  ShortVideoService._internal();
  static ShortVideoService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Upload ──────────────────────────────────────────────────────────────────

  /// Upload a short video and create its Firestore document.
  /// Progress is reported via [onProgress] (0.0 — 1.0).
  Future<String?> uploadVideo({
    required File videoFile,
    String? caption,
    List<String> tags = const [],
    void Function(double)? onProgress,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final d = userDoc.data() ?? {};
      final userName = d['displayName'] as String? ?? 'User';
      final userAvatar = d['photoUrl'] as String? ?? d['avatarUrl'] as String?;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef =
          _storage.ref('short_videos/$uid/$timestamp.mp4');

      final uploadTask = storageRef.putFile(videoFile);
      uploadTask.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress?.call(snap.bytesTransferred / snap.totalBytes);
        }
      });
      await uploadTask;
      final videoUrl = await storageRef.getDownloadURL();

      final docRef = await _db.collection('short_videos').add({
        'userId': uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'videoUrl': videoUrl,
        'thumbnailUrl': null,
        'caption': caption,
        'tags': tags,
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'isVisible': true,
      });

      debugPrint('✅ [ShortVideo] Uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [ShortVideo] Upload error: $e');
      return null;
    }
  }

  // ── Feed ────────────────────────────────────────────────────────────────────

  /// Paginated feed — returns most recent visible videos.
  Future<List<ShortVideo>> getVideoFeed({
    DocumentSnapshot? lastDoc,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('short_videos')
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();
      return snap.docs.map(ShortVideo.fromFirestore).toList();
    } catch (e) {
      debugPrint('❌ [ShortVideo] getVideoFeed error: $e');
      return [];
    }
  }

  /// Stream of a user's own short videos.
  Stream<List<ShortVideo>> watchUserVideos(String userId) {
    return _db
        .collection('short_videos')
        .where('userId', isEqualTo: userId)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ShortVideo.fromFirestore).toList());
  }

  // ── Interactions ────────────────────────────────────────────────────────────

  /// Toggle like on a video. Returns true if now liked.
  Future<bool> toggleLike(String videoId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final ref = _db.collection('short_videos').doc(videoId);
      final doc = await ref.get();
      if (!doc.exists) return false;
      final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
      final isLiked = likedBy.contains(uid);
      if (isLiked) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }
      await ref.update({
        'likedBy': likedBy,
        'likeCount': likedBy.length,
      });
      return !isLiked;
    } catch (e) {
      debugPrint('❌ [ShortVideo] toggleLike error: $e');
      return false;
    }
  }

  /// Increment share count for analytics.
  Future<void> recordShare(String videoId) async {
    try {
      await _db.collection('short_videos').doc(videoId).update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  /// Delete a video (author only).
  Future<void> deleteVideo(String videoId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('short_videos').doc(videoId).get();
      if (doc.data()?['userId'] != uid) return;
      final url = doc.data()?['videoUrl'] as String?;
      if (url != null) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
      await _db.collection('short_videos').doc(videoId).delete();
    } catch (e) {
      debugPrint('❌ [ShortVideo] deleteVideo error: $e');
    }
  }
}
