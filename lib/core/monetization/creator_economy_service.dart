/// Creator Economy Service
///
/// Manages creator earnings, payouts, tier management, bonuses,
/// and retention incentives for the creator program.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';

/// Creator tier with associated benefits
class CreatorTierConfig {
  final String id;
  final String name;
  final int minFollowers;
  final int minMonthlyEarnings;
  final double revenueSharePercent;
  final List<String> benefits;
  final String badgeIcon;

  const CreatorTierConfig({
    required this.id,
    required this.name,
    required this.minFollowers,
    required this.minMonthlyEarnings,
    required this.revenueSharePercent,
    required this.benefits,
    required this.badgeIcon,
  });

  factory CreatorTierConfig.fromMap(Map<String, dynamic> map) {
    return CreatorTierConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      minFollowers: map['minFollowers'] as int,
      minMonthlyEarnings: map['minMonthlyEarnings'] as int,
      revenueSharePercent: (map['revenueSharePercent'] as num).toDouble(),
      benefits: List<String>.from(map['benefits'] ?? []),
      badgeIcon: map['badgeIcon'] as String? ?? '⭐',
    );
  }
}

/// Earning transaction record
class EarningRecord {
  final String id;
  final String creatorId;
  final EarningSource source;
  final double amount;
  final double platformFee;
  final double netAmount;
  final String? sourceId;
  final String? description;
  final DateTime timestamp;

  const EarningRecord({
    required this.id,
    required this.creatorId,
    required this.source,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    this.sourceId,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorId': creatorId,
    'source': source.name,
    'amount': amount,
    'platformFee': platformFee,
    'netAmount': netAmount,
    'sourceId': sourceId,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory EarningRecord.fromMap(Map<String, dynamic> map) {
    return EarningRecord(
      id: map['id'] as String,
      creatorId: map['creatorId'] as String,
      source: EarningSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => EarningSource.gift,
      ),
      amount: (map['amount'] as num).toDouble(),
      platformFee: (map['platformFee'] as num).toDouble(),
      netAmount: (map['netAmount'] as num).toDouble(),
      sourceId: map['sourceId'] as String?,
      description: map['description'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

enum EarningSource {
  gift,
  subscription,
  tip,
  badge,
  bundle,
  bonus,
  referral,
}

/// Payout request
class PayoutRequest {
  final String id;
  final String creatorId;
  final double amount;
  final PayoutMethod method;
  final PayoutStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? transactionId;
  final Map<String, dynamic> paymentDetails;

  const PayoutRequest({
    required this.id,
    required this.creatorId,
    required this.amount,
    required this.method,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.transactionId,
    this.paymentDetails = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorId': creatorId,
    'amount': amount,
    'method': method.name,
    'status': status.name,
    'requestedAt': requestedAt.toIso8601String(),
    'processedAt': processedAt?.toIso8601String(),
    'transactionId': transactionId,
    'paymentDetails': paymentDetails,
  };

  factory PayoutRequest.fromMap(Map<String, dynamic> map) {
    return PayoutRequest(
      id: map['id'] as String,
      creatorId: map['creatorId'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: PayoutMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PayoutMethod.bankTransfer,
      ),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PayoutStatus.pending,
      ),
      requestedAt: DateTime.parse(map['requestedAt'] as String),
      processedAt: map['processedAt'] != null
          ? DateTime.parse(map['processedAt'] as String)
          : null,
      transactionId: map['transactionId'] as String?,
      paymentDetails: Map<String, dynamic>.from(map['paymentDetails'] ?? {}),
    );
  }
}

enum PayoutMethod {
  bankTransfer,
  paypal,
  stripe,
  crypto,
}

enum PayoutStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Creator bonus
class CreatorBonus {
  final String id;
  final String creatorId;
  final BonusType type;
  final double amount;
  final String reason;
  final DateTime awardedAt;
  final bool isClaimed;

  const CreatorBonus({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.awardedAt,
    this.isClaimed = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorId': creatorId,
    'type': type.name,
    'amount': amount,
    'reason': reason,
    'awardedAt': awardedAt.toIso8601String(),
    'isClaimed': isClaimed,
  };
}

enum BonusType {
  engagement,
  milestone,
  retention,
  referral,
  seasonal,
  performance,
}

/// Service for managing creator economy
class CreatorEconomyService {
  static CreatorEconomyService? _instance;
  static CreatorEconomyService get instance => _instance ??= CreatorEconomyService._();

  CreatorEconomyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _creatorsCollection =>
      _firestore.collection('creators');

  CollectionReference<Map<String, dynamic>> get _earningsCollection =>
      _firestore.collection('creator_earnings');

  CollectionReference<Map<String, dynamic>> get _payoutsCollection =>
      _firestore.collection('creator_payouts');

  CollectionReference<Map<String, dynamic>> get _bonusesCollection =>
      _firestore.collection('creator_bonuses');

  // Tier configurations
  final List<CreatorTierConfig> _tierConfigs = [
    const CreatorTierConfig(
      id: 'starter',
      name: 'Starter',
      minFollowers: 0,
      minMonthlyEarnings: 0,
      revenueSharePercent: 0.70,
      benefits: ['Basic analytics', 'Standard support'],
      badgeIcon: '🌱',
    ),
    const CreatorTierConfig(
      id: 'rising',
      name: 'Rising Star',
      minFollowers: 100,
      minMonthlyEarnings: 50,
      revenueSharePercent: 0.75,
      benefits: ['Enhanced analytics', 'Priority support', 'Custom room themes'],
      badgeIcon: '⭐',
    ),
    const CreatorTierConfig(
      id: 'established',
      name: 'Established',
      minFollowers: 1000,
      minMonthlyEarnings: 200,
      revenueSharePercent: 0.80,
      benefits: ['Full analytics dashboard', 'Dedicated support', 'Featured placement'],
      badgeIcon: '🌟',
    ),
    const CreatorTierConfig(
      id: 'partner',
      name: 'Partner',
      minFollowers: 10000,
      minMonthlyEarnings: 1000,
      revenueSharePercent: 0.85,
      benefits: ['All benefits', 'Revenue optimization', 'Brand partnerships'],
      badgeIcon: '👑',
    ),
  ];

  // Stream controllers
  final _earningsController = StreamController<EarningRecord>.broadcast();
  final _tierChangeController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of new earnings
  Stream<EarningRecord> get earningsStream => _earningsController.stream;

  /// Stream of tier changes
  Stream<Map<String, dynamic>> get tierChangeStream => _tierChangeController.stream;

  /// Get tier configurations
  List<CreatorTierConfig> get tierConfigs => List.unmodifiable(_tierConfigs);

  /// Initialize the service
  Future<void> initialize() async {
    AnalyticsService.instance.logEvent(
      name: 'creator_economy_initialized',
      parameters: {},
    );
  }

  /// Track creator earnings
  Future<EarningRecord> trackCreatorEarnings({
    required String creatorId,
    required EarningSource source,
    required double amount,
    String? sourceId,
    String? description,
  }) async {
    // Get creator's tier for revenue share calculation
    final creatorDoc = await _creatorsCollection.doc(creatorId).get();
    final tierId = creatorDoc.data()?['tier'] as String? ?? 'starter';
    final tierConfig = _tierConfigs.firstWhere(
      (t) => t.id == tierId,
      orElse: () => _tierConfigs.first,
    );

    final platformFee = amount * (1 - tierConfig.revenueSharePercent);
    final netAmount = amount - platformFee;

    final docRef = _earningsCollection.doc();
    final earning = EarningRecord(
      id: docRef.id,
      creatorId: creatorId,
      source: source,
      amount: amount,
      platformFee: platformFee,
      netAmount: netAmount,
      sourceId: sourceId,
      description: description,
      timestamp: DateTime.now(),
    );

    await docRef.set(earning.toMap());

    // Update creator's balance
    await _creatorsCollection.doc(creatorId).update({
      'pendingBalance': FieldValue.increment(netAmount),
      'totalEarnings': FieldValue.increment(netAmount),
      'monthlyEarnings': FieldValue.increment(netAmount),
      'lastEarningAt': FieldValue.serverTimestamp(),
    });

    _earningsController.add(earning);

    AnalyticsService.instance.logEvent(
      name: 'creator_earning_tracked',
      parameters: {
        'creator_id': creatorId,
        'source': source.name,
        'amount': amount,
        'net_amount': netAmount,
      },
    );

    return earning;
  }

  /// Calculate and process payouts
  Future<PayoutRequest?> calculatePayouts({
    required String creatorId,
    required PayoutMethod method,
    Map<String, dynamic> paymentDetails = const {},
    double? customAmount,
  }) async {
    // Get creator's balance
    final creatorDoc = await _creatorsCollection.doc(creatorId).get();
    if (!creatorDoc.exists) return null;

    final creatorData = creatorDoc.data()!;
    final pendingBalance = (creatorData['pendingBalance'] as num?)?.toDouble() ?? 0;

    // Check minimum payout threshold
    const minPayout = 10.0;
    final payoutAmount = customAmount ?? pendingBalance;

    if (payoutAmount < minPayout) {
      return null; // Below minimum
    }

    if (payoutAmount > pendingBalance) {
      return null; // Insufficient balance
    }

    // Create payout request
    final docRef = _payoutsCollection.doc();
    final payout = PayoutRequest(
      id: docRef.id,
      creatorId: creatorId,
      amount: payoutAmount,
      method: method,
      status: PayoutStatus.pending,
      requestedAt: DateTime.now(),
      paymentDetails: paymentDetails,
    );

    await docRef.set(payout.toMap());

    // Deduct from pending balance
    await _creatorsCollection.doc(creatorId).update({
      'pendingBalance': FieldValue.increment(-payoutAmount),
    });

    AnalyticsService.instance.logEvent(
      name: 'payout_requested',
      parameters: {
        'creator_id': creatorId,
        'amount': payoutAmount,
        'method': method.name,
      },
    );

    return payout;
  }

  /// Manage creator tiers
  Future<Map<String, dynamic>> manageCreatorTiers({
    required String creatorId,
    bool autoUpgrade = true,
  }) async {
    final creatorDoc = await _creatorsCollection.doc(creatorId).get();
    if (!creatorDoc.exists) return {'success': false, 'error': 'Creator not found'};

    final creatorData = creatorDoc.data()!;
    final currentTierId = creatorData['tier'] as String? ?? 'starter';
    final followers = (creatorData['followerCount'] as int?) ?? 0;
    final monthlyEarnings = (creatorData['monthlyEarnings'] as num?)?.toDouble() ?? 0;

    // Find eligible tier
    CreatorTierConfig? eligibleTier;
    for (final tier in _tierConfigs.reversed) {
      if (followers >= tier.minFollowers && monthlyEarnings >= tier.minMonthlyEarnings) {
        eligibleTier = tier;
        break;
      }
    }

    eligibleTier ??= _tierConfigs.first;

    if (eligibleTier.id == currentTierId) {
      return {
        'success': true,
        'changed': false,
        'currentTier': currentTierId,
      };
    }

    // Check if this is an upgrade or downgrade
    final currentTierIndex = _tierConfigs.indexWhere((t) => t.id == currentTierId);
    final newTierIndex = _tierConfigs.indexWhere((t) => t.id == eligibleTier!.id);
    final isUpgrade = newTierIndex > currentTierIndex;

    // Only auto-upgrade, not downgrade (downgrades should be manual)
    if (!autoUpgrade && !isUpgrade) {
      return {
        'success': true,
        'changed': false,
        'currentTier': currentTierId,
        'pendingDowngrade': eligibleTier.id,
      };
    }

    // Apply tier change
    await _creatorsCollection.doc(creatorId).update({
      'tier': eligibleTier.id,
      'tierChangedAt': FieldValue.serverTimestamp(),
      'previousTier': currentTierId,
    });

    _tierChangeController.add({
      'creatorId': creatorId,
      'oldTier': currentTierId,
      'newTier': eligibleTier.id,
      'isUpgrade': isUpgrade,
    });

    // Award tier change bonus if upgrade
    if (isUpgrade) {
      await creatorBonusesForEngagement(
        creatorId: creatorId,
        bonusType: BonusType.milestone,
        amount: 50.0 * (newTierIndex + 1),
        reason: 'Tier upgrade to ${eligibleTier.name}',
      );
    }

    AnalyticsService.instance.logEvent(
      name: 'creator_tier_changed',
      parameters: {
        'creator_id': creatorId,
        'old_tier': currentTierId,
        'new_tier': eligibleTier.id,
        'is_upgrade': isUpgrade,
      },
    );

    return {
      'success': true,
      'changed': true,
      'oldTier': currentTierId,
      'newTier': eligibleTier.id,
      'isUpgrade': isUpgrade,
    };
  }

  /// Award creator bonuses for engagement
  Future<CreatorBonus> creatorBonusesForEngagement({
    required String creatorId,
    required BonusType bonusType,
    required double amount,
    required String reason,
  }) async {
    final docRef = _bonusesCollection.doc();
    final bonus = CreatorBonus(
      id: docRef.id,
      creatorId: creatorId,
      type: bonusType,
      amount: amount,
      reason: reason,
      awardedAt: DateTime.now(),
    );

    await docRef.set(bonus.toMap());

    // Add to creator's bonus balance
    await _creatorsCollection.doc(creatorId).update({
      'pendingBonuses': FieldValue.increment(amount),
      'totalBonuses': FieldValue.increment(amount),
    });

    AnalyticsService.instance.logEvent(
      name: 'creator_bonus_awarded',
      parameters: {
        'creator_id': creatorId,
        'bonus_type': bonusType.name,
        'amount': amount,
      },
    );

    return bonus;
  }

  /// Creator retention incentives
  Future<Map<String, dynamic>> creatorRetentionIncentives({
    required String creatorId,
  }) async {
    final creatorDoc = await _creatorsCollection.doc(creatorId).get();
    if (!creatorDoc.exists) return {'success': false};

    final creatorData = creatorDoc.data()!;
    final incentives = <String, dynamic>{};

    // Check for inactivity
    final lastActive = creatorData['lastActive'] != null
        ? (creatorData['lastActive'] as Timestamp).toDate()
        : null;

    if (lastActive != null) {
      final daysSinceActive = DateTime.now().difference(lastActive).inDays;

      if (daysSinceActive >= 7 && daysSinceActive < 14) {
        // First warning - small incentive
        incentives['retentionBonus'] = 20.0;
        incentives['message'] = 'We miss you! Collect your loyalty bonus.';
      } else if (daysSinceActive >= 14 && daysSinceActive < 30) {
        // Second warning - larger incentive
        incentives['retentionBonus'] = 50.0;
        incentives['message'] = 'Your fans are waiting! Here\'s a special bonus.';
      } else if (daysSinceActive >= 30) {
        // Critical - significant incentive
        incentives['retentionBonus'] = 100.0;
        incentives['boostDays'] = 3;
        incentives['message'] = 'Welcome back offer: Bonus + 3 days of free boosts!';
      }
    }

    // Check for declining engagement
    final previousMonthEarnings = (creatorData['previousMonthEarnings'] as num?)?.toDouble() ?? 0;
    final monthlyEarnings = (creatorData['monthlyEarnings'] as num?)?.toDouble() ?? 0;

    if (previousMonthEarnings > 0 && monthlyEarnings < previousMonthEarnings * 0.5) {
      // Declining earnings - support bonus
      incentives['supportBonus'] = previousMonthEarnings * 0.1;
      incentives['message'] = (incentives['message'] ?? '') +
          ' Plus a support bonus to help you grow!';
    }

    // Apply incentives if any
    if (incentives.containsKey('retentionBonus')) {
      await creatorBonusesForEngagement(
        creatorId: creatorId,
        bonusType: BonusType.retention,
        amount: incentives['retentionBonus'] as double,
        reason: 'Creator retention incentive',
      );
    }

    if (incentives.containsKey('supportBonus')) {
      await creatorBonusesForEngagement(
        creatorId: creatorId,
        bonusType: BonusType.performance,
        amount: incentives['supportBonus'] as double,
        reason: 'Earnings support bonus',
      );
    }

    AnalyticsService.instance.logEvent(
      name: 'retention_incentive_applied',
      parameters: {
        'creator_id': creatorId,
        'has_incentives': incentives.isNotEmpty,
      },
    );

    return {
      'success': true,
      'incentives': incentives,
    };
  }

  /// Get creator earnings summary
  Future<Map<String, dynamic>> getCreatorEarningsSummary({
    required String creatorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final earningsSnapshot = await _earningsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
        .get();

    double totalEarnings = 0;
    double totalNetEarnings = 0;
    final earningsBySource = <String, double>{};

    for (final doc in earningsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final netAmount = (data['netAmount'] as num).toDouble();
      final source = data['source'] as String;

      totalEarnings += amount;
      totalNetEarnings += netAmount;
      earningsBySource[source] = (earningsBySource[source] ?? 0) + netAmount;
    }

    // Get payout history
    final payoutsSnapshot = await _payoutsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: PayoutStatus.completed.name)
        .where('requestedAt', isGreaterThanOrEqualTo: start.toIso8601String())
        .get();

    double totalPaidOut = 0;
    for (final doc in payoutsSnapshot.docs) {
      totalPaidOut += (doc.data()['amount'] as num).toDouble();
    }

    return {
      'period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
      'totalEarnings': totalEarnings,
      'totalNetEarnings': totalNetEarnings,
      'totalPaidOut': totalPaidOut,
      'earningsBySource': earningsBySource,
      'transactionCount': earningsSnapshot.docs.length,
    };
  }

  /// Get pending bonuses for a creator
  Future<List<CreatorBonus>> getPendingBonuses(String creatorId) async {
    final snapshot = await _bonusesCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('isClaimed', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CreatorBonus(
        id: data['id'] as String,
        creatorId: data['creatorId'] as String,
        type: BonusType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => BonusType.engagement,
        ),
        amount: (data['amount'] as num).toDouble(),
        reason: data['reason'] as String,
        awardedAt: DateTime.parse(data['awardedAt'] as String),
        isClaimed: data['isClaimed'] as bool? ?? false,
      );
    }).toList();
  }

  /// Claim a bonus
  Future<bool> claimBonus(String bonusId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final bonusDoc = await _bonusesCollection.doc(bonusId).get();
    if (!bonusDoc.exists) return false;

    final bonusData = bonusDoc.data()!;
    if (bonusData['creatorId'] != userId) return false;
    if (bonusData['isClaimed'] == true) return false;

    final amount = (bonusData['amount'] as num).toDouble();

    // Transfer bonus to pending balance
    await _creatorsCollection.doc(userId).update({
      'pendingBalance': FieldValue.increment(amount),
      'pendingBonuses': FieldValue.increment(-amount),
    });

    // Mark bonus as claimed
    await _bonusesCollection.doc(bonusId).update({
      'isClaimed': true,
      'claimedAt': FieldValue.serverTimestamp(),
    });

    AnalyticsService.instance.logEvent(
      name: 'bonus_claimed',
      parameters: {
        'bonus_id': bonusId,
        'amount': amount,
      },
    );

    return true;
  }

  /// Dispose resources
  void dispose() {
    _earningsController.close();
    _tierChangeController.close();
  }
}
