// lib/shared/models/app_notification.dart
//
// Firestore schema:
//   /users/{uid}/notifications/{notificationId}
//     type, senderId, targetId, metadata, isRead, timestamp
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ── Notification types ────────────────────────────────────────────────────────
enum AppNotificationType {
  // Chat
  chatMessage,
  // Feed
  like,
  comment,
  // Friends
  friendRequest,
  friendAccepted,
  // Rooms
  roomInvite,
  roomLive,
  // Speed Dating
  speedDatingMatch,
  // System
  system,
  // Tips
  tip,
  // Follow
  newFollower,
}

// ── AppNotification model ─────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final AppNotificationType type;
  final String receiverId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;

  /// Human-readable body text
  final String body;

  /// Generic key→value bag for deep-link params (chatId, roomId, postId…)
  final Map<String, dynamic> metadata;

  final bool isRead;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.type,
    required this.receiverId,
    required this.body,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    this.metadata = const {},
    this.isRead = false,
    required this.timestamp,
  });

  // ── Factories ─────────────────────────────────────────────────────────────
  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification.fromMap(data, doc.id);
  }

  factory AppNotification.fromMap(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      type: AppNotificationType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'system'),
        orElse: () => AppNotificationType.system,
      ),
      receiverId: data['receiverId'] as String? ?? '',
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      body: data['body'] as String? ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      isRead: data['isRead'] as bool? ?? false,
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'type': type.name,
        'receiverId': receiverId,
        if (senderId != null) 'senderId': senderId,
        if (senderName != null) 'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        'body': body,
        'metadata': metadata,
        'isRead': isRead,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        receiverId: receiverId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        body: body,
        metadata: metadata,
        isRead: isRead ?? this.isRead,
        timestamp: timestamp,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the group label used in grouped notification UI.
  String get groupLabel {
    switch (type) {
      case AppNotificationType.chatMessage:
        return 'Chats';
      case AppNotificationType.like:
      case AppNotificationType.comment:
        return 'Feed';
      case AppNotificationType.friendRequest:
      case AppNotificationType.friendAccepted:
        return 'Friend Requests';
      case AppNotificationType.roomInvite:
      case AppNotificationType.roomLive:
        return 'Room Invites';
      case AppNotificationType.speedDatingMatch:
        return 'Matches';
      case AppNotificationType.tip:
        return 'Tips';
      case AppNotificationType.newFollower:
        return 'Followers';
      case AppNotificationType.system:
        return 'System';
    }
  }

  /// Returns the deep-link route for tapping this notification.
  String? get route {
    switch (type) {
      case AppNotificationType.chatMessage:
        final chatId = metadata['chatId'] as String?;
        return chatId != null ? '/chat?chatId=$chatId' : '/messages';
      case AppNotificationType.like:
      case AppNotificationType.comment:
        final postId = metadata['postId'] as String?;
        return postId != null ? '/post/$postId' : '/feed';
      case AppNotificationType.friendRequest:
      case AppNotificationType.friendAccepted:
        return '/friend-requests';
      case AppNotificationType.roomInvite:
      case AppNotificationType.roomLive:
        final roomId = metadata['roomId'] as String?;
        return roomId != null ? '/room/$roomId' : '/rooms';
      case AppNotificationType.speedDatingMatch:
        return '/speed-dating/matches';
      case AppNotificationType.tip:
        return '/profile';
      case AppNotificationType.newFollower:
        final uid = senderId;
        return uid != null ? '/profile/$uid' : '/profile';
      case AppNotificationType.system:
        return null;
    }
  }
}
