// App Models and Data Classes for Video Chat Features

/// Friend user model
class Friend {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isFavorite;
  final int unreadMessages;

  Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastSeen,
    required this.isFavorite,
    required this.unreadMessages,
  });

  Friend copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isFavorite,
    int? unreadMessages,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isFavorite: isFavorite ?? this.isFavorite,
      unreadMessages: unreadMessages ?? this.unreadMessages,
    );
  }
}

/// Video group/room model
class VideoGroup {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int maxParticipants;
  final List<String> participantIds;
  final DateTime createdAt;
  final int unreadMessages;
  final String ownerId;

  VideoGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.maxParticipants,
    required this.participantIds,
    required this.createdAt,
    required this.unreadMessages,
    required this.ownerId,
  });

  VideoGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? maxParticipants,
    List<String>? participantIds,
    DateTime? createdAt,
    int? unreadMessages,
    String? ownerId,
  }) {
    return VideoGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final String type; // 'text', 'emoji', 'sticker', 'file'
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });
}

/// Participant info for video display
class VideoParticipant {
  final String userId;
  final String userName;
  final String avatarUrl;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final DateTime joinedAt;
  final String? cameraApprovalStatus; // null, 'pending', 'approved', 'denied'

  VideoParticipant({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.isAudioEnabled,
    required this.isVideoEnabled,
    required this.isScreenSharing,
    required this.joinedAt,
    this.cameraApprovalStatus,
  });

  VideoParticipant copyWith({
    String? userId,
    String? userName,
    String? avatarUrl,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    DateTime? joinedAt,
    String? cameraApprovalStatus,
  }) {
    return VideoParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      joinedAt: joinedAt ?? this.joinedAt,
      cameraApprovalStatus: cameraApprovalStatus ?? this.cameraApprovalStatus,
    );
  }
}

/// Reaction model for engagement features
class MessageReaction {
  final String emoji;
  final String userId;
  final String userName;
  final DateTime timestamp;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });
}

/// Video quality settings
enum VideoQuality {
  low, // 180p
  medium, // 360p
  high, // 720p
}

/// Notification action button
class NotificationAction {
  final String id;
  final String label;
  final String? icon;
  final void Function()? onPressed;

  NotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.onPressed,
  });
}

/// Extended app notification model with FCM support
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'message', 'friend_request', 'group_invite', 'system_alert', 'video_call'
  final String? icon;
  final DateTime timestamp;
  final bool isRead;

  // FCM specific fields
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final Map<String, dynamic>? metadata; // For storing additional data (roomId, groupId, etc)
  final List<NotificationAction>? actions; // Action buttons
  final String? largeIcon;
  final String? imageUrl;
  final String? sound;
  final int? priority; // 0-2: low, normal, high
  final String? tag; // For grouping notifications

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    required this.timestamp,
    required this.isRead,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.metadata,
    this.actions,
    this.largeIcon,
    this.imageUrl,
    this.sound,
    this.priority,
    this.tag,
  });

  /// Create a copy with modifications
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? icon,
    DateTime? timestamp,
    bool? isRead,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    Map<String, dynamic>? metadata,
    List<NotificationAction>? actions,
    String? largeIcon,
    String? imageUrl,
    String? sound,
    int? priority,
    String? tag,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      metadata: metadata ?? this.metadata,
      actions: actions ?? this.actions,
      largeIcon: largeIcon ?? this.largeIcon,
      imageUrl: imageUrl ?? this.imageUrl,
      sound: sound ?? this.sound,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
    );
  }

  /// Create notification from FCM payload
  factory AppNotification.fromFCMPayload(Map<String, dynamic> payload, {required String id}) {
    return AppNotification(
      id: id,
      title: payload['title'] ?? 'Notification',
      message: payload['body'] ?? '',
      type: payload['notificationType'] ?? 'system_alert',
      senderId: payload['senderId'],
      senderName: payload['senderName'],
      senderAvatar: payload['senderAvatar'],
      metadata: payload['metadata'] != null ? Map<String, dynamic>.from(payload['metadata'] as Map) : null,
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: payload['imageUrl'],
      sound: payload['sound'],
      priority: payload['priority'] != null ? int.tryParse(payload['priority'].toString()) : null,
      tag: payload['tag'],
    );
  }

  /// Create an empty notification (for default cases)
  factory AppNotification.empty() {
    return AppNotification(
      id: '',
      title: 'Notification',
      message: '',
      type: 'system_alert',
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppNotification && other.id == id && other.message == message && other.type == type && other.isRead == isRead;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ message.hashCode ^ isRead.hashCode;
}


