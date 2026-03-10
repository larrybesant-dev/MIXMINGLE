/// Message types for voice room chat
enum MessageType {
  text, // Regular text message
  system, // System notifications (join/leave/kick/ban)
  emote, // Emote/action message
  sticker, // Sticker message
}

/// Chat message model for voice room text chat
class VoiceRoomChatMessage {
  final String id;
  final String userId;
  final String displayName;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final bool isDeleted;
  final String? userAvatar;
  final Map<String, dynamic>? metadata; // For additional data (sticker ID, etc.)

  const VoiceRoomChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.isDeleted = false,
    this.userAvatar,
    this.metadata,
  });

  /// Legacy isSystemMessage for backward compatibility
  bool get isSystemMessage => type == MessageType.system;

  /// Create a copy with updated fields
  VoiceRoomChatMessage copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? message,
    DateTime? timestamp,
    MessageType? type,
    bool? isDeleted,
    String? userAvatar,
    Map<String, dynamic>? metadata,
  }) {
    return VoiceRoomChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isDeleted: isDeleted ?? this.isDeleted,
      userAvatar: userAvatar ?? this.userAvatar,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isDeleted': isDeleted,
      'userAvatar': userAvatar,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory VoiceRoomChatMessage.fromJson(Map<String, dynamic> json) {
    return VoiceRoomChatMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => MessageType.text,
            )
          : (json['isSystemMessage'] as bool? ?? false)
              ? MessageType.system
              : MessageType.text,
      isDeleted: json['isDeleted'] as bool? ?? false,
      userAvatar: json['userAvatar'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': userId,
      'senderName': displayName,
      'text': message,
      'type': type.name,
      'createdAt': timestamp.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
      'isSystem': type == MessageType.system,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory VoiceRoomChatMessage.fromFirestore(String docId, Map<String, dynamic> data) {
    return VoiceRoomChatMessage(
      id: docId,
      userId: data['senderId'] as String,
      displayName: data['senderName'] as String,
      message: data['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      type: data['type'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => MessageType.text,
            )
          : (data['isSystem'] as bool? ?? false)
              ? MessageType.system
              : MessageType.text,
      isDeleted: data['isDeleted'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a system message (join/leave notification)
  factory VoiceRoomChatMessage.system({
    required String message,
    required DateTime timestamp,
  }) {
    return VoiceRoomChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'system',
      displayName: 'System',
      message: message,
      timestamp: timestamp,
      type: MessageType.system,
    );
  }

  /// Create an emote message
  factory VoiceRoomChatMessage.emote({
    required String id,
    required String userId,
    required String displayName,
    required String emote,
    required DateTime timestamp,
  }) {
    return VoiceRoomChatMessage(
      id: id,
      userId: userId,
      displayName: displayName,
      message: emote,
      timestamp: timestamp,
      type: MessageType.emote,
    );
  }
}


