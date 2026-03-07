import 'package:cloud_firestore/cloud_firestore.dart';

enum GiftRarity { common, rare, epic, legendary }

/// A virtual gift item from the gift catalog.
class Gift {
  final String id;
  final String name;
  final String emoji;
  final int coinCost;
  final GiftRarity rarity;
  final String? animationUrl;
  final bool isAvailable;

  const Gift({
    required this.id,
    required this.name,
    required this.emoji,
    required this.coinCost,
    required this.rarity,
    this.animationUrl,
    this.isAvailable = true,
  });

  factory Gift.fromMap(Map<String, dynamic> map) => Gift(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '🎁',
        coinCost: (map['coinCost'] as num?)?.toInt() ?? 0,
        rarity: GiftRarity.values.firstWhere(
          (r) => r.name == map['rarity'],
          orElse: () => GiftRarity.common,
        ),
        animationUrl: map['animationUrl'] as String?,
        isAvailable: map['isAvailable'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'coinCost': coinCost,
        'rarity': rarity.name,
        if (animationUrl != null) 'animationUrl': animationUrl,
        'isAvailable': isAvailable,
      };
}

/// A record of a sent gift (written to `sentGifts` collection).
class SentGift {
  final String id;
  final String giftId;
  final String giftName;
  final String giftEmoji;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String? roomId;
  final int coinCost;
  final DateTime sentAt;

  const SentGift({
    required this.id,
    required this.giftId,
    required this.giftName,
    required this.giftEmoji,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    this.roomId,
    required this.coinCost,
    required this.sentAt,
  });

  factory SentGift.fromMap(Map<String, dynamic> map) => SentGift(
        id: map['id'] as String? ?? '',
        giftId: map['giftId'] as String? ?? '',
        giftName: map['giftName'] as String? ?? '',
        giftEmoji: map['giftEmoji'] as String? ?? '🎁',
        senderId: map['senderId'] as String? ?? '',
        senderName: map['senderName'] as String? ?? 'Someone',
        receiverId: map['receiverId'] as String? ?? '',
        roomId: map['roomId'] as String?,
        coinCost: (map['coinCost'] as num?)?.toInt() ?? 0,
        sentAt: map['sentAt'] != null
            ? (map['sentAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'giftId': giftId,
        'giftName': giftName,
        'giftEmoji': giftEmoji,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'roomId': roomId,
        'coinCost': coinCost,
        'sentAt': Timestamp.fromDate(sentAt),
      };
}
