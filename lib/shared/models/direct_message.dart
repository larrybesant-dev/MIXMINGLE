import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart' show MessageStatus;

enum DirectMessageType {
  text,
  image,
  video,
  audio,
  file,
}

class DirectMessage {
  final String id;
  final String
      conversationId; // Unique ID for the conversation between two users
  final String senderId;
  final String receiverId;
  final DirectMessageType type;
  final String content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final bool isEdited;
  final DateTime? editedAt;
  final Map<String, List<String>> reactions; // emoji -> list of user IDs

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.readAt,
    this.isEdited = false,
    this.editedAt,
    this.reactions = const {},
  });

  factory DirectMessage.fromMap(Map<String, dynamic> map, String id) {
    return DirectMessage(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: DirectMessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DirectMessageType.text,
      ),
      content: map['content'] ?? '',
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      metadata: map['metadata'],
      status: map['status'] != null
          ? MessageStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => MessageStatus.sent,
            )
          : (map['isRead'] == true ? MessageStatus.read : MessageStatus.sent),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      isEdited: map['isEdited'] ?? false,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      reactions: Map<String, List<String>>.from(
        (map['reactions'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, List<String>.from(value as List)),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'status': status.name,
      'isRead': status == MessageStatus.read, // Backward compatibility
      'timestamp': Timestamp.fromDate(timestamp),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'reactions': reactions,
    };
  }

  /// Create a unique conversation ID for two users
  static String createConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Check if this message is from the current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Mark message as read
  DirectMessage markAsRead() {
    return DirectMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
      status: MessageStatus.read,
      timestamp: timestamp,
      readAt: DateTime.now(),
      isEdited: isEdited,
      editedAt: editedAt,
      reactions: reactions,
    );
  }

  /// Add a reaction to the message
  DirectMessage addReaction(String emoji, String userId) {
    final newReactions = Map<String, List<String>>.from(reactions);
    if (!newReactions.containsKey(emoji)) {
      newReactions[emoji] = [];
    }
    if (!newReactions[emoji]!.contains(userId)) {
      newReactions[emoji]!.add(userId);
    }

    return DirectMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
      status: status,
      timestamp: timestamp,
      readAt: readAt,
      isEdited: isEdited,
      editedAt: editedAt,
      reactions: newReactions,
    );
  }

  /// Remove a reaction from the message
  DirectMessage removeReaction(String emoji, String userId) {
    final newReactions = Map<String, List<String>>.from(reactions);
    if (newReactions.containsKey(emoji)) {
      newReactions[emoji]!.remove(userId);
      if (newReactions[emoji]!.isEmpty) {
        newReactions.remove(emoji);
      }
    }

    return DirectMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
      status: status,
      timestamp: timestamp,
      readAt: readAt,
      isEdited: isEdited,
      editedAt: editedAt,
      reactions: newReactions,
    );
  }

  /// Check if a user has reacted with a specific emoji
  bool hasUserReacted(String emoji, String userId) {
    return reactions[emoji]?.contains(userId) ?? false;
  }

  /// Get the total number of reactions
  int get totalReactions =>
      reactions.values.fold(0, (total, users) => total + users.length);

  DirectMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    DirectMessageType? type,
    String? content,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, List<String>>? reactions,
  }) {
    return DirectMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectMessage &&
        other.id == id &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.type == type &&
        other.content == content &&
        other.mediaUrl == mediaUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.metadata == metadata &&
        other.status == status &&
        other.timestamp == timestamp &&
        other.readAt == readAt &&
        other.isEdited == isEdited &&
        other.editedAt == editedAt &&
        other.reactions == reactions;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        conversationId.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        type.hashCode ^
        content.hashCode ^
        (mediaUrl?.hashCode ?? 0) ^
        (thumbnailUrl?.hashCode ?? 0) ^
        (metadata?.hashCode ?? 0) ^
        status.hashCode ^
        timestamp.hashCode ^
        (readAt?.hashCode ?? 0) ^
        isEdited.hashCode ^
        (editedAt?.hashCode ?? 0) ^
        reactions.hashCode;
  }

  @override
  String toString() {
    return 'DirectMessage(id: $id, conversationId: $conversationId, senderId: $senderId, receiverId: $receiverId, type: $type, status: $status, timestamp: $timestamp, isEdited: $isEdited, totalReactions: $totalReactions)';
  }
}
