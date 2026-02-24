/// Partner Program Service
///
/// Manages partner registration, tier assignment, revenue sharing,
/// and analytics for the partner program.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';

/// Partner registration
class Partner {
  final String id;
  final String userId;
  final String name;
  final String email;
  final PartnerType type;
  final PartnerTier tier;
  final PartnerStatus status;
  final String? companyName;
  final String? website;
  final String? referralCode;
  final int referralCount;
  final double lifetimeEarnings;
  final Map<String, dynamic> metadata;
  final DateTime registeredAt;
  final DateTime? verifiedAt;

  const Partner({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.type,
    required this.tier,
    required this.status,
    this.companyName,
    this.website,
    this.referralCode,
    this.referralCount = 0,
    this.lifetimeEarnings = 0,
    this.metadata = const {},
    required this.registeredAt,
    this.verifiedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'email': email,
        'type': type.name,
        'tier': tier.name,
        'status': status.name,
        'companyName': companyName,
        'website': website,
        'referralCode': referralCode,
        'referralCount': referralCount,
        'lifetimeEarnings': lifetimeEarnings,
        'metadata': metadata,
        'registeredAt': registeredAt.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
      };

  factory Partner.fromMap(Map<String, dynamic> map) => Partner(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        type: PartnerType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => PartnerType.affiliate,
        ),
        tier: PartnerTier.values.firstWhere(
          (t) => t.name == map['tier'],
          orElse: () => PartnerTier.bronze,
        ),
        status: PartnerStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => PartnerStatus.pending,
        ),
        companyName: map['companyName'] as String?,
        website: map['website'] as String?,
        referralCode: map['referralCode'] as String?,
        referralCount: map['referralCount'] as int? ?? 0,
        lifetimeEarnings: (map['lifetimeEarnings'] as num?)?.toDouble() ?? 0,
        metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
        registeredAt: DateTime.parse(map['registeredAt'] as String),
        verifiedAt: map['verifiedAt'] != null
            ? DateTime.parse(map['verifiedAt'] as String)
            : null,
      );

  Partner copyWith({
    PartnerTier? tier,
    PartnerStatus? status,
    int? referralCount,
    double? lifetimeEarnings,
    DateTime? verifiedAt,
  }) =>
      Partner(
        id: id,
        userId: userId,
        name: name,
        email: email,
        type: type,
        tier: tier ?? this.tier,
        status: status ?? this.status,
        companyName: companyName,
        website: website,
        referralCode: referralCode,
        referralCount: referralCount ?? this.referralCount,
        lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
        metadata: metadata,
        registeredAt: registeredAt,
        verifiedAt: verifiedAt ?? this.verifiedAt,
      );
}

enum PartnerType {
  affiliate,
  reseller,
  integrator,
  agency,
  ambassador,
}

enum PartnerTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

enum PartnerStatus {
  pending,
  active,
  suspended,
  terminated,
}

/// Revenue share configuration
class RevenueShare {
  final String partnerId;
  final PartnerTier tier;
  final double basePercentage;
  final double bonusPercentage;
  final double totalPercentage;
  final List<RevenueBonus> activeBonuses;
  final DateTime calculatedAt;

  const RevenueShare({
    required this.partnerId,
    required this.tier,
    required this.basePercentage,
    this.bonusPercentage = 0,
    required this.totalPercentage,
    this.activeBonuses = const [],
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() => {
        'partnerId': partnerId,
        'tier': tier.name,
        'basePercentage': basePercentage,
        'bonusPercentage': bonusPercentage,
        'totalPercentage': totalPercentage,
        'activeBonuses': activeBonuses.map((b) => b.toMap()).toList(),
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}

class RevenueBonus {
  final String id;
  final String name;
  final double percentage;
  final DateTime expiresAt;

  const RevenueBonus({
    required this.id,
    required this.name,
    required this.percentage,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'percentage': percentage,
        'expiresAt': expiresAt.toIso8601String(),
      };
}

/// Partner payout record
class PartnerPayout {
  final String id;
  final String partnerId;
  final double amount;
  final String currency;
  final PayoutStatus status;
  final PayoutMethod method;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? processedAt;

  const PartnerPayout({
    required this.id,
    required this.partnerId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.method,
    this.transactionId,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'partnerId': partnerId,
        'amount': amount,
        'currency': currency,
        'status': status.name,
        'method': method.name,
        'transactionId': transactionId,
        'createdAt': createdAt.toIso8601String(),
        'processedAt': processedAt?.toIso8601String(),
      };
}

enum PayoutStatus {
  pending,
  processing,
  completed,
  failed,
  canceled,
}

enum PayoutMethod {
  bankTransfer,
  paypal,
  stripe,
  crypto,
}

/// Partner analytics
class PartnerAnalytics {
  final String partnerId;
  final int totalReferrals;
  final int activeReferrals;
  final int conversions;
  final double conversionRate;
  final double totalRevenue;
  final double totalCommissions;
  final double pendingCommissions;
  final Map<String, int> referralsByMonth;
  final Map<String, double> revenueByMonth;
  final DateTime periodStart;
  final DateTime periodEnd;

  const PartnerAnalytics({
    required this.partnerId,
    required this.totalReferrals,
    required this.activeReferrals,
    required this.conversions,
    required this.conversionRate,
    required this.totalRevenue,
    required this.totalCommissions,
    required this.pendingCommissions,
    this.referralsByMonth = const {},
    this.revenueByMonth = const {},
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toMap() => {
        'partnerId': partnerId,
        'totalReferrals': totalReferrals,
        'activeReferrals': activeReferrals,
        'conversions': conversions,
        'conversionRate': conversionRate,
        'totalRevenue': totalRevenue,
        'totalCommissions': totalCommissions,
        'pendingCommissions': pendingCommissions,
        'referralsByMonth': referralsByMonth,
        'revenueByMonth': revenueByMonth,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };
}

/// Referral record
class Referral {
  final String id;
  final String partnerId;
  final String referredUserId;
  final String? referralCode;
  final ReferralStatus status;
  final double? revenue;
  final double? commission;
  final DateTime createdAt;
  final DateTime? convertedAt;

  const Referral({
    required this.id,
    required this.partnerId,
    required this.referredUserId,
    this.referralCode,
    required this.status,
    this.revenue,
    this.commission,
    required this.createdAt,
    this.convertedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'partnerId': partnerId,
        'referredUserId': referredUserId,
        'referralCode': referralCode,
        'status': status.name,
        'revenue': revenue,
        'commission': commission,
        'createdAt': createdAt.toIso8601String(),
        'convertedAt': convertedAt?.toIso8601String(),
      };
}

enum ReferralStatus {
  pending,
  active,
  converted,
  churned,
}

/// Partner Program Service
class PartnerProgramService {
  static PartnerProgramService? _instance;
  static PartnerProgramService get instance =>
      _instance ??= PartnerProgramService._();

  PartnerProgramService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _partnerController = StreamController<Partner>.broadcast();
  final _payoutController = StreamController<PartnerPayout>.broadcast();

  Stream<Partner> get partnerStream => _partnerController.stream;
  Stream<PartnerPayout> get payoutStream => _payoutController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _partnersCollection =>
      _firestore.collection('partners');

  CollectionReference<Map<String, dynamic>> get _referralsCollection =>
      _firestore.collection('referrals');

  CollectionReference<Map<String, dynamic>> get _payoutsCollection =>
      _firestore.collection('partner_payouts');

  // ============================================================
  // REGISTER PARTNER
  // ============================================================

  /// Register a new partner
  Future<Partner> registerPartner({
    required String userId,
    required String name,
    required String email,
    required PartnerType type,
    String? companyName,
    String? website,
  }) async {
    debugPrint('ðŸ¤ [PartnerProgram] Registering partner: $name');

    try {
      final id = 'partner_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final referralCode = _generateReferralCode(name);

      final partner = Partner(
        id: id,
        userId: userId,
        name: name,
        email: email,
        type: type,
        tier: PartnerTier.bronze,
        status: PartnerStatus.pending,
        companyName: companyName,
        website: website,
        referralCode: referralCode,
        registeredAt: DateTime.now(),
      );

      await _partnersCollection.doc(id).set(partner.toMap());

      _partnerController.add(partner);

      AnalyticsService.instance.logEvent(
        name: 'partner_registered',
        parameters: {
          'type': type.name,
        },
      );

      debugPrint('âœ… [PartnerProgram] Partner registered: $id');
      return partner;
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to register partner: $e');
      rethrow;
    }
  }

  String _generateReferralCode(String name) {
    final prefix = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final suffix = _random.nextInt(9999).toString().padLeft(4, '0');
    return '$prefix$suffix';
  }

  /// Verify partner (admin action)
  Future<Partner> verifyPartner(String partnerId) async {
    final doc = await _partnersCollection.doc(partnerId).get();
    if (!doc.exists) throw Exception('Partner not found');

    final partner = Partner.fromMap(doc.data()!);
    final verifiedPartner = partner.copyWith(
      status: PartnerStatus.active,
      verifiedAt: DateTime.now(),
    );

    await _partnersCollection.doc(partnerId).update({
      'status': PartnerStatus.active.name,
      'verifiedAt': DateTime.now().toIso8601String(),
    });

    _partnerController.add(verifiedPartner);
    return verifiedPartner;
  }

  /// Get partner by ID
  Future<Partner?> getPartner(String partnerId) async {
    final doc = await _partnersCollection.doc(partnerId).get();
    if (!doc.exists) return null;
    return Partner.fromMap(doc.data()!);
  }

  /// Get partner by user ID
  Future<Partner?> getPartnerByUserId(String userId) async {
    final snapshot = await _partnersCollection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Partner.fromMap(snapshot.docs.first.data());
  }

  /// Get partner by referral code
  Future<Partner?> getPartnerByReferralCode(String code) async {
    final snapshot = await _partnersCollection
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Partner.fromMap(snapshot.docs.first.data());
  }

  // ============================================================
  // ASSIGN PARTNER TIER
  // ============================================================

  /// Assign or update partner tier
  Future<Partner> assignPartnerTier(
    String partnerId, {
    required PartnerTier tier,
    String? reason,
  }) async {
    debugPrint('â¬†ï¸ [PartnerProgram] Assigning tier: ${tier.name} to $partnerId');

    try {
      final doc = await _partnersCollection.doc(partnerId).get();
      if (!doc.exists) throw Exception('Partner not found');

      final partner = Partner.fromMap(doc.data()!);
      final oldTier = partner.tier;

      final updatedPartner = partner.copyWith(tier: tier);

      await _partnersCollection.doc(partnerId).update({
        'tier': tier.name,
        'tierUpdatedAt': DateTime.now().toIso8601String(),
        'tierUpdateReason': reason,
      });

      _partnerController.add(updatedPartner);

      // Log tier change
      if (oldTier.index < tier.index) {
        AnalyticsService.instance.logEvent(
          name: 'partner_tier_upgraded',
          parameters: {
            'old_tier': oldTier.name,
            'new_tier': tier.name,
          },
        );
      }

      debugPrint('âœ… [PartnerProgram] Partner tier updated: ${tier.name}');
      return updatedPartner;
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to assign tier: $e');
      rethrow;
    }
  }

  /// Check and auto-upgrade tier based on performance
  Future<void> evaluateTierUpgrade(String partnerId) async {
    final partner = await getPartner(partnerId);
    if (partner == null) return;

    final analytics = await partnerAnalytics(partnerId);

    // Tier thresholds based on referrals and revenue
    final newTier = _calculateTier(
      referrals: analytics.totalReferrals,
      revenue: analytics.totalRevenue,
    );

    if (newTier.index > partner.tier.index) {
      await assignPartnerTier(
        partnerId,
        tier: newTier,
        reason: 'Auto-upgrade based on performance',
      );
    }
  }

  PartnerTier _calculateTier({
    required int referrals,
    required double revenue,
  }) {
    // Diamond: 1000+ referrals OR $100k+ revenue
    if (referrals >= 1000 || revenue >= 100000) {
      return PartnerTier.diamond;
    }
    // Platinum: 500+ referrals OR $50k+ revenue
    if (referrals >= 500 || revenue >= 50000) {
      return PartnerTier.platinum;
    }
    // Gold: 100+ referrals OR $10k+ revenue
    if (referrals >= 100 || revenue >= 10000) {
      return PartnerTier.gold;
    }
    // Silver: 25+ referrals OR $2.5k+ revenue
    if (referrals >= 25 || revenue >= 2500) {
      return PartnerTier.silver;
    }
    // Bronze: default
    return PartnerTier.bronze;
  }

  // ============================================================
  // PARTNER REVENUE SHARE
  // ============================================================

  /// Calculate partner revenue share
  Future<RevenueShare> partnerRevenueShare(String partnerId) async {
    debugPrint('ðŸ’° [PartnerProgram] Calculating revenue share: $partnerId');

    try {
      final partner = await getPartner(partnerId);
      if (partner == null) throw Exception('Partner not found');

      // Base percentage by tier
      final basePercentage = _getBasePercentage(partner.tier);

      // Get active bonuses
      final bonuses = await _getActiveBonuses(partnerId);
      final bonusPercentage = bonuses.fold<double>(
        0,
        (total, bonus) => total + bonus.percentage,
      );

      final revenueShare = RevenueShare(
        partnerId: partnerId,
        tier: partner.tier,
        basePercentage: basePercentage,
        bonusPercentage: bonusPercentage,
        totalPercentage: basePercentage + bonusPercentage,
        activeBonuses: bonuses,
        calculatedAt: DateTime.now(),
      );

      debugPrint('âœ… [PartnerProgram] Revenue share: ${revenueShare.totalPercentage}%');
      return revenueShare;
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to calculate revenue share: $e');
      rethrow;
    }
  }

  double _getBasePercentage(PartnerTier tier) => switch (tier) {
        PartnerTier.bronze => 10.0,
        PartnerTier.silver => 15.0,
        PartnerTier.gold => 20.0,
        PartnerTier.platinum => 25.0,
        PartnerTier.diamond => 30.0,
      };

  Future<List<RevenueBonus>> _getActiveBonuses(String partnerId) async {
    // In production, fetch from database
    // For now, return empty list
    return [];
  }

  /// Add a bonus to partner
  Future<void> addRevenueBonus({
    required String partnerId,
    required String name,
    required double percentage,
    required Duration duration,
  }) async {
    final bonusId = 'bonus_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final expiresAt = DateTime.now().add(duration);

    await _partnersCollection.doc(partnerId).collection('bonuses').doc(bonusId).set({
      'id': bonusId,
      'name': name,
      'percentage': percentage,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    });

    AnalyticsService.instance.logEvent(
      name: 'partner_bonus_added',
      parameters: {
        'partner_id': partnerId,
        'bonus_name': name,
        'percentage': percentage,
      },
    );
  }

  // ============================================================
  // PARTNER ANALYTICS
  // ============================================================

  /// Get partner analytics
  Future<PartnerAnalytics> partnerAnalytics(
    String partnerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('ðŸ“Š [PartnerProgram] Fetching partner analytics: $partnerId');

    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    try {
      final partner = await getPartner(partnerId);
      if (partner == null) throw Exception('Partner not found');

      // Fetch referrals
      final referralsSnapshot = await _referralsCollection
          .where('partnerId', isEqualTo: partnerId)
          .get();

      final referrals = referralsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Referral(
          id: data['id'] as String,
          partnerId: data['partnerId'] as String,
          referredUserId: data['referredUserId'] as String,
          referralCode: data['referralCode'] as String?,
          status: ReferralStatus.values.firstWhere(
            (s) => s.name == data['status'],
          ),
          revenue: (data['revenue'] as num?)?.toDouble(),
          commission: (data['commission'] as num?)?.toDouble(),
          createdAt: DateTime.parse(data['createdAt'] as String),
          convertedAt: data['convertedAt'] != null
              ? DateTime.parse(data['convertedAt'] as String)
              : null,
        );
      }).toList();

      // Calculate stats
      final totalReferrals = referrals.length;
      final activeReferrals = referrals.where((r) => r.status == ReferralStatus.active || r.status == ReferralStatus.converted).length;
      final conversions = referrals.where((r) => r.status == ReferralStatus.converted).length;
      final conversionRate = totalReferrals > 0 ? (conversions / totalReferrals * 100) : 0;

      final totalRevenue = referrals.fold<double>(
        0,
        (total, r) => total + (r.revenue ?? 0),
      );

      final totalCommissions = referrals.fold<double>(
        0,
        (total, r) => total + (r.commission ?? 0),
      );

      // Pending commissions from payouts
      final pendingPayouts = await _payoutsCollection
          .where('partnerId', isEqualTo: partnerId)
          .where('status', isEqualTo: PayoutStatus.pending.name)
          .get();

      final pendingCommissions = pendingPayouts.docs.fold<double>(
        0,
        (total, doc) => total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
      );

      final analytics = PartnerAnalytics(
        partnerId: partnerId,
        totalReferrals: totalReferrals,
        activeReferrals: activeReferrals,
        conversions: conversions,
        conversionRate: conversionRate.toDouble(),
        totalRevenue: totalRevenue,
        totalCommissions: totalCommissions,
        pendingCommissions: pendingCommissions,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      debugPrint('âœ… [PartnerProgram] Analytics fetched');
      return analytics;
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to fetch analytics: $e');
      rethrow;
    }
  }

  // ============================================================
  // REFERRAL TRACKING
  // ============================================================

  /// Record a referral
  Future<Referral> recordReferral({
    required String partnerId,
    required String referredUserId,
    String? referralCode,
  }) async {
    debugPrint('ðŸ“ [PartnerProgram] Recording referral');

    try {
      final id = 'ref_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final referral = Referral(
        id: id,
        partnerId: partnerId,
        referredUserId: referredUserId,
        referralCode: referralCode,
        status: ReferralStatus.pending,
        createdAt: DateTime.now(),
      );

      await _referralsCollection.doc(id).set(referral.toMap());

      // Increment partner referral count
      await _partnersCollection.doc(partnerId).update({
        'referralCount': FieldValue.increment(1),
      });

      return referral;
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to record referral: $e');
      rethrow;
    }
  }

  /// Convert a referral (when user makes a purchase)
  Future<void> convertReferral({
    required String referralId,
    required double revenue,
  }) async {
    try {
      final doc = await _referralsCollection.doc(referralId).get();
      if (!doc.exists) throw Exception('Referral not found');

      final data = doc.data()!;
      final partnerId = data['partnerId'] as String;

      // Get revenue share
      final revenueShare = await partnerRevenueShare(partnerId);
      final commission = revenue * (revenueShare.totalPercentage / 100);

      await _referralsCollection.doc(referralId).update({
        'status': ReferralStatus.converted.name,
        'revenue': revenue,
        'commission': commission,
        'convertedAt': DateTime.now().toIso8601String(),
      });

      // Update partner earnings
      await _partnersCollection.doc(partnerId).update({
        'lifetimeEarnings': FieldValue.increment(commission),
      });

      AnalyticsService.instance.logEvent(
        name: 'referral_converted',
        parameters: {
          'partner_id': partnerId,
          'revenue': revenue,
          'commission': commission,
        },
      );
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to convert referral: $e');
      rethrow;
    }
  }

  // ============================================================
  // PAYOUTS
  // ============================================================

  /// Request a payout
  Future<PartnerPayout> requestPayout({
    required String partnerId,
    required double amount,
    required PayoutMethod method,
  }) async {
    debugPrint('ðŸ’¸ [PartnerProgram] Requesting payout: \$$amount');

    try {
      final partner = await getPartner(partnerId);
      if (partner == null) throw Exception('Partner not found');

      final id = 'payout_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final payout = PartnerPayout(
        id: id,
        partnerId: partnerId,
        amount: amount,
        status: PayoutStatus.pending,
        method: method,
        createdAt: DateTime.now(),
      );

      await _payoutsCollection.doc(id).set(payout.toMap());

      _payoutController.add(payout);

      return payout;
    } catch (e) {
      debugPrint('âŒ [PartnerProgram] Failed to request payout: $e');
      rethrow;
    }
  }

  /// Get partner payouts
  Future<List<PartnerPayout>> getPartnerPayouts(
    String partnerId, {
    int limit = 20,
  }) async {
    final snapshot = await _payoutsCollection
        .where('partnerId', isEqualTo: partnerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return PartnerPayout(
        id: data['id'] as String,
        partnerId: data['partnerId'] as String,
        amount: (data['amount'] as num).toDouble(),
        currency: data['currency'] as String? ?? 'USD',
        status: PayoutStatus.values.firstWhere(
          (s) => s.name == data['status'],
        ),
        method: PayoutMethod.values.firstWhere(
          (m) => m.name == data['method'],
        ),
        transactionId: data['transactionId'] as String?,
        createdAt: DateTime.parse(data['createdAt'] as String),
        processedAt: data['processedAt'] != null
            ? DateTime.parse(data['processedAt'] as String)
            : null,
      );
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    _partnerController.close();
    _payoutController.close();
  }
}
