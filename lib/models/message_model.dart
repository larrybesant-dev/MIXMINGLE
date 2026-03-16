import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String roomId;
  final String content;
  final DateTime sentAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.roomId,
    required this.content,
    required this.sentAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      roomId: data['roomId'] ?? '',
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'roomId': roomId,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
