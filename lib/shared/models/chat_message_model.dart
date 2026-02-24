// lib/models/chat_message_model.dart

class ChatMessageModel {
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessageModel({
    required this.userId,
    required this.message,
    required this.timestamp,
    this.isTyping = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) =>
      ChatMessageModel(
        userId: map['userId'],
        message: map['message'],
        timestamp: DateTime.parse(map['timestamp']),
        isTyping: map['isTyping'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isTyping': isTyping,
      };
}
