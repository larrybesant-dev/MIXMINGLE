import 'package:cloud_firestore/cloud_firestore.dart';

class RoomGiftEvent {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String roomId;
  final String giftId;
  final int coinCost;
  final DateTime sentAt;

  const RoomGiftEvent({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.roomId,
    required this.giftId,
    required this.coinCost,
    required this.sentAt,
  });

  factory RoomGiftEvent.fromJson(String docId, Map<String, dynamic> data) {
    final sentAtRaw = data['sentAt'];
    DateTime sentAt;
    if (sentAtRaw is Timestamp) {
      sentAt = sentAtRaw.toDate();
    } else if (sentAtRaw is String) {
      sentAt = DateTime.tryParse(sentAtRaw) ?? DateTime.now();
    } else {
      sentAt = DateTime.now();
    }
    return RoomGiftEvent(
      id: docId,
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      receiverId: (data['receiverId'] as String?) ?? '',
      roomId: (data['roomId'] as String?) ?? '',
      giftId: (data['giftId'] as String?) ?? '',
      coinCost: (data['coinCost'] as num?)?.toInt() ?? 0,
      sentAt: sentAt,
    );
  }
}

class RoomTopGifter {
  final String userId;
  final String displayName;
  final int totalCoins;

  const RoomTopGifter({
    required this.userId,
    required this.displayName,
    required this.totalCoins,
  });
}
