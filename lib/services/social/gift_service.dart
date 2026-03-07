import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/gift.dart';

/// Default gift catalog — seeded into Firestore on first load.
const List<Gift> kDefaultGiftCatalog = [
  Gift(id: 'rose',      name: 'Rose',      emoji: '🌹', coinCost: 10,   rarity: GiftRarity.common),
  Gift(id: 'heart',     name: 'Heart',     emoji: '❤️', coinCost: 20,   rarity: GiftRarity.common),
  Gift(id: 'star',      name: 'Star',      emoji: '⭐', coinCost: 15,   rarity: GiftRarity.common),
  Gift(id: 'fire',      name: 'Fire',      emoji: '🔥', coinCost: 30,   rarity: GiftRarity.common),
  Gift(id: 'rocket',    name: 'Rocket',    emoji: '🚀', coinCost: 50,   rarity: GiftRarity.rare),
  Gift(id: 'mic',       name: 'Mic',       emoji: '🎤', coinCost: 40,   rarity: GiftRarity.rare),
  Gift(id: 'party',     name: 'Party',     emoji: '🎉', coinCost: 75,   rarity: GiftRarity.rare),
  Gift(id: 'lightning', name: 'Lightning', emoji: '⚡', coinCost: 60,   rarity: GiftRarity.rare),
  Gift(id: 'diamond',   name: 'Diamond',   emoji: '💎', coinCost: 100,  rarity: GiftRarity.epic),
  Gift(id: 'crown',     name: 'Crown',     emoji: '👑', coinCost: 250,  rarity: GiftRarity.epic),
  Gift(id: 'trophy',    name: 'Trophy',    emoji: '🏆', coinCost: 500,  rarity: GiftRarity.legendary),
  Gift(id: 'unicorn',   name: 'Unicorn',   emoji: '🦄', coinCost: 1000, rarity: GiftRarity.legendary),
];

class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Catalog
  // ---------------------------------------------------------------------------

  /// Fetches the gift catalog from Firestore. Falls back to embedded catalog.
  Future<List<Gift>> getCatalog() async {
    try {
      final snapshot = await _firestore.collection('giftCatalog').get();
      if (snapshot.docs.isEmpty) {
        await _seedCatalog();
        return kDefaultGiftCatalog;
      }
      return snapshot.docs
          .map((doc) => Gift.fromMap({...doc.data(), 'id': doc.id}))
          .where((g) => g.isAvailable)
          .toList()
        ..sort((a, b) => a.coinCost.compareTo(b.coinCost));
    } catch (e) {
      debugPrint('GiftService.getCatalog: $e');
      return kDefaultGiftCatalog;
    }
  }

  /// Streams a user's coin balance.
  Stream<int> coinBalanceStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => (doc.data()?['coinBalance'] as num?)?.toInt() ?? 0);
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Streams the last 20 gifts sent in a room.
  Stream<List<SentGift>> roomGiftStream(String roomId) {
    return _firestore
        .collection('sentGifts')
        .where('roomId', isEqualTo: roomId)
        .orderBy('sentAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => SentGift.fromMap({...d.data(), 'id': d.id})).toList());
  }

  /// Streams gifts received by a user.
  Stream<List<SentGift>> receivedGiftsStream(String userId) {
    return _firestore
        .collection('sentGifts')
        .where('receiverId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => SentGift.fromMap({...d.data(), 'id': d.id})).toList());
  }

  // ---------------------------------------------------------------------------
  // Send
  // ---------------------------------------------------------------------------

  /// Sends a gift from [senderId] to [receiverId] (in optional [roomId]).
  /// Atomically:
  ///  1. Deducts [gift.coinCost] from sender's balance.
  ///  2. Credits 80 % of coin value to receiver.
  ///  3. Writes a `sentGifts` document.
  ///  4. Writes a `notifications` document for receiver.
  ///  5. Writes a room event so the room page can animate the gift.
  Future<void> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    String? roomId,
    required Gift gift,
  }) async {
    // Check balance first (outside the batch) to give a clear error message.
    final senderSnap =
        await _firestore.collection('users').doc(senderId).get();
    final balance = (senderSnap.data()?['coinBalance'] as num?)?.toInt() ?? 0;
    if (balance < gift.coinCost) {
      throw Exception(
          'Not enough coins. You have $balance but need ${gift.coinCost}.');
    }

    final batch = _firestore.batch();
    final now = DateTime.now();

    // 1 — Deduct from sender
    batch.update(_firestore.collection('users').doc(senderId), {
      'coinBalance': FieldValue.increment(-gift.coinCost),
    });

    // 2 — Credit 80 % to receiver
    final receiverCredit = (gift.coinCost * 0.8).round();
    batch.update(_firestore.collection('users').doc(receiverId), {
      'coinBalance': FieldValue.increment(receiverCredit),
    });

    // 3 — sentGifts record
    final giftRef = _firestore.collection('sentGifts').doc();
    final sent = SentGift(
      id: giftRef.id,
      giftId: gift.id,
      giftName: gift.name,
      giftEmoji: gift.emoji,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      roomId: roomId,
      coinCost: gift.coinCost,
      sentAt: now,
    );
    batch.set(giftRef, sent.toMap());

    // 4 — Notification for receiver
    batch.set(_firestore.collection('notifications').doc(), {
      'userId': receiverId,
      'type': 'gift_received',
      'senderId': senderId,
      'senderName': senderName,
      'giftId': gift.id,
      'giftEmoji': gift.emoji,
      'giftName': gift.name,
      'coinValue': receiverCredit,
      'roomId': roomId,
      'read': false,
      'createdAt': Timestamp.fromDate(now),
    });

    // 5 — Room floating-animation event
    if (roomId != null) {
      batch.set(
        _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('events')
            .doc(),
        {
          'type': 'gift',
          'senderId': senderId,
          'senderName': senderName,
          'receiverId': receiverId,
          'giftId': gift.id,
          'giftEmoji': gift.emoji,
          'giftName': gift.name,
          'timestamp': Timestamp.fromDate(now),
        },
      );
    }

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _seedCatalog() async {
    try {
      final batch = _firestore.batch();
      for (final gift in kDefaultGiftCatalog) {
        batch.set(
          _firestore.collection('giftCatalog').doc(gift.id),
          gift.toMap(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('GiftService._seedCatalog: $e');
    }
  }
}
