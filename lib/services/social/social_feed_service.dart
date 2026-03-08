import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/post.dart';
import 'activity_feed_service.dart';

/// Social Feed Service
/// Manages posts, likes, comments, and feed pagination
class SocialFeedService {
  static SocialFeedService? _instance;
  static SocialFeedService get instance => _instance ??= SocialFeedService._();

  SocialFeedService._();
  factory SocialFeedService() => instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ============================================================
  // POST CRUD
  // ============================================================

  /// Create a new post
  Future<String?> createPost({
    required String userId,
    required String content,
    String? imageUrl,
    String? roomId,
    PostType type = PostType.text,
  }) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() ?? {};

      final postRef = await _postsCollection.add({
        'userId': userId,
        'userName': userData['displayName'] ?? 'User',
        'userAvatar': userData['avatarUrl'] ?? userData['photoUrl'] ?? '',
        'content': content,
        'imageUrl': imageUrl,
        'roomId': roomId,
        'type': type.name,
        'likes': [],
        'likeCount': 0,
        'commentCount': 0,
        'tipCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVisible': true,
      });

      debugPrint('âœ… [SocialFeed] Post created: ${postRef.id}');
      return postRef.id;
    } catch (e) {
      debugPrint('âŒ [SocialFeed] Error creating post: $e');
      return null;
    }
  }

  /// Get paginated feed for a user (posts from friends + own posts)
  Future<List<Post>> getFeed({
    required String userId,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    try {
      // Get user's friends list
      final userDoc = await _usersCollection.doc(userId).get();
      final friendIds =
          List<String>.from(userDoc.data()?['friends'] ?? []);

      // Include own posts
      final allUserIds = [userId, ...friendIds];

      // Firestore 'whereIn' limited to 30, batch if needed
      final batches = <List<String>>[];
      for (var i = 0; i < allUserIds.length; i += 30) {
        batches.add(
          allUserIds.sublist(
            i,
            i + 30 > allUserIds.length ? allUserIds.length : i + 30,
          ),
        );
      }

      final posts = <Post>[];
      for (final batch in batches) {
        Query<Map<String, dynamic>> query = _postsCollection
            .where('userId', whereIn: batch)
            .where('isVisible', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();
        posts.addAll(snapshot.docs.map((doc) => Post.fromFirestore(doc)));
      }

      // Sort all posts by date
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts.take(limit).toList();
    } catch (e) {
      debugPrint('âŒ [SocialFeed] Error getting feed: $e');
      return [];
    }
  }

  /// Get posts from users the current user follows (subcollection-based following feed).
  /// Returns an empty stream if [userId] is empty or follows nobody.
  Stream<List<Post>> getFollowingFeedStream(String userId, {int limit = 50}) {
    if (userId.isEmpty) return Stream.value([]);

    return _usersCollection
        .doc(userId)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnap) async {
      final followingIds = followingSnap.docs.map((d) => d.id).toList();
      if (followingIds.isEmpty) return <Post>[];

      // Include the user's own posts too
      final allIds = [userId, ...followingIds];

      final posts = <Post>[];
      for (var i = 0; i < allIds.length; i += 30) {
        final chunk = allIds.sublist(i, i + 30 > allIds.length ? allIds.length : i + 30);
        final snap = await _postsCollection
            .where('userId', whereIn: chunk)
            .where('isVisible', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        posts.addAll(snap.docs.map((doc) => Post.fromFirestore(doc)));
      }

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts.take(limit).toList();
    });
  }

  /// Get global/discover feed (all public posts)
  Stream<List<Post>> getGlobalFeedStream({int limit = 50}) {
    return _postsCollection
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  /// Get posts for a specific user
  Stream<List<Post>> getUserPostsStream(String userId, {int limit = 20}) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  /// Get trending posts ordered by likeCount descending.
  Stream<List<Post>> getTrendingFeedStream({int limit = 20}) {
    return _postsCollection
        .where('isVisible', isEqualTo: true)
        .orderBy('likeCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Post.fromFirestore(d)).toList());
  }

  /// One page of the global feed using DocumentSnapshot cursor pagination.
  /// Returns (posts, nextCursor) — nextCursor is null when no more pages.
  Future<(List<Post>, DocumentSnapshot?)> getGlobalFeedPage({
    DocumentSnapshot? cursor,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _postsCollection
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snap = await query.get();
      final posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      final next =
          snap.docs.length == limit ? snap.docs.last as DocumentSnapshot? : null;
      return (posts, next);
    } catch (e) {
      debugPrint('❌ [SocialFeed] getGlobalFeedPage error: $e');
      return (<Post>[], null);
    }
  }

  /// One page of the trending feed using DocumentSnapshot cursor pagination.
  Future<(List<Post>, DocumentSnapshot?)> getTrendingFeedPage({
    DocumentSnapshot? cursor,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _postsCollection
          .where('isVisible', isEqualTo: true)
          .orderBy('likeCount', descending: true)
          .limit(limit);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snap = await query.get();
      final posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      final next =
          snap.docs.length == limit ? snap.docs.last as DocumentSnapshot? : null;
      return (posts, next);
    } catch (e) {
      debugPrint('❌ [SocialFeed] getTrendingFeedPage error: $e');
      return (<Post>[], null);
    }
  }

  /// One page of the following feed using offset-based pagination.
  /// Fetches all following posts in memory then paginates (handles whereIn batching).
  /// Returns (posts, nextOffset) — nextOffset is null when no more pages.
  Future<(List<Post>, int?)> getFollowingFeedPage({
    required String userId,
    int offset = 0,
    int limit = 20,
  }) async {
    if (userId.isEmpty) return (<Post>[], null);
    try {
      final followingSnap = await _usersCollection
          .doc(userId)
          .collection('following')
          .get();
      final allIds = [userId, ...followingSnap.docs.map((d) => d.id)];
      final allPosts = <Post>[];
      for (var i = 0; i < allIds.length; i += 30) {
        final chunk = allIds.sublist(
            i, i + 30 > allIds.length ? allIds.length : i + 30);
        final snap = await _postsCollection
            .where('userId', whereIn: chunk)
            .where('isVisible', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        allPosts.addAll(snap.docs.map((d) => Post.fromFirestore(d)));
      }
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final page = allPosts.skip(offset).take(limit).toList();
      final nextOffset = page.length == limit ? offset + limit : null;
      return (page, nextOffset);
    } catch (e) {
      debugPrint('❌ [SocialFeed] getFollowingFeedPage error: $e');
      return (<Post>[], null);
    }
  }

  // ============================================================
  // INTERACTIONS
  // ============================================================

  /// Like/unlike a post
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return false;

      final likes = List<String>.from(postDoc.data()?['likes'] ?? []);
      final isLiked = likes.contains(userId);

      if (isLiked) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await postRef.update({
        'likes': likes,
        'likeCount': likes.length,
      });

      // Fire activity event when a post is newly liked (not on unlike)
      if (!isLiked) {
        final postOwnerId = postDoc.data()?['userId'] as String?;
        if (postOwnerId != null && postOwnerId != userId) {
          await ActivityFeedService.instance
              .onLikePost(postOwnerId, postId);
        }
      }

      debugPrint('✅ [SocialFeed] Post ${isLiked ? 'unliked' : 'liked'}');
      return !isLiked;
    } catch (e) {
      debugPrint('âŒ [SocialFeed] Error toggling like: $e');
      return false;
    }
  }

  /// Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() ?? {};

      final commentRef = await _postsCollection
          .doc(postId)
          .collection('comments')
          .add({
        'userId': userId,
        'userName': userData['displayName'] ?? 'User',
        'userAvatar': userData['avatarUrl'] ?? userData['photoUrl'] ?? '',
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comment count
      await _postsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Fire activity event to the post owner
      final postDoc = await _postsCollection.doc(postId).get();
      final postOwnerId = postDoc.data()?['userId'] as String?;
      if (postOwnerId != null && postOwnerId != userId) {
        await ActivityFeedService.instance.onComment(
          postOwnerId, postId, content,
        );
      }

      debugPrint('✅ [SocialFeed] Comment added');
      return commentRef.id;
    } catch (e) {
      debugPrint('âŒ [SocialFeed] Error adding comment: $e');
      return null;
    }
  }

  /// Get comments for a post
  Stream<List<Comment>> getCommentsStream(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }

  /// Tip a post author
  Future<bool> tipPost({
    required String postId,
    required String fromUserId,
    required int coinAmount,
  }) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) return false;

      final toUserId = postDoc.data()?['userId'] as String;

      // Deduct from sender
      await _usersCollection.doc(fromUserId).update({
        'coinBalance': FieldValue.increment(-coinAmount),
      });

      // Add to receiver
      await _usersCollection.doc(toUserId).update({
        'coinBalance': FieldValue.increment(coinAmount),
      });

      // Record tip on post
      await _postsCollection.doc(postId).update({
        'tipCount': FieldValue.increment(coinAmount),
      });

      // Record transaction
      await _firestore.collection('transactions').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': coinAmount,
        'type': 'post_tip',
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('âœ… [SocialFeed] Post tipped $coinAmount coins');
      return true;
    } catch (e) {
      debugPrint('âŒ [SocialFeed] Error tipping post: $e');
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId, String userId) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) return false;

      // Only author can delete
      if (postDoc.data()?['userId'] != userId) return false;

      await _postsCollection.doc(postId).update({
        'isVisible': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('âœ… [SocialFeed] Post deleted');
      return true;
    } catch (e) {
      debugPrint('âŒ [SocialFeed] Error deleting post: $e');
      return false;
    }
  }
}
