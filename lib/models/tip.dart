import 'package:cloud_firestore/cloud_firestore.dart';

class Tip {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final int amount;
  final String message;
  final String? roomId;
  final DateTime timestamp;

  Tip({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    required this.message,
    this.roomId,
    required this.timestamp,
  });

  factory Tip.fromMap(Map<String, dynamic> map) {
    return Tip(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      amount: map['amount'] ?? 0,
      message: map['message'] ?? '',
      roomId: map['roomId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'amount': amount,
      'message': message,
      'roomId': roomId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}


