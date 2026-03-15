// lib/services/notifications/app_notification_service.dart
//
// In-app notification service using Firestore subcollections.
//
// Firestore schema:
//   /users/{uid}/notifications/{notificationId}
//     type, senderId, senderName, senderAvatarUrl,
//     body, metadata, isRead, timestamp, receiverId
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/app_notification.dart';

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference _notifCol(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  // ── Send ───────────────────────────────────────────────────────────────────

  /// Creates a new notification document in the receiver's subcollection.
  Future<void> sendNotification({
    required AppNotificationType type,
    required String receiverId,
    required String body,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (receiverId.isEmpty || receiverId == (senderId ?? _uid)) return;
    try {
      final ref = _notifCol(receiverId).doc();
      final notif = AppNotification(
        id: ref.id,
        type: type,
        receiverId: receiverId,
        senderId: senderId ?? _uid,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        body: body,
        metadata: metadata,
        isRead: false,
        timestamp: DateTime.now(),
      );
      await ref.set(notif.toMap());
      debugPrint('[AppNotificationService] sent ${type.name} → $receiverId');
    } catch (e) {
      debugPrint('[AppNotificationService] sendNotification error: $e');
    }
  }

  // ── Mark as read ───────────────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    if (_uid.isEmpty) return;
    try {
      await _notifCol(_uid).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AppNotificationService] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_uid.isEmpty) return;
    try {
      final unread = await _notifCol(_uid)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('[AppNotificationService] marked all as read (${unread.docs.length})');
    } catch (e) {
      debugPrint('[AppNotificationService] markAllAsRead error: $e');
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteNotification(String notificationId) async {
    if (_uid.isEmpty) return;
    try {
      await _notifCol(_uid).doc(notificationId).delete();
    } catch (e) {
      debugPrint('[AppNotificationService] deleteNotification error: $e');
    }
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Real-time stream of the current user's notifications (newest first).
  Stream<List<AppNotification>> streamUserNotifications({int limit = 60}) {
    if (_uid.isEmpty) return Stream.value([]);
    return _notifCol(_uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromDoc(d)).toList());
  }

  /// Live unread count stream for badge display.
  Stream<int> streamUnreadCount() {
    if (_uid.isEmpty) return Stream.value(0);
    return _notifCol(_uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Typed convenience senders ──────────────────────────────────────────────

  Future<void> notifyNewChatMessage({
    required String receiverId,
    required String senderName,
    required String chatId,
    required String preview,
    String? senderAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.chatMessage,
      receiverId: receiverId,
      body: '$senderName: $preview',
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      metadata: {'chatId': chatId},
    );
  }

  Future<void> notifyFriendRequest({
    required String receiverId,
    required String senderName,
    String? senderAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.friendRequest,
      receiverId: receiverId,
      body: '$senderName sent you a friend request',
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
    );
  }

  Future<void> notifyFriendAccepted({
    required String receiverId,
    required String acceptorName,
    String? acceptorAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.friendAccepted,
      receiverId: receiverId,
      body: '$acceptorName accepted your friend request',
      senderName: acceptorName,
      senderAvatarUrl: acceptorAvatarUrl,
    );
  }

  Future<void> notifyLike({
    required String receiverId,
    required String likerName,
    required String postId,
    String? likerAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.like,
      receiverId: receiverId,
      body: '$likerName liked your post',
      senderName: likerName,
      senderAvatarUrl: likerAvatarUrl,
      metadata: {'postId': postId},
    );
  }

  Future<void> notifyComment({
    required String receiverId,
    required String commenterName,
    required String postId,
    required String commentPreview,
    String? commenterAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.comment,
      receiverId: receiverId,
      body: '$commenterName commented: $commentPreview',
      senderName: commenterName,
      senderAvatarUrl: commenterAvatarUrl,
      metadata: {'postId': postId},
    );
  }

  Future<void> notifyRoomInvite({
    required String receiverId,
    required String inviterName,
    required String roomId,
    required String roomName,
    String? inviterAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.roomInvite,
      receiverId: receiverId,
      body: '$inviterName invited you to "$roomName"',
      senderName: inviterName,
      senderAvatarUrl: inviterAvatarUrl,
      metadata: {'roomId': roomId, 'roomName': roomName},
    );
  }

  Future<void> notifySpeedDatingMatch({
    required String receiverId,
    required String matchName,
    String? matchAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.speedDatingMatch,
      receiverId: receiverId,
      body: "It's a match! You and $matchName both liked each other 🎉",
      senderName: matchName,
      senderAvatarUrl: matchAvatarUrl,
    );
  }

  Future<void> notifyNewFollower({
    required String receiverId,
    required String followerName,
    String? followerAvatarUrl,
  }) {
    return sendNotification(
      type: AppNotificationType.newFollower,
      receiverId: receiverId,
      body: '$followerName started following you',
      senderName: followerName,
      senderAvatarUrl: followerAvatarUrl,
    );
  }
}
