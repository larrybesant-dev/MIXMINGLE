import 'package:cloud_firestore/cloud_firestore.dart';

/// Typing indicator for showing when users are typing in chat
class TypingIndicator {
  final String userId;
  final String userName;
  final String chatId; // Room or DM ID
  final DateTime startedAt;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.chatId,
    required this.startedAt,
  });

  factory TypingIndicator.fromMap(Map<String, dynamic> map) {
    return TypingIndicator(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Someone',
      chatId: map['chatId'] ?? '',
      startedAt: (map['startedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'chatId': chatId,
      'startedAt': Timestamp.fromDate(startedAt),
    };
  }

  /// Check if typing indicator is still valid (less than 5 seconds old)
  bool get isValid {
    return DateTime.now().difference(startedAt).inSeconds < 5;
  }
}
