/// Creator Program Service
///
/// Manages the creator program including applications, tiers,
/// earnings, analytics, and dashboard functionality.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';

/// Creator tier levels
enum CreatorTier {
  applicant,
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Creator application status
enum CreatorApplicationStatus {
  pending,
  underReview,
  approved,
  rejected,
  waitlisted,
}

/// Types of creator earnings
enum EarningType {
  giftRevenue,
  subscriptionShare,
  sponsorship,
  referralBonus,
  eventPrize,
  milestone,
  bonus,
}

/// Creator program requirements by tier
class TierRequirements {
  final CreatorTier tier;
  final int minFollowers;
  final int minWeeklyStreamHours;
  final double minEngagementRate;
  final int minMonthlyViews;
  final double revenueSharePercent;
  final List<String> perks;

  const TierRequirements({
    required this.tier,
    required this.minFollowers,
    required this.minWeeklyStreamHours,
    required this.minEngagementRate,
    required this.minMonthlyViews,
    required this.revenueSharePercent,
    required this.perks,
  });

  static const Map<CreatorTier, TierRequirements> requirements = {
    CreatorTier.bronze: TierRequirements(
      tier: CreatorTier.bronze,
      minFollowers: 100,
      minWeeklyStreamHours: 5,
      minEngagementRate: 0.02,
      minMonthlyViews: 500,
      revenueSharePercent: 50,
      perks: ['Basic analytics', 'Priority support'],
    ),
    CreatorTier.silver: TierRequirements(
      tier: CreatorTier.silver,
      minFollowers: 500,
      minWeeklyStreamHours: 10,
      minEngagementRate: 0.03,
      minMonthlyViews: 2500,
      revenueSharePercent: 55,
      perks: ['Advanced analytics', 'Custom profile badge', 'Early feature access'],
    ),
    CreatorTier.gold: TierRequirements(
      tier: CreatorTier.gold,
      minFollowers: 2000,
      minWeeklyStreamHours: 15,
      minEngagementRate: 0.04,
      minMonthlyViews: 10000,
      revenueSharePercent: 60,
      perks: ['Revenue dashboard', 'Monetization tools', 'Creator community access'],
    ),
    CreatorTier.platinum: TierRequirements(
      tier: CreatorTier.platinum,
      minFollowers: 10000,
      minWeeklyStreamHours: 20,
      minEngagementRate: 0.05,
      minMonthlyViews: 50000,
      revenueSharePercent: 65,
      perks: ['Dedicated manager', 'Brand partnership opportunities', 'Featured placement'],
    ),
    CreatorTier.diamond: TierRequirements(
      tier: CreatorTier.diamond,
      minFollowers: 50000,
      minWeeklyStreamHours: 25,
      minEngagementRate: 0.06,
      minMonthlyViews: 200000,
      revenueSharePercent: 70,
      perks: ['VIP everything', 'Exclusive events', 'Custom features', 'Revenue advances'],
    ),
  };
}

/// Model for creator profile
class CreatorProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final CreatorTier tier;
  final CreatorApplicationStatus applicationStatus;
  final DateTime joinedAt;
  final DateTime? tierUpdatedAt;
  final CreatorStats stats;
  final EarningsSummary earnings;
  final List<String> specializations;
  final Map<String, dynamic> settings;

  const CreatorProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.tier,
    required this.applicationStatus,
    required this.joinedAt,
    this.tierUpdatedAt,
    required this.stats,
    required this.earnings,
    this.specializations = const [],
    this.settings = const {},
  });

  bool get isApproved => applicationStatus == CreatorApplicationStatus.approved;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'tier': tier.name,
    'applicationStatus': applicationStatus.name,
    'joinedAt': joinedAt.toIso8601String(),
    'tierUpdatedAt': tierUpdatedAt?.toIso8601String(),
    'stats': stats.toMap(),
    'earnings': earnings.toMap(),
    'specializations': specializations,
    'settings': settings,
  };
}

/// Creator statistics
class CreatorStats {
  final int followers;
  final int totalViews;
  final int monthlyViews;
  final double engagementRate;
  final int totalStreamHours;
  final int weeklyStreamHours;
  final int totalRooms;
  final int activeRooms;
  final double averageViewers;
  final int peakViewers;
  final DateTime? lastStreamAt;

  const CreatorStats({
    this.followers = 0,
    this.totalViews = 0,
    this.monthlyViews = 0,
    this.engagementRate = 0,
    this.totalStreamHours = 0,
    this.weeklyStreamHours = 0,
    this.totalRooms = 0,
    this.activeRooms = 0,
    this.averageViewers = 0,
    this.peakViewers = 0,
    this.lastStreamAt,
  });

  Map<String, dynamic> toMap() => {
    'followers': followers,
    'totalViews': totalViews,
    'monthlyViews': monthlyViews,
    'engagementRate': engagementRate,
    'totalStreamHours': totalStreamHours,
    'weeklyStreamHours': weeklyStreamHours,
    'totalRooms': totalRooms,
    'activeRooms': activeRooms,
    'averageViewers': averageViewers,
    'peakViewers': peakViewers,
    'lastStreamAt': lastStreamAt?.toIso8601String(),
  };

  factory CreatorStats.fromMap(Map<String, dynamic> map) => CreatorStats(
    followers: map['followers'] ?? 0,
    totalViews: map['totalViews'] ?? 0,
    monthlyViews: map['monthlyViews'] ?? 0,
    engagementRate: (map['engagementRate'] as num?)?.toDouble() ?? 0,
    totalStreamHours: map['totalStreamHours'] ?? 0,
    weeklyStreamHours: map['weeklyStreamHours'] ?? 0,
    totalRooms: map['totalRooms'] ?? 0,
    activeRooms: map['activeRooms'] ?? 0,
    averageViewers: (map['averageViewers'] as num?)?.toDouble() ?? 0,
    peakViewers: map['peakViewers'] ?? 0,
    lastStreamAt: map['lastStreamAt'] != null
        ? DateTime.parse(map['lastStreamAt'])
        : null,
  );
}

/// Creator earnings summary
class EarningsSummary {
  final double totalEarnings;
  final double pendingPayout;
  final double lifetimeEarnings;
  final double thisMonthEarnings;
  final double lastMonthEarnings;
  final Map<EarningType, double> earningsByType;
  final DateTime? lastPayoutAt;
  final double lastPayoutAmount;

  const EarningsSummary({
    this.totalEarnings = 0,
    this.pendingPayout = 0,
    this.lifetimeEarnings = 0,
    this.thisMonthEarnings = 0,
    this.lastMonthEarnings = 0,
    this.earningsByType = const {},
    this.lastPayoutAt,
    this.lastPayoutAmount = 0,
  });

  Map<String, dynamic> toMap() => {
    'totalEarnings': totalEarnings,
    'pendingPayout': pendingPayout,
    'lifetimeEarnings': lifetimeEarnings,
    'thisMonthEarnings': thisMonthEarnings,
    'lastMonthEarnings': lastMonthEarnings,
    'earningsByType': earningsByType.map((k, v) => MapEntry(k.name, v)),
    'lastPayoutAt': lastPayoutAt?.toIso8601String(),
    'lastPayoutAmount': lastPayoutAmount,
  };

  factory EarningsSummary.fromMap(Map<String, dynamic> map) => EarningsSummary(
    totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0,
    pendingPayout: (map['pendingPayout'] as num?)?.toDouble() ?? 0,
    lifetimeEarnings: (map['lifetimeEarnings'] as num?)?.toDouble() ?? 0,
    thisMonthEarnings: (map['thisMonthEarnings'] as num?)?.toDouble() ?? 0,
    lastMonthEarnings: (map['lastMonthEarnings'] as num?)?.toDouble() ?? 0,
    earningsByType: (map['earningsByType'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(
              EarningType.values.firstWhere((e) => e.name == k),
              (v as num).toDouble(),
            )) ??
        {},
    lastPayoutAt: map['lastPayoutAt'] != null
        ? DateTime.parse(map['lastPayoutAt'])
        : null,
    lastPayoutAmount: (map['lastPayoutAmount'] as num?)?.toDouble() ?? 0,
  );
}

/// Individual earning transaction
class EarningTransaction {
  final String id;
  final String creatorId;
  final EarningType type;
  final double amount;
  final String description;
  final String? sourceId;
  final DateTime createdAt;
  final bool paid;
  final DateTime? paidAt;

  const EarningTransaction({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.amount,
    required this.description,
    this.sourceId,
    required this.createdAt,
    this.paid = false,
    this.paidAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorId': creatorId,
    'type': type.name,
    'amount': amount,
    'description': description,
    'sourceId': sourceId,
    'createdAt': createdAt.toIso8601String(),
    'paid': paid,
    'paidAt': paidAt?.toIso8601String(),
  };
}

/// Service for managing the creator program
class CreatorProgramService {
  static CreatorProgramService? _instance;
  static CreatorProgramService get instance => _instance ??= CreatorProgramService._();

  CreatorProgramService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _creatorsCollection =>
      _firestore.collection('creators');

  CollectionReference<Map<String, dynamic>> get _applicationsCollection =>
      _firestore.collection('creator_applications');

  CollectionReference<Map<String, dynamic>> get _earningsCollection =>
      _firestore.collection('creator_earnings');

  CollectionReference<Map<String, dynamic>> get _payoutsCollection =>
      _firestore.collection('creator_payouts');

  // Cache
  final Map<String, CreatorProfile> _profileCache = {};

  // Stream controllers
  final _profileUpdateController = StreamController<CreatorProfile>.broadcast();
  final _earningsUpdateController = StreamController<EarningTransaction>.broadcast();

  /// Stream of profile updates
  Stream<CreatorProfile> get profileUpdateStream => _profileUpdateController.stream;

  /// Stream of earnings updates
  Stream<EarningTransaction> get earningsUpdateStream => _earningsUpdateController.stream;

  /// Apply to the creator program
  Future<String> applyToProgram({
    required String displayName,
    required List<String> specializations,
    String? bio,
    String? socialLinks,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Check if already applied
    final existingApp = await _applicationsCollection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existingApp.docs.isNotEmpty) {
      throw Exception('Application already exists');
    }

    final docRef = _applicationsCollection.doc();

    await docRef.set({
      'id': docRef.id,
      'userId': userId,
      'displayName': displayName,
      'specializations': specializations,
      'bio': bio,
      'socialLinks': socialLinks,
      'status': CreatorApplicationStatus.pending.name,
      'appliedAt': FieldValue.serverTimestamp(),
    });

    AnalyticsService.instance.logEvent(
      name: 'creator_application_submitted',
      parameters: {
        'user_id': userId,
        'specializations': specializations.join(','),
      },
    );

    return docRef.id;
  }

  /// Get creator profile by user ID
  Future<CreatorProfile?> getCreatorProfile({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;

    // Check cache
    if (_profileCache.containsKey(uid)) {
      return _profileCache[uid];
    }

    final snapshot = await _creatorsCollection
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final profile = _parseCreatorProfile(snapshot.docs.first);
    _profileCache[uid] = profile;

    return profile;
  }

  /// Get creator profile by creator ID
  Future<CreatorProfile?> getCreatorById(String creatorId) async {
    final doc = await _creatorsCollection.doc(creatorId).get();
    if (!doc.exists) return null;
    return _parseCreatorProfile(doc);
  }

  /// Check eligibility for tier upgrade
  Future<CreatorTier?> checkTierEligibility(String creatorId) async {
    final profile = await getCreatorById(creatorId);
    if (profile == null || !profile.isApproved) return null;

    final stats = profile.stats;
    CreatorTier? eligibleTier;

    // Check each tier from highest to lowest
    for (final tier in CreatorTier.values.reversed) {
      if (tier == CreatorTier.applicant) continue;

      final requirements = TierRequirements.requirements[tier];
      if (requirements == null) continue;

      if (stats.followers >= requirements.minFollowers &&
          stats.weeklyStreamHours >= requirements.minWeeklyStreamHours &&
          stats.engagementRate >= requirements.minEngagementRate &&
          stats.monthlyViews >= requirements.minMonthlyViews) {
        eligibleTier = tier;
        break;
      }
    }

    return eligibleTier;
  }

  /// Process tier upgrade
  Future<bool> processTierUpgrade(String creatorId) async {
    final eligibleTier = await checkTierEligibility(creatorId);
    final profile = await getCreatorById(creatorId);

    if (eligibleTier == null || profile == null) return false;
    if (eligibleTier.index <= profile.tier.index) return false;

    await _creatorsCollection.doc(creatorId).update({
      'tier': eligibleTier.name,
      'tierUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Invalidate cache
    _profileCache.remove(profile.userId);

    AnalyticsService.instance.logEvent(
      name: 'creator_tier_upgraded',
      parameters: {
        'creator_id': creatorId,
        'old_tier': profile.tier.name,
        'new_tier': eligibleTier.name,
      },
    );

    return true;
  }

  /// Record earnings for a creator
  Future<EarningTransaction> recordEarnings({
    required String creatorId,
    required EarningType type,
    required double amount,
    required String description,
    String? sourceId,
  }) async {
    final docRef = _earningsCollection.doc();

    final transaction = EarningTransaction(
      id: docRef.id,
      creatorId: creatorId,
      type: type,
      amount: amount,
      description: description,
      sourceId: sourceId,
      createdAt: DateTime.now(),
    );

    await docRef.set(transaction.toMap());

    // Update creator's earnings summary
    await _creatorsCollection.doc(creatorId).update({
      'earnings.totalEarnings': FieldValue.increment(amount),
      'earnings.pendingPayout': FieldValue.increment(amount),
      'earnings.thisMonthEarnings': FieldValue.increment(amount),
      'earnings.earningsByType.${type.name}': FieldValue.increment(amount),
    });

    // Invalidate cache
    final profile = await getCreatorById(creatorId);
    if (profile != null) {
      _profileCache.remove(profile.userId);
    }

    _earningsUpdateController.add(transaction);

    return transaction;
  }

  /// Get earnings history for a creator
  Future<List<EarningTransaction>> getEarningsHistory({
    required String creatorId,
    int limit = 50,
    EarningType? filterType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _earningsCollection
        .where('creatorId', isEqualTo: creatorId);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    final snapshot = await query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return EarningTransaction(
        id: data['id'] ?? doc.id,
        creatorId: data['creatorId'] ?? '',
        type: EarningType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => EarningType.giftRevenue,
        ),
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        description: data['description'] ?? '',
        sourceId: data['sourceId'],
        createdAt: DateTime.parse(data['createdAt']),
        paid: data['paid'] ?? false,
        paidAt: data['paidAt'] != null ? DateTime.parse(data['paidAt']) : null,
      );
    }).toList();
  }

  /// Request payout
  Future<String> requestPayout({
    required String creatorId,
    required double amount,
    required String paymentMethod,
    required Map<String, String> paymentDetails,
  }) async {
    final profile = await getCreatorById(creatorId);
    if (profile == null) throw Exception('Creator not found');

    if (amount > profile.earnings.pendingPayout) {
      throw Exception('Insufficient pending balance');
    }

    final docRef = _payoutsCollection.doc();

    await docRef.set({
      'id': docRef.id,
      'creatorId': creatorId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });

    // Deduct from pending payout
    await _creatorsCollection.doc(creatorId).update({
      'earnings.pendingPayout': FieldValue.increment(-amount),
    });

    // Invalidate cache
    _profileCache.remove(profile.userId);

    AnalyticsService.instance.logEvent(
      name: 'payout_requested',
      parameters: {
        'creator_id': creatorId,
        'amount': amount,
        'method': paymentMethod,
      },
    );

    return docRef.id;
  }

  /// Get top creators by various metrics
  Future<List<CreatorProfile>> getTopCreators({
    int limit = 10,
    String sortBy = 'followers',
    CreatorTier? filterTier,
  }) async {
    Query<Map<String, dynamic>> query = _creatorsCollection
        .where('applicationStatus', isEqualTo: CreatorApplicationStatus.approved.name);

    if (filterTier != null) {
      query = query.where('tier', isEqualTo: filterTier.name);
    }

    query = query.orderBy('stats.$sortBy', descending: true).limit(limit);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => _parseCreatorProfile(doc)).toList();
  }

  /// Update creator stats
  Future<void> updateCreatorStats({
    required String creatorId,
    int? followers,
    int? views,
    double? engagementRate,
    int? streamMinutes,
  }) async {
    final updates = <String, dynamic>{};

    if (followers != null) {
      updates['stats.followers'] = followers;
    }
    if (views != null) {
      updates['stats.totalViews'] = FieldValue.increment(views);
      updates['stats.monthlyViews'] = FieldValue.increment(views);
    }
    if (engagementRate != null) {
      updates['stats.engagementRate'] = engagementRate;
    }
    if (streamMinutes != null) {
      final hours = streamMinutes ~/ 60;
      updates['stats.totalStreamHours'] = FieldValue.increment(hours);
      updates['stats.weeklyStreamHours'] = FieldValue.increment(hours);
      updates['stats.lastStreamAt'] = DateTime.now().toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _creatorsCollection.doc(creatorId).update(updates);

      // Invalidate cache
      final profile = await getCreatorById(creatorId);
      if (profile != null) {
        _profileCache.remove(profile.userId);
      }
    }
  }

  /// Get dashboard data for a creator
  Future<Map<String, dynamic>> getDashboardData(String creatorId) async {
    final profile = await getCreatorById(creatorId);
    if (profile == null) return {};

    final recentEarnings = await getEarningsHistory(
      creatorId: creatorId,
      limit: 10,
    );

    final eligibleTier = await checkTierEligibility(creatorId);

    return {
      'profile': profile.toMap(),
      'tier': profile.tier.name,
      'tierRequirements': TierRequirements.requirements[profile.tier]?.toMap(),
      'nextTier': eligibleTier?.name,
      'stats': profile.stats.toMap(),
      'earnings': profile.earnings.toMap(),
      'recentEarnings': recentEarnings.map((e) => e.toMap()).toList(),
      'perks': TierRequirements.requirements[profile.tier]?.perks ?? [],
    };
  }

  // Private methods

  CreatorProfile _parseCreatorProfile(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return CreatorProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      tier: CreatorTier.values.firstWhere(
        (t) => t.name == data['tier'],
        orElse: () => CreatorTier.applicant,
      ),
      applicationStatus: CreatorApplicationStatus.values.firstWhere(
        (s) => s.name == data['applicationStatus'],
        orElse: () => CreatorApplicationStatus.pending,
      ),
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      tierUpdatedAt: data['tierUpdatedAt'] != null
          ? (data['tierUpdatedAt'] as Timestamp).toDate()
          : null,
      stats: CreatorStats.fromMap(data['stats'] ?? {}),
      earnings: EarningsSummary.fromMap(data['earnings'] ?? {}),
      specializations: List<String>.from(data['specializations'] ?? []),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  /// Dispose resources
  void dispose() {
    _profileUpdateController.close();
    _earningsUpdateController.close();
  }
}

extension TierRequirementsExtension on TierRequirements {
  Map<String, dynamic> toMap() => {
    'tier': tier.name,
    'minFollowers': minFollowers,
    'minWeeklyStreamHours': minWeeklyStreamHours,
    'minEngagementRate': minEngagementRate,
    'minMonthlyViews': minMonthlyViews,
    'revenueSharePercent': revenueSharePercent,
    'perks': perks,
  };
}


