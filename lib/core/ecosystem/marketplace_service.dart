/// Marketplace Service
///
/// Manages the creator marketplace including service listings,
/// purchases, revenue splits, and tier boosts.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Creator service listing
class CreatorService {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String description;
  final ServiceCategory category;
  final ServiceType type;
  final double price;
  final String currency;
  final Duration? duration;
  final int? maxBookings;
  final int currentBookings;
  final ServiceStatus status;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final List<String> images;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CreatorService({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.price,
    this.currency = 'USD',
    this.duration,
    this.maxBookings,
    this.currentBookings = 0,
    required this.status,
    this.rating = 0,
    this.reviewCount = 0,
    this.tags = const [],
    this.images = const [],
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable =>
      status == ServiceStatus.active &&
      (maxBookings == null || currentBookings < maxBookings!);

  Map<String, dynamic> toMap() => {
        'id': id,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'title': title,
        'description': description,
        'category': category.name,
        'type': type.name,
        'price': price,
        'currency': currency,
        'durationMinutes': duration?.inMinutes,
        'maxBookings': maxBookings,
        'currentBookings': currentBookings,
        'status': status.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'tags': tags,
        'images': images,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory CreatorService.fromMap(Map<String, dynamic> map) => CreatorService(
        id: map['id'] as String,
        creatorId: map['creatorId'] as String,
        creatorName: map['creatorName'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        category: ServiceCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => ServiceCategory.other,
        ),
        type: ServiceType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => ServiceType.oneTime,
        ),
        price: (map['price'] as num).toDouble(),
        currency: map['currency'] as String? ?? 'USD',
        duration: map['durationMinutes'] != null
            ? Duration(minutes: map['durationMinutes'] as int)
            : null,
        maxBookings: map['maxBookings'] as int?,
        currentBookings: map['currentBookings'] as int? ?? 0,
        status: ServiceStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => ServiceStatus.draft,
        ),
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: map['reviewCount'] as int? ?? 0,
        tags: List<String>.from(map['tags'] ?? []),
        images: List<String>.from(map['images'] ?? []),
        metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );
}

enum ServiceCategory {
  coaching,
  consultation,
  shoutout,
  collab,
  privateSession,
  tutorial,
  merchandise,
  digitalContent,
  other,
}

enum ServiceType {
  oneTime,
  subscription,
  bundle,
  auction,
}

enum ServiceStatus {
  draft,
  pending,
  active,
  paused,
  soldOut,
  archived,
}

/// Service purchase
class ServicePurchase {
  final String id;
  final String serviceId;
  final String buyerId;
  final String creatorId;
  final double amount;
  final double platformFee;
  final double creatorEarnings;
  final String currency;
  final PurchaseStatus status;
  final DateTime purchasedAt;
  final DateTime? completedAt;
  final String? notes;

  const ServicePurchase({
    required this.id,
    required this.serviceId,
    required this.buyerId,
    required this.creatorId,
    required this.amount,
    required this.platformFee,
    required this.creatorEarnings,
    this.currency = 'USD',
    required this.status,
    required this.purchasedAt,
    this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'serviceId': serviceId,
        'buyerId': buyerId,
        'creatorId': creatorId,
        'amount': amount,
        'platformFee': platformFee,
        'creatorEarnings': creatorEarnings,
        'currency': currency,
        'status': status.name,
        'purchasedAt': purchasedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
      };
}

enum PurchaseStatus {
  pending,
  processing,
  completed,
  refunded,
  disputed,
  canceled,
}

/// Revenue split configuration
class RevenueSplit {
  final String creatorId;
  final CreatorTier tier;
  final double platformPercentage;
  final double creatorPercentage;
  final double? partnerBonus;
  final DateTime effectiveFrom;

  const RevenueSplit({
    required this.creatorId,
    required this.tier,
    required this.platformPercentage,
    required this.creatorPercentage,
    this.partnerBonus,
    required this.effectiveFrom,
  });

  Map<String, dynamic> toMap() => {
        'creatorId': creatorId,
        'tier': tier.name,
        'platformPercentage': platformPercentage,
        'creatorPercentage': creatorPercentage,
        'partnerBonus': partnerBonus,
        'effectiveFrom': effectiveFrom.toIso8601String(),
      };
}

enum CreatorTier {
  starter,
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  legend,
}

/// Tier boost
class TierBoost {
  final String id;
  final String creatorId;
  final BoostType type;
  final double multiplier;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String? reason;

  const TierBoost({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.multiplier,
    required this.startedAt,
    required this.expiresAt,
    this.reason,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toMap() => {
        'id': id,
        'creatorId': creatorId,
        'type': type.name,
        'multiplier': multiplier,
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'reason': reason,
      };
}

enum BoostType {
  visibility,
  revenue,
  featuredPlacement,
  searchRanking,
}

/// Creator earnings summary
class CreatorEarnings {
  final String creatorId;
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final int totalSales;
  final Map<String, double> earningsByService;
  final Map<String, double> earningsByMonth;
  final DateTime lastUpdated;

  const CreatorEarnings({
    required this.creatorId,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.paidEarnings,
    required this.totalSales,
    this.earningsByService = const {},
    this.earningsByMonth = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'creatorId': creatorId,
        'totalEarnings': totalEarnings,
        'pendingEarnings': pendingEarnings,
        'paidEarnings': paidEarnings,
        'totalSales': totalSales,
        'earningsByService': earningsByService,
        'earningsByMonth': earningsByMonth,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

/// Marketplace Service
class MarketplaceService {
  static MarketplaceService? _instance;
  static MarketplaceService get instance =>
      _instance ??= MarketplaceService._();

  MarketplaceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _serviceController = StreamController<CreatorService>.broadcast();
  final _purchaseController = StreamController<ServicePurchase>.broadcast();

  Stream<CreatorService> get serviceStream => _serviceController.stream;
  Stream<ServicePurchase> get purchaseStream => _purchaseController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _servicesCollection =>
      _firestore.collection('marketplace_services');

  CollectionReference<Map<String, dynamic>> get _purchasesCollection =>
      _firestore.collection('marketplace_purchases');

  CollectionReference<Map<String, dynamic>> get _earningsCollection =>
      _firestore.collection('creator_earnings');

  CollectionReference<Map<String, dynamic>> get _boostsCollection =>
      _firestore.collection('tier_boosts');

  // ============================================================
  // SERVICE LISTINGS
  // ============================================================

  /// List a new creator service
  Future<CreatorService> listCreatorServices({
    required String creatorId,
    required String creatorName,
    required String title,
    required String description,
    required ServiceCategory category,
    required ServiceType type,
    required double price,
    String currency = 'USD',
    Duration? duration,
    int? maxBookings,
    List<String>? tags,
    List<String>? images,
  }) async {
    debugPrint('📦 [Marketplace] Listing service: $title');

    try {
      final id = 'svc_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final service = CreatorService(
        id: id,
        creatorId: creatorId,
        creatorName: creatorName,
        title: title,
        description: description,
        category: category,
        type: type,
        price: price,
        currency: currency,
        duration: duration,
        maxBookings: maxBookings,
        status: ServiceStatus.pending,
        tags: tags ?? [],
        images: images ?? [],
        createdAt: DateTime.now(),
      );

      await _servicesCollection.doc(id).set(service.toMap());

      _serviceController.add(service);

      AnalyticsService.instance.logEvent(
        name: 'service_listed',
        parameters: {
          'category': category.name,
          'type': type.name,
          'price': price,
        },
      );

      debugPrint('✅ [Marketplace] Service listed: $id');
      return service;
    } catch (e) {
      debugPrint('❌ [Marketplace] Failed to list service: $e');
      rethrow;
    }
  }

  /// Get all services with optional filters
  Future<List<CreatorService>> listCreatorServicesWithFilters({
    ServiceCategory? category,
    String? creatorId,
    ServiceStatus? status,
    double? minPrice,
    double? maxPrice,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _servicesCollection;

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (creatorId != null) {
      query = query.where('creatorId', isEqualTo: creatorId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    final snapshot = await query.limit(limit).get();

    return snapshot.docs
        .map((doc) => CreatorService.fromMap(doc.data()))
        .toList();
  }

  /// Activate a service listing
  Future<bool> activateService(String serviceId) async {
    try {
      await _servicesCollection.doc(serviceId).update({
        'status': ServiceStatus.active.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ [Marketplace] Failed to activate service: $e');
      return false;
    }
  }

  // ============================================================
  // PURCHASES
  // ============================================================

  /// Purchase a creator service
  Future<ServicePurchase?> purchaseCreatorService({
    required String serviceId,
    required String buyerId,
    String? notes,
  }) async {
    debugPrint('💰 [Marketplace] Processing purchase for service: $serviceId');

    try {
      // Get service
      final serviceDoc = await _servicesCollection.doc(serviceId).get();
      if (!serviceDoc.exists) {
        throw Exception('Service not found');
      }

      final service = CreatorService.fromMap(serviceDoc.data()!);

      if (!service.isAvailable) {
        throw Exception('Service is not available');
      }

      // Calculate revenue split
      final split = await _getRevenueSplit(service.creatorId);
      final platformFee = service.price * (split.platformPercentage / 100);
      final creatorEarnings = service.price - platformFee;

      final purchaseId = 'pur_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      final purchase = ServicePurchase(
        id: purchaseId,
        serviceId: serviceId,
        buyerId: buyerId,
        creatorId: service.creatorId,
        amount: service.price,
        platformFee: platformFee,
        creatorEarnings: creatorEarnings,
        currency: service.currency,
        status: PurchaseStatus.processing,
        purchasedAt: DateTime.now(),
        notes: notes,
      );

      // Store purchase
      await _purchasesCollection.doc(purchaseId).set(purchase.toMap());

      // Update service bookings
      await _servicesCollection.doc(serviceId).update({
        'currentBookings': FieldValue.increment(1),
      });

      // Update creator earnings
      await _updateCreatorEarnings(service.creatorId, creatorEarnings, serviceId);

      _purchaseController.add(purchase);

      AnalyticsService.instance.logEvent(
        name: 'service_purchased',
        parameters: {
          'service_id': serviceId,
          'amount': service.price,
          'creator_id': service.creatorId,
        },
      );

      debugPrint('✅ [Marketplace] Purchase completed: $purchaseId');
      return purchase;
    } catch (e) {
      debugPrint('❌ [Marketplace] Purchase failed: $e');
      return null;
    }
  }

  Future<void> _updateCreatorEarnings(
    String creatorId,
    double amount,
    String serviceId,
  ) async {
    final earningsDoc = await _earningsCollection.doc(creatorId).get();

    if (earningsDoc.exists) {
      await _earningsCollection.doc(creatorId).update({
        'totalEarnings': FieldValue.increment(amount),
        'pendingEarnings': FieldValue.increment(amount),
        'totalSales': FieldValue.increment(1),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } else {
      await _earningsCollection.doc(creatorId).set({
        'creatorId': creatorId,
        'totalEarnings': amount,
        'pendingEarnings': amount,
        'paidEarnings': 0,
        'totalSales': 1,
        'earningsByService': {serviceId: amount},
        'earningsByMonth': {},
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  // ============================================================
  // REVENUE SPLIT
  // ============================================================

  /// Get revenue split for a creator
  Future<RevenueSplit> creatorRevenueSplit(String creatorId) async {
    return _getRevenueSplit(creatorId);
  }

  Future<RevenueSplit> _getRevenueSplit(String creatorId) async {
    // Get creator tier (simulated)
    final tier = await _getCreatorTier(creatorId);

    // Calculate split based on tier
    final (platformPct, creatorPct) = _getTierSplit(tier);

    // Check for any active boosts
    double? partnerBonus;
    final boosts = await _getActiveBoosts(creatorId);
    for (final boost in boosts) {
      if (boost.type == BoostType.revenue) {
        partnerBonus = (partnerBonus ?? 0) + (boost.multiplier - 1) * 100;
      }
    }

    return RevenueSplit(
      creatorId: creatorId,
      tier: tier,
      platformPercentage: platformPct,
      creatorPercentage: creatorPct + (partnerBonus ?? 0),
      partnerBonus: partnerBonus,
      effectiveFrom: DateTime.now(),
    );
  }

  Future<CreatorTier> _getCreatorTier(String creatorId) async {
    // In production, this would check actual creator metrics
    final earningsDoc = await _earningsCollection.doc(creatorId).get();

    if (!earningsDoc.exists) return CreatorTier.starter;

    final totalEarnings = (earningsDoc.data()?['totalEarnings'] as num?)?.toDouble() ?? 0;

    if (totalEarnings >= 100000) return CreatorTier.legend;
    if (totalEarnings >= 50000) return CreatorTier.diamond;
    if (totalEarnings >= 25000) return CreatorTier.platinum;
    if (totalEarnings >= 10000) return CreatorTier.gold;
    if (totalEarnings >= 5000) return CreatorTier.silver;
    if (totalEarnings >= 1000) return CreatorTier.bronze;

    return CreatorTier.starter;
  }

  (double, double) _getTierSplit(CreatorTier tier) => switch (tier) {
        CreatorTier.starter => (30.0, 70.0),
        CreatorTier.bronze => (25.0, 75.0),
        CreatorTier.silver => (22.0, 78.0),
        CreatorTier.gold => (20.0, 80.0),
        CreatorTier.platinum => (18.0, 82.0),
        CreatorTier.diamond => (15.0, 85.0),
        CreatorTier.legend => (10.0, 90.0),
      };

  // ============================================================
  // TIER BOOSTS
  // ============================================================

  /// Apply a tier boost to a creator
  Future<TierBoost> creatorTierBoosts({
    required String creatorId,
    required BoostType type,
    required double multiplier,
    required Duration duration,
    String? reason,
  }) async {
    debugPrint('🚀 [Marketplace] Applying tier boost for: $creatorId');

    try {
      final id = 'boost_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final boost = TierBoost(
        id: id,
        creatorId: creatorId,
        type: type,
        multiplier: multiplier,
        startedAt: now,
        expiresAt: now.add(duration),
        reason: reason,
      );

      await _boostsCollection.doc(id).set(boost.toMap());

      AnalyticsService.instance.logEvent(
        name: 'tier_boost_applied',
        parameters: {
          'creator_id': creatorId,
          'type': type.name,
          'multiplier': multiplier,
        },
      );

      debugPrint('✅ [Marketplace] Boost applied: $id');
      return boost;
    } catch (e) {
      debugPrint('❌ [Marketplace] Failed to apply boost: $e');
      rethrow;
    }
  }

  Future<List<TierBoost>> _getActiveBoosts(String creatorId) async {
    final snapshot = await _boostsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TierBoost(
        id: data['id'] as String,
        creatorId: data['creatorId'] as String,
        type: BoostType.values.firstWhere(
          (t) => t.name == data['type'],
        ),
        multiplier: (data['multiplier'] as num).toDouble(),
        startedAt: DateTime.parse(data['startedAt'] as String),
        expiresAt: DateTime.parse(data['expiresAt'] as String),
        reason: data['reason'] as String?,
      );
    }).toList();
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  /// Get creator earnings
  Future<CreatorEarnings?> getCreatorEarnings(String creatorId) async {
    final doc = await _earningsCollection.doc(creatorId).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return CreatorEarnings(
      creatorId: data['creatorId'] as String,
      totalEarnings: (data['totalEarnings'] as num).toDouble(),
      pendingEarnings: (data['pendingEarnings'] as num).toDouble(),
      paidEarnings: (data['paidEarnings'] as num).toDouble(),
      totalSales: data['totalSales'] as int,
      earningsByService:
          Map<String, double>.from(data['earningsByService'] ?? {}),
      earningsByMonth:
          Map<String, double>.from(data['earningsByMonth'] ?? {}),
      lastUpdated: DateTime.parse(data['lastUpdated'] as String),
    );
  }

  /// Dispose resources
  void dispose() {
    _serviceController.close();
    _purchaseController.close();
  }
}
