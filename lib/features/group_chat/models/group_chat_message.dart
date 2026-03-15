import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupChatMessageType { text }

class GroupChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final GroupChatMessageType type;
  final DateTime? timestamp;

  const GroupChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    this.timestamp,
  });

  factory GroupChatMessage.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GroupChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown User',
      text: data['text'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type.name,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }

  static GroupChatMessageType _parseType(String? raw) {
    if (raw == GroupChatMessageType.text.name) return GroupChatMessageType.text;
    return GroupChatMessageType.text;
  }
}
