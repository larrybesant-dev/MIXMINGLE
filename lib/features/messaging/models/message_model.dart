import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final List<String> readBy; // UIDs of users who read this message

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.readBy = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json, String docId) {
    return Message(
      id: docId,
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (json['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      readBy: List<String>.from((json['readBy'] as List<dynamic>?) ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'readBy': readBy,
    };
  }

  bool isRead(String userId) => readBy.contains(userId);
}
