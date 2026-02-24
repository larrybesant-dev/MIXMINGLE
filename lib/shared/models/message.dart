enum MessageType { text, image, video, audio }

enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String senderName;
  final String senderAvatarUrl;
  final String type;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final List<String> mentionedUserIds;
  final List<String> reactions;
  final bool isEdited;
  final DateTime? editedAt;

  // NEW CHAT FEATURES
  final MessageStatus status;
  final String? replyToMessageId;
  final bool isTyping;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    required this.mentionedUserIds,
    required this.reactions,
    required this.isEdited,
    this.editedAt,
    required this.status,
    this.replyToMessageId,
    required this.isTyping,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderName: json['senderName'] ?? '',
      senderAvatarUrl: json['senderAvatarUrl'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      metadata: json['metadata'],
      mentionedUserIds: List<String>.from(json['mentionedUserIds'] ?? []),
      reactions: List<String>.from(json['reactions'] ?? []),
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status'] ?? 'sent'}',
        orElse: () => MessageStatus.sent,
      ),
      replyToMessageId: json['replyToMessageId'],
      isTyping: json['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'type': type,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'mentionedUserIds': mentionedUserIds,
      'reactions': reactions,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'status': status.toString().split('.').last,
      'replyToMessageId': replyToMessageId,
      'isTyping': isTyping,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message.fromJson(map);
  }

  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    String? senderName,
    String? senderAvatarUrl,
    String? type,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    List<String>? mentionedUserIds,
    List<String>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    MessageStatus? status,
    String? replyToMessageId,
    bool? isTyping,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.senderName == senderName &&
        other.senderAvatarUrl == senderAvatarUrl &&
        other.type == type &&
        other.mediaUrl == mediaUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.metadata == metadata &&
        other.mentionedUserIds == mentionedUserIds &&
        other.reactions == reactions &&
        other.isEdited == isEdited &&
        other.editedAt == editedAt &&
        other.status == status &&
        other.replyToMessageId == replyToMessageId &&
        other.isTyping == isTyping;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roomId.hashCode ^
        senderId.hashCode ^
        content.hashCode ^
        timestamp.hashCode ^
        senderName.hashCode ^
        senderAvatarUrl.hashCode ^
        type.hashCode ^
        (mediaUrl?.hashCode ?? 0) ^
        (thumbnailUrl?.hashCode ?? 0) ^
        (metadata?.hashCode ?? 0) ^
        mentionedUserIds.hashCode ^
        reactions.hashCode ^
        isEdited.hashCode ^
        (editedAt?.hashCode ?? 0) ^
        status.hashCode ^
        (replyToMessageId?.hashCode ?? 0) ^
        isTyping.hashCode;
  }

  @override
  String toString() {
    return 'Message(id: $id, roomId: $roomId, senderId: $senderId, content: $content, timestamp: $timestamp, type: $type, status: $status, isEdited: $isEdited)';
  }
}