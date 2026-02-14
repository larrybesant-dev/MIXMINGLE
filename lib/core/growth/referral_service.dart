/// Referral Service
///
/// Manages referral codes, tracking, and rewards for viral growth.
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing referral program
class ReferralService {
  static ReferralService? _instance;
  static ReferralService get instance => _instance ??= ReferralService._();

  ReferralService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Referral reward amounts
  static const int referrerCoinReward = 50;
  static const int refereeCoinReward = 25;
  static const int vipReferrerBonusCoins = 25;

  // ============================================================
  // REFERRAL CODE GENERATION
  // ============================================================

  /// Generate a unique referral code for a user
  /// Returns existing code if user already has one
  Future<String> generateReferralCode(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final referralRef = userRef.collection('referral').doc('info');

      final referralDoc = await referralRef.get();

      // Return existing code if available
      if (referralDoc.exists && referralDoc.data()?['code'] != null) {
        return referralDoc.data()!['code'] as String;
      }

      // Generate new code
      final code = await _generateUniqueCode(userId);

      // Store the code
      await referralRef.set({
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'totalReferrals': 0,
        'totalRewardsEarned': 0,
      });

      // Also store in referral_codes collection for lookup
      await _firestore.collection('referral_codes').doc(code).set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      await _analytics.logEvent(
        name: 'referral_code_generated',
        parameters: {'user_id': userId, 'code': code},
      );

      debugPrint('✅ [Referral] Generated code: $code for user: $userId');
      return code;
    } catch (e) {
      debugPrint('❌ [Referral] Failed to generate code: $e');
      rethrow;
    }
  }

  /// Generate a unique alphanumeric code
  Future<String> _generateUniqueCode(String userId) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars
    final random = Random.secure();

    for (int attempt = 0; attempt < 10; attempt++) {
      // Generate 6-character code
      final code = List.generate(
        6,
        (index) => chars[random.nextInt(chars.length)],
      ).join();

      // Check if code exists
      final existing = await _firestore
          .collection('referral_codes')
          .doc(code)
          .get();

      if (!existing.exists) {
        return code;
      }
    }

    // Fallback: use user ID hash
    return userId.substring(0, 6).toUpperCase();
  }

  /// Get user's referral code
  Future<String?> getReferralCode(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referral')
          .doc('info')
          .get();

      return doc.data()?['code'] as String?;
    } catch (e) {
      debugPrint('❌ [Referral] Failed to get code: $e');
      return null;
    }
  }

  // ============================================================
  // REFERRAL CODE REDEMPTION
  // ============================================================

  /// Redeem a referral code
  /// Returns result indicating success/failure and rewards
  Future<ReferralRedemptionResult> redeemReferralCode(
    String newUserId,
    String code,
  ) async {
    try {
      // Lookup the code
      final codeDoc = await _firestore
          .collection('referral_codes')
          .doc(code.toUpperCase())
          .get();

      if (!codeDoc.exists) {
        return ReferralRedemptionResult(
          success: false,
          message: 'Invalid referral code',
        );
      }

      final codeData = codeDoc.data()!;
      final referrerId = codeData['userId'] as String;

      // Can't refer yourself
      if (referrerId == newUserId) {
        return ReferralRedemptionResult(
          success: false,
          message: 'You cannot use your own referral code',
        );
      }

      // Check if code is active
      if (codeData['isActive'] == false) {
        return ReferralRedemptionResult(
          success: false,
          message: 'This referral code is no longer active',
        );
      }

      // Check if user has already used a referral code
      final newUserRef = _firestore.collection('users').doc(newUserId);
      final newUserDoc = await newUserRef.get();

      if (newUserDoc.data()?['referredBy'] != null) {
        return ReferralRedemptionResult(
          success: false,
          message: 'You have already used a referral code',
        );
      }

      // Process the referral
      return await _firestore.runTransaction((transaction) async {
        // Get referrer data
        final referrerRef = _firestore.collection('users').doc(referrerId);
        final referrerDoc = await transaction.get(referrerRef);
        final referrerData = referrerDoc.data();

        if (referrerData == null) {
          return ReferralRedemptionResult(
            success: false,
            message: 'Referrer account not found',
          );
        }

        // Calculate rewards
        int referrerReward = referrerCoinReward;
        final referrerTier = referrerData['membershipTier'] ?? 'free';
        if (referrerTier == 'vip' || referrerTier == 'vip_plus') {
          referrerReward += vipReferrerBonusCoins;
        }

        // Update referrer
        transaction.update(referrerRef, {
          'coinBalance': FieldValue.increment(referrerReward),
        });

        // Update referrer's referral stats
        final referrerInfoRef = referrerRef.collection('referral').doc('info');
        transaction.set(referrerInfoRef, {
          'totalReferrals': FieldValue.increment(1),
          'totalRewardsEarned': FieldValue.increment(referrerReward),
          'lastReferralAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update new user
        transaction.update(newUserRef, {
          'referredBy': referrerId,
          'referralCode': code.toUpperCase(),
          'coinBalance': FieldValue.increment(refereeCoinReward),
        });

        // Log referral
        final referralLogRef = _firestore.collection('referral_logs').doc();
        transaction.set(referralLogRef, {
          'referrerId': referrerId,
          'refereeId': newUserId,
          'code': code.toUpperCase(),
          'referrerReward': referrerReward,
          'refereeReward': refereeCoinReward,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return ReferralRedemptionResult(
          success: true,
          message: 'Welcome! You received $refereeCoinReward coins!',
          referrerReward: referrerReward,
          refereeReward: refereeCoinReward,
          referrerId: referrerId,
        );
      });
    } catch (e) {
      debugPrint('❌ [Referral] Failed to redeem code: $e');
      return ReferralRedemptionResult(
        success: false,
        message: 'Failed to redeem referral code',
      );
    }
  }

  // ============================================================
  // REFERRAL TRACKING
  // ============================================================

  /// Track referral reward earned
  Future<void> trackReferralReward(
    String userId,
    int amount,
    String source,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'referral_reward_earned',
        parameters: {
          'user_id': userId,
          'amount': amount,
          'source': source,
        },
      );

      // Log transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('coin_transactions')
          .add({
        'type': 'earn',
        'source': 'referral',
        'amount': amount,
        'description': 'Referral reward: $source',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [Referral] Failed to track reward: $e');
    }
  }

  /// Get referral statistics for a user
  Future<ReferralStats> getReferralStats(String userId) async {
    try {
      final referralDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referral')
          .doc('info')
          .get();

      if (!referralDoc.exists) {
        return const ReferralStats();
      }

      final data = referralDoc.data()!;

      // Get list of referrals
      final referralsQuery = await _firestore
          .collection('referral_logs')
          .where('referrerId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final referrals = referralsQuery.docs.map((doc) {
        final d = doc.data();
        return ReferralRecord(
          refereeId: d['refereeId'],
          reward: d['referrerReward'],
          timestamp: (d['timestamp'] as Timestamp).toDate(),
        );
      }).toList();

      return ReferralStats(
        code: data['code'],
        totalReferrals: data['totalReferrals'] ?? 0,
        totalRewardsEarned: data['totalRewardsEarned'] ?? 0,
        referrals: referrals,
      );
    } catch (e) {
      debugPrint('❌ [Referral] Failed to get stats: $e');
      return const ReferralStats();
    }
  }

  /// Get referral link
  String getReferralLink(String code) {
    return 'https://mixmingle.app/ref/$code';
  }

  /// Check if user was referred
  Future<bool> wasUserReferred(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['referredBy'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Get referral leaderboard
  Future<List<ReferralLeaderboardEntry>> getReferralLeaderboard({
    int limit = 10,
  }) async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('referralCount', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return ReferralLeaderboardEntry(
          userId: doc.id,
          displayName: data['displayName'] ?? 'Anonymous',
          referralCount: data['referralCount'] ?? 0,
          photoUrl: data['photoUrl'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Referral] Failed to get leaderboard: $e');
      return [];
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class ReferralRedemptionResult {
  final bool success;
  final String message;
  final int? referrerReward;
  final int? refereeReward;
  final String? referrerId;

  const ReferralRedemptionResult({
    required this.success,
    required this.message,
    this.referrerReward,
    this.refereeReward,
    this.referrerId,
  });
}

class ReferralStats {
  final String? code;
  final int totalReferrals;
  final int totalRewardsEarned;
  final List<ReferralRecord> referrals;

  const ReferralStats({
    this.code,
    this.totalReferrals = 0,
    this.totalRewardsEarned = 0,
    this.referrals = const [],
  });
}

class ReferralRecord {
  final String refereeId;
  final int reward;
  final DateTime timestamp;

  const ReferralRecord({
    required this.refereeId,
    required this.reward,
    required this.timestamp,
  });
}

class ReferralLeaderboardEntry {
  final String userId;
  final String displayName;
  final int referralCount;
  final String? photoUrl;

  const ReferralLeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.referralCount,
    this.photoUrl,
  });
}
