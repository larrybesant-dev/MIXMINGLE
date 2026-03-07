import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Promo code model
// ---------------------------------------------------------------------------

class PromoCode {
  final String code;
  final int coinBonus;
  final int discountPercent;
  final int maxUses;
  final int usedCount;
  final DateTime? expiry;
  final bool isActive;

  const PromoCode({
    required this.code,
    required this.coinBonus,
    required this.discountPercent,
    required this.maxUses,
    required this.usedCount,
    this.expiry,
    required this.isActive,
  });

  bool get isUsable =>
      isActive &&
      usedCount < maxUses &&
      (expiry == null || expiry!.isAfter(DateTime.now()));

  factory PromoCode.fromMap(Map<String, dynamic> map) => PromoCode(
        code: map['code'] as String? ?? '',
        coinBonus: (map['coinBonus'] as num?)?.toInt() ?? 0,
        discountPercent: (map['discountPercent'] as num?)?.toInt() ?? 0,
        maxUses: (map['maxUses'] as num?)?.toInt() ?? 0,
        usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
        expiry: (map['expiry'] as Timestamp?)?.toDate(),
        isActive: map['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'coinBonus': coinBonus,
        'discountPercent': discountPercent,
        'maxUses': maxUses,
        'usedCount': usedCount,
        if (expiry != null) 'expiry': Timestamp.fromDate(expiry!),
        'isActive': isActive,
      };
}

// ---------------------------------------------------------------------------
// Admin service
// ---------------------------------------------------------------------------

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---- Promo codes --------------------------------------------------------

  Future<void> createPromoCode(PromoCode promo) async {
    await _firestore
        .collection('promoCodes')
        .doc(promo.code.toUpperCase())
        .set(promo.toMap());
  }

  Stream<List<PromoCode>> promoCodesStream() {
    return _firestore
        .collection('promoCodes')
        .snapshots()
        .map((s) => s.docs
            .map((d) => PromoCode.fromMap({...d.data(), 'code': d.id}))
            .toList()
          ..sort((a, b) {
            if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
            return 0;
          }));
  }

  Future<void> deactivatePromoCode(String code) async {
    await _firestore
        .collection('promoCodes')
        .doc(code.toUpperCase())
        .update({'isActive': false});
  }

  /// Validates and applies a promo code for [userId]. Returns coins granted.
  Future<int> redeemPromoCode(String code, String userId) async {
    final docRef =
        _firestore.collection('promoCodes').doc(code.toUpperCase());
    return _firestore.runTransaction<int>((tx) async {
      final doc = await tx.get(docRef);
      if (!doc.exists) throw Exception('Invalid promo code.');
      final promo = PromoCode.fromMap({...doc.data()!, 'code': doc.id});
      if (!promo.isUsable) throw Exception('Code is expired or used up.');

      // Check this user hasn't already redeemed it.
      final usageRef = docRef.collection('redeemedBy').doc(userId);
      final usageSnap = await tx.get(usageRef);
      if (usageSnap.exists) throw Exception('You already used this code.');

      tx.update(docRef, {'usedCount': FieldValue.increment(1)});
      tx.set(usageRef, {'redeemedAt': FieldValue.serverTimestamp()});

      if (promo.coinBonus > 0) {
        tx.update(_firestore.collection('users').doc(userId), {
          'coinBalance': FieldValue.increment(promo.coinBonus),
        });
      }
      return promo.coinBonus;
    });
  }

  // ---- User moderation ----------------------------------------------------

  Future<void> banUser(
    String userId,
    String reason, {
    Duration? duration,
  }) async {
    final expiry = duration != null
        ? Timestamp.fromDate(DateTime.now().add(duration))
        : null;
    await _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'banReason': reason,
      'banExpiry': expiry,
      'bannedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('adminActions').add({
      'type': 'user_ban',
      'targetId': userId,
      'reason': reason,
      if (expiry != null) 'expiry': expiry,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': false,
      'banReason': FieldValue.delete(),
      'banExpiry': FieldValue.delete(),
    });
    await _firestore.collection('adminActions').add({
      'type': 'user_unban',
      'targetId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> grantPremium(String userId, {int days = 30}) async {
    final expiry = Timestamp.fromDate(
        DateTime.now().add(Duration(days: days)));
    await _firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumGrantedBy': 'admin',
      'premiumExpiry': expiry,
    });
  }

  Future<void> grantCoins(String userId, int amount) async {
    await _firestore.collection('users').doc(userId).update({
      'coinBalance': FieldValue.increment(amount),
    });
    await _firestore.collection('adminActions').add({
      'type': 'coin_grant',
      'targetId': userId,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---- Room moderation ----------------------------------------------------

  Future<void> closeRoom(String roomId, String reason) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'isActive': false,
      'closedByAdmin': true,
      'closeReason': reason,
      'closedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('adminActions').add({
      'type': 'room_close',
      'targetId': roomId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---- Analytics ----------------------------------------------------------

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore
            .collection('rooms')
            .where('isActive', isEqualTo: true)
            .count()
            .get(),
        _firestore.collection('sentGifts').count().get(),
        _firestore.collection('reportedMessages').count().get(),
        _firestore
            .collection('users')
            .where('isPremium', isEqualTo: true)
            .count()
            .get(),
      ]);
      return {
        'totalUsers': results[0].count ?? 0,
        'activeRooms': results[1].count ?? 0,
        'giftsTotal': results[2].count ?? 0,
        'pendingReports': results[3].count ?? 0,
        'premiumUsers': results[4].count ?? 0,
      };
    } catch (e) {
      debugPrint('AdminService.getDashboardStats: $e');
      return {
        'totalUsers': 0,
        'activeRooms': 0,
        'giftsTotal': 0,
        'pendingReports': 0,
        'premiumUsers': 0,
      };
    }
  }
}
