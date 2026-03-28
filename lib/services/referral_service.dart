import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/referral_model.dart';

class ReferralService {
  ReferralService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<String> generateReferralCode(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId is required');
    }

    final existing = await _firestore
        .collection('referral_codes')
        .where('ownerUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final random = Random();
    for (var attempt = 0; attempt < 8; attempt++) {
      final suffix = List.generate(6, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
      final candidate = 'MXVY-$suffix';
      final codeRef = _firestore.collection('referral_codes').doc(candidate);
      final snapshot = await codeRef.get();
      if (snapshot.exists) {
        continue;
      }

      final model = ReferralCodeModel(
        code: candidate,
        ownerUserId: userId,
        isActive: true,
        createdAt: DateTime.now().toUtc(),
      );
      await codeRef.set(model.toJson(), SetOptions(merge: true));
      return candidate;
    }

    throw Exception('Could not generate referral code. Please retry.');
  }

  Future<bool> redeemReferral(String code, String userId) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty || userId.trim().isEmpty) {
      return false;
    }

    final codeRef = _firestore.collection('referral_codes').doc(normalizedCode);
    final codeSnapshot = await codeRef.get();
    if (!codeSnapshot.exists) {
      return false;
    }

    final codeData = codeSnapshot.data() ?? <String, dynamic>{};
    final ownerUserId = (codeData['ownerUserId'] as String? ?? '').trim();
    final isActive = codeData['isActive'] as bool? ?? true;
    if (!isActive || ownerUserId.isEmpty || ownerUserId == userId) {
      return false;
    }

    final existing = await _firestore
        .collection('referrals')
        .where('referredUserId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return false;
    }

    final referralRef = _firestore.collection('referrals').doc();
    final attribution = ReferralAttributionModel(
      id: referralRef.id,
      referrerUserId: ownerUserId,
      referredUserId: userId,
      referralCode: normalizedCode,
      subscriptionStatus: 'pending',
      rewardStatus: 'pending',
      createdAt: DateTime.now().toUtc(),
    );

    await referralRef.set(attribution.toJson());
    return true;
  }

  Stream<String?> referralCodeStream(String userId) {
    if (userId.trim().isEmpty) {
      return Stream<String?>.value(null);
    }

    return _firestore
        .collection('referral_codes')
        .where('ownerUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : snapshot.docs.first.id);
  }

  Stream<double> referralEarningsTotalStream(String userId) {
    if (userId.trim().isEmpty) {
      return Stream<double>.value(0);
    }

    return _firestore
        .collection('referral_earnings')
        .where('beneficiaryUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    });
  }

  Stream<List<ReferralAttributionModel>> referralsForUserStream(String userId) {
    if (userId.trim().isEmpty) {
      return Stream<List<ReferralAttributionModel>>.value(<ReferralAttributionModel>[]);
    }

    return _firestore
        .collection('referrals')
        .where('referrerUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralAttributionModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList(growable: false));
  }
}
