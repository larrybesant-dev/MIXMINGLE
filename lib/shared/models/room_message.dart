import 'package:cloud_firestore/cloud_firestore.dart';

/// Room chat message model - represents a single message in a room
class RoomMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final String type; // 'text', 'system', 'image', 'join', 'leave'
  final bool deleted;

  RoomMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.type = 'text',
    this.deleted = false,
  });

  /// Create from Firestore document snapshot
  factory RoomMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RoomMessage(
      id: doc.id,
      text: data['text'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? 'text',
      deleted: data['deleted'] as bool? ?? false,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() => {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'createdAt': Timestamp.fromDate(createdAt),
        'type': type,
        'deleted': deleted,
      };

  @override
  String toString() => 'RoomMessage(id: $id, senderId: $senderId, text: $text)';
}
