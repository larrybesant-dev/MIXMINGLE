import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Activity event types for the unified social graph
enum ActivityEventType {
  follow,
  like,
  comment,
  roomJoin,
  postCreate,
  match,
  storyView,
  storyPost,
  shortVideoPost,
  videoLike,
  gift,
  achievement,
}

extension ActivityEventTypeX on ActivityEventType {
  String get value => toString().split('.').last;

  static ActivityEventType fromString(String s) => ActivityEventType.values
      .firstWhere((e) => e.value == s, orElse: () => ActivityEventType.follow);
}

/// A single activity event written to the `activity_events` collection.
class ActivityEvent {
  final String id;
  final ActivityEventType type;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String targetId; // userId whose feed receives this event
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.targetId,
    this.metadata = const {},
    required this.createdAt,
  });

  factory ActivityEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ActivityEvent(
      id: doc.id,
      type: ActivityEventTypeX.fromString(d['type'] ?? ''),
      actorId: d['actorId'] ?? '',
      actorName: d['actorName'] ?? '',
      actorPhotoUrl: d['actorPhotoUrl'],
      targetId: d['targetId'] ?? '',
      metadata: Map<String, dynamic>.from(d['metadata'] ?? {}),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.value,
        'actorId': actorId,
        'actorName': actorName,
        'actorPhotoUrl': actorPhotoUrl,
        'targetId': targetId,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      };

  String get displayText {
    switch (type) {
      case ActivityEventType.follow:
        return '$actorName started following you';
      case ActivityEventType.like:
        return '$actorName liked your post';
      case ActivityEventType.comment:
        return '$actorName commented on your post';
      case ActivityEventType.roomJoin:
        return '$actorName joined your room';
      case ActivityEventType.postCreate:
        return '$actorName shared a new post';
      case ActivityEventType.match:
        return "You matched with $actorName!";
      case ActivityEventType.storyView:
        return '$actorName viewed your story';
      case ActivityEventType.storyPost:
        return '$actorName posted a new story';
      case ActivityEventType.shortVideoPost:
        return '$actorName posted a new video';
      case ActivityEventType.videoLike:
        return '$actorName liked your video';
      case ActivityEventType.gift:
        return '$actorName sent you a gift';
      case ActivityEventType.achievement:
        return '$actorName unlocked an achievement';
    }
  }

  String get iconEmoji {
    switch (type) {
      case ActivityEventType.follow:
        return '👤';
      case ActivityEventType.like:
        return '❤️';
      case ActivityEventType.comment:
        return '💬';
      case ActivityEventType.roomJoin:
        return '🚪';
      case ActivityEventType.postCreate:
        return '📝';
      case ActivityEventType.match:
        return '💕';
      case ActivityEventType.storyView:
        return '👁️';
      case ActivityEventType.storyPost:
        return '✨';
      case ActivityEventType.shortVideoPost:
        return '🎬';
      case ActivityEventType.videoLike:
        return '🎥';
      case ActivityEventType.gift:
        return '🎁';
      case ActivityEventType.achievement:
        return '🏆';
    }
  }
}

/// Service that writes to and reads from the `activity_events` Firestore collection.
/// All social actions that should appear in a user's activity feed call [writeEvent].
class ActivityFeedService {
  static final ActivityFeedService _instance = ActivityFeedService._internal();
  factory ActivityFeedService() => _instance;
  ActivityFeedService._internal();

  static ActivityFeedService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('activity_events');

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Writes a single activity event targeted at [targetUserId]'s feed.
  Future<void> writeEvent({
    required ActivityEventType type,
    required String targetId,
    Map<String, dynamic> metadata = const {},
    String? actorIdOverride,
    String? actorNameOverride,
    String? actorPhotoOverride,
  }) async {
    try {
      final user = _auth.currentUser;
      final actorId = actorIdOverride ?? user?.uid;
      if (actorId == null) return;
      // Don't write self-events (e.g. user liking own post)
      if (actorId == targetId) return;

      String actorName = actorNameOverride ?? user?.displayName ?? 'Someone';
      String? actorPhoto = actorPhotoOverride ?? user?.photoURL;

      // Resolve actor name from Firestore if not provided
      if (actorNameOverride == null && user != null) {
        try {
          final doc = await _db.collection('users').doc(actorId).get();
          actorName = doc.data()?['displayName'] ?? actorName;
          actorPhoto = doc.data()?['photoUrl'] ?? doc.data()?['avatarUrl'] ?? actorPhoto;
        } catch (_) {}
      }

      await _col.add({
        'type': type.value,
        'actorId': actorId,
        'actorName': actorName,
        'actorPhotoUrl': actorPhoto,
        'targetId': targetId,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('❌ [ActivityFeed] writeEvent error: $e');
    }
  }

  // ── Convenience wrappers ───────────────────────────────────────────────────

  Future<void> onFollow(String targetUserId) => writeEvent(
        type: ActivityEventType.follow,
        targetId: targetUserId,
      );

  Future<void> onLikePost(String postOwnerId, String postId) => writeEvent(
        type: ActivityEventType.like,
        targetId: postOwnerId,
        metadata: {'postId': postId},
      );

  Future<void> onComment(String postOwnerId, String postId, String snippet) =>
      writeEvent(
        type: ActivityEventType.comment,
        targetId: postOwnerId,
        metadata: {'postId': postId, 'snippet': snippet},
      );

  Future<void> onRoomJoin(String hostUserId, String roomId, String roomName) =>
      writeEvent(
        type: ActivityEventType.roomJoin,
        targetId: hostUserId,
        metadata: {'roomId': roomId, 'roomName': roomName},
      );

  Future<void> onMatch(String matchedUserId, String matchId) => writeEvent(
        type: ActivityEventType.match,
        targetId: matchedUserId,
        metadata: {'matchId': matchId},
      );

  Future<void> onStoryView(String storyOwnerId, String storyId) => writeEvent(
        type: ActivityEventType.storyView,
        targetId: storyOwnerId,
        metadata: {'storyId': storyId},
      );

  Future<void> onVideoLike(String videoOwnerId, String videoId) => writeEvent(
        type: ActivityEventType.videoLike,
        targetId: videoOwnerId,
        metadata: {'videoId': videoId},
      );

  Future<void> onGiftSent(String recipientId, String giftName, int coins) =>
      writeEvent(
        type: ActivityEventType.gift,
        targetId: recipientId,
        metadata: {'giftName': giftName, 'coins': coins},
      );

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Stream of the current user's activity feed, newest-first, limited to [limit].
  Stream<List<ActivityEvent>> watchMyFeed({int limit = 40}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _col
        .where('targetId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .withConverter<ActivityEvent>(
          fromFirestore: (s, _) => ActivityEvent.fromFirestore(s),
          toFirestore: (e, _) => e.toFirestore(),
        )
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.data()).toList())
        .handleError((e) {
      debugPrint('❌ [ActivityFeed] watchMyFeed error: $e');
      return <ActivityEvent>[];
    });
  }

  /// One-shot fetch for profile / preview cards.
  Future<List<ActivityEvent>> getRecentFeed({int limit = 20}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];
      final qs = await _col
          .where('targetId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return qs.docs
          .map((d) => ActivityEvent.fromFirestore(d))
          .toList();
    } catch (e) {
      debugPrint('❌ [ActivityFeed] getRecentFeed: $e');
      return [];
    }
  }

  /// Count of unread events (badge counter).
  Stream<int> watchUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return _col
        .where('targetId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((qs) => qs.size)
        .handleError((_) => 0);
  }

  /// Mark all events as read for the current user.
  Future<void> markAllRead() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final unread = await _col
          .where('targetId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get();
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ActivityFeed] markAllRead: $e');
    }
  }
}
