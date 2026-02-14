/// Dynamic Economy Service
///
/// Manages real-time coin inflation control, creator market balancing,
/// dynamic gift pricing, and global event economy boosts.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Economy health status
enum EconomyHealth {
  thriving,
  healthy,
  stable,
  stressed,
  critical,
}

/// Inflation trend
enum InflationTrend {
  deflationary,
  stable,
  moderate,
  high,
  hyperinflation,
}

/// Market sector
enum MarketSector {
  gifts,
  subscriptions,
  tipping,
  premium,
  marketplace,
  sponsorships,
}

/// Coin supply metrics
class CoinSupplyMetrics {
  final double totalSupply;
  final double circulatingSupply;
  final double reserveSupply;
  final double burnedSupply;
  final double mintedToday;
  final double burnedToday;
  final double inflationRate;
  final InflationTrend trend;
  final DateTime timestamp;

  const CoinSupplyMetrics({
    required this.totalSupply,
    required this.circulatingSupply,
    required this.reserveSupply,
    required this.burnedSupply,
    required this.mintedToday,
    required this.burnedToday,
    required this.inflationRate,
    required this.trend,
    required this.timestamp,
  });

  factory CoinSupplyMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoinSupplyMetrics(
      totalSupply: (data['totalSupply'] ?? 0).toDouble(),
      circulatingSupply: (data['circulatingSupply'] ?? 0).toDouble(),
      reserveSupply: (data['reserveSupply'] ?? 0).toDouble(),
      burnedSupply: (data['burnedSupply'] ?? 0).toDouble(),
      mintedToday: (data['mintedToday'] ?? 0).toDouble(),
      burnedToday: (data['burnedToday'] ?? 0).toDouble(),
      inflationRate: (data['inflationRate'] ?? 0).toDouble(),
      trend: InflationTrend.values.firstWhere(
        (t) => t.name == data['trend'],
        orElse: () => InflationTrend.stable,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalSupply': totalSupply,
        'circulatingSupply': circulatingSupply,
        'reserveSupply': reserveSupply,
        'burnedSupply': burnedSupply,
        'mintedToday': mintedToday,
        'burnedToday': burnedToday,
        'inflationRate': inflationRate,
        'trend': trend.name,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

/// Creator market metrics
class CreatorMarketMetrics {
  final int totalCreators;
  final int activeCreators;
  final double totalEarnings;
  final double averageEarnings;
  final double medianEarnings;
  final double giniCoefficient;
  final double topTenPercent;
  final Map<String, double> earningsByCategory;
  final DateTime timestamp;

  const CreatorMarketMetrics({
    required this.totalCreators,
    required this.activeCreators,
    required this.totalEarnings,
    required this.averageEarnings,
    required this.medianEarnings,
    required this.giniCoefficient,
    required this.topTenPercent,
    this.earningsByCategory = const {},
    required this.timestamp,
  });

  factory CreatorMarketMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreatorMarketMetrics(
      totalCreators: data['totalCreators'] ?? 0,
      activeCreators: data['activeCreators'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      averageEarnings: (data['averageEarnings'] ?? 0).toDouble(),
      medianEarnings: (data['medianEarnings'] ?? 0).toDouble(),
      giniCoefficient: (data['giniCoefficient'] ?? 0).toDouble(),
      topTenPercent: (data['topTenPercent'] ?? 0).toDouble(),
      earningsByCategory: Map<String, double>.from(
        (data['earningsByCategory'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalCreators': totalCreators,
        'activeCreators': activeCreators,
        'totalEarnings': totalEarnings,
        'averageEarnings': averageEarnings,
        'medianEarnings': medianEarnings,
        'giniCoefficient': giniCoefficient,
        'topTenPercent': topTenPercent,
        'earningsByCategory': earningsByCategory,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  EconomyHealth get marketHealth {
    // Lower gini = more equal distribution = healthier market
    if (giniCoefficient < 0.3) return EconomyHealth.thriving;
    if (giniCoefficient < 0.4) return EconomyHealth.healthy;
    if (giniCoefficient < 0.5) return EconomyHealth.stable;
    if (giniCoefficient < 0.6) return EconomyHealth.stressed;
    return EconomyHealth.critical;
  }
}

/// Gift pricing data
class GiftPricing {
  final String giftId;
  final String name;
  final int basePrice;
  final int currentPrice;
  final double demandMultiplier;
  final double supplyMultiplier;
  final DateTime lastAdjusted;
  final List<int> priceHistory;

  const GiftPricing({
    required this.giftId,
    required this.name,
    required this.basePrice,
    required this.currentPrice,
    this.demandMultiplier = 1.0,
    this.supplyMultiplier = 1.0,
    required this.lastAdjusted,
    this.priceHistory = const [],
  });

  factory GiftPricing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftPricing(
      giftId: doc.id,
      name: data['name'] ?? '',
      basePrice: data['basePrice'] ?? 0,
      currentPrice: data['currentPrice'] ?? data['basePrice'] ?? 0,
      demandMultiplier: (data['demandMultiplier'] ?? 1).toDouble(),
      supplyMultiplier: (data['supplyMultiplier'] ?? 1).toDouble(),
      lastAdjusted: (data['lastAdjusted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priceHistory: List<int>.from(data['priceHistory'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'basePrice': basePrice,
        'currentPrice': currentPrice,
        'demandMultiplier': demandMultiplier,
        'supplyMultiplier': supplyMultiplier,
        'lastAdjusted': Timestamp.fromDate(lastAdjusted),
        'priceHistory': priceHistory,
      };

  double get priceChange =>
      basePrice > 0 ? (currentPrice - basePrice) / basePrice * 100 : 0;
}

/// Economy boost event
class EconomyBoost {
  final String boostId;
  final String name;
  final String description;
  final double multiplier;
  final List<MarketSector> affectedSectors;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final Map<String, dynamic> conditions;

  const EconomyBoost({
    required this.boostId,
    required this.name,
    required this.description,
    required this.multiplier,
    this.affectedSectors = const [],
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.conditions = const {},
  });

  factory EconomyBoost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EconomyBoost(
      boostId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      multiplier: (data['multiplier'] ?? 1).toDouble(),
      affectedSectors: (data['affectedSectors'] as List<dynamic>? ?? [])
          .map((s) => MarketSector.values.firstWhere(
                (ms) => ms.name == s,
                orElse: () => MarketSector.gifts,
              ))
          .toList(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      conditions: Map<String, dynamic>.from(data['conditions'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'multiplier': multiplier,
        'affectedSectors': affectedSectors.map((s) => s.name).toList(),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'isActive': isActive,
        'conditions': conditions,
      };

  bool get isCurrentlyActive =>
      isActive &&
      DateTime.now().isAfter(startTime) &&
      DateTime.now().isBefore(endTime);
}

/// Economic stability indicators
class EconomicStability {
  final EconomyHealth overallHealth;
  final double velocityOfMoney;
  final double savingsRate;
  final double spendingRate;
  final double transactionVolume;
  final Map<String, double> sectorHealth;
  final List<String> warnings;
  final List<String> recommendations;

  const EconomicStability({
    required this.overallHealth,
    required this.velocityOfMoney,
    required this.savingsRate,
    required this.spendingRate,
    required this.transactionVolume,
    this.sectorHealth = const {},
    this.warnings = const [],
    this.recommendations = const [],
  });
}

/// Dynamic economy service singleton
class DynamicEconomyService {
  static DynamicEconomyService? _instance;
  static DynamicEconomyService get instance =>
      _instance ??= DynamicEconomyService._();

  DynamicEconomyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _metricsCollection =>
      _firestore.collection('economy_metrics');
  CollectionReference get _giftPricingCollection =>
      _firestore.collection('gift_pricing');
  CollectionReference get _boostsCollection =>
      _firestore.collection('economy_boosts');
  CollectionReference get _transactionsCollection =>
      _firestore.collection('transactions');

  final StreamController<CoinSupplyMetrics> _supplyController =
      StreamController<CoinSupplyMetrics>.broadcast();
  final StreamController<CreatorMarketMetrics> _marketController =
      StreamController<CreatorMarketMetrics>.broadcast();

  Stream<CoinSupplyMetrics> get supplyStream => _supplyController.stream;
  Stream<CreatorMarketMetrics> get marketStream => _marketController.stream;

  Timer? _inflationControlTimer;
  Timer? _pricingAdjustmentTimer;

  // ============================================================
  // COIN INFLATION CONTROL
  // ============================================================

  /// Monitor and control real-time coin inflation
  Future<CoinSupplyMetrics> realTimeCoinInflationControl() async {
    debugPrint('💰 [Economy] Checking coin inflation');

    // Get current supply metrics
    final metricsDoc = await _metricsCollection.doc('coin_supply').get();
    CoinSupplyMetrics metrics;

    if (metricsDoc.exists) {
      metrics = CoinSupplyMetrics.fromFirestore(metricsDoc);
    } else {
      // Initialize with defaults
      metrics = CoinSupplyMetrics(
        totalSupply: 1000000000, // 1 billion initial supply
        circulatingSupply: 100000000, // 100 million circulating
        reserveSupply: 900000000,
        burnedSupply: 0,
        mintedToday: 0,
        burnedToday: 0,
        inflationRate: 0,
        trend: InflationTrend.stable,
        timestamp: DateTime.now(),
      );
    }

    // Calculate current inflation rate
    final dailyInflation = metrics.circulatingSupply > 0
        ? (metrics.mintedToday - metrics.burnedToday) / metrics.circulatingSupply * 100
        : 0.0;

    // Determine inflation trend
    InflationTrend trend;
    if (dailyInflation < -0.1) {
      trend = InflationTrend.deflationary;
    } else if (dailyInflation < 0.05) {
      trend = InflationTrend.stable;
    } else if (dailyInflation < 0.2) {
      trend = InflationTrend.moderate;
    } else if (dailyInflation < 0.5) {
      trend = InflationTrend.high;
    } else {
      trend = InflationTrend.hyperinflation;
    }

    // Apply inflation control measures
    if (trend == InflationTrend.high || trend == InflationTrend.hyperinflation) {
      await _applyInflationControls(metrics, dailyInflation);
    }

    // Update metrics
    final updatedMetrics = CoinSupplyMetrics(
      totalSupply: metrics.totalSupply,
      circulatingSupply: metrics.circulatingSupply,
      reserveSupply: metrics.reserveSupply,
      burnedSupply: metrics.burnedSupply,
      mintedToday: metrics.mintedToday,
      burnedToday: metrics.burnedToday,
      inflationRate: dailyInflation,
      trend: trend,
      timestamp: DateTime.now(),
    );

    await _metricsCollection.doc('coin_supply').set(updatedMetrics.toFirestore());
    _supplyController.add(updatedMetrics);

    debugPrint('📊 [Economy] Inflation rate: ${dailyInflation.toStringAsFixed(2)}% ($trend)');
    return updatedMetrics;
  }

  Future<void> _applyInflationControls(
    CoinSupplyMetrics metrics,
    double inflationRate,
  ) async {
    debugPrint('⚠️ [Economy] Applying inflation controls');

    // Reduce minting rates
    await _metricsCollection.doc('minting_config').update({
      'dailyMintingCap': FieldValue.increment(-1000),
      'lastAdjusted': Timestamp.now(),
    });

    // Increase burn rates on transactions
    await _metricsCollection.doc('burn_config').update({
      'transactionBurnRate': FieldValue.increment(0.001),
      'lastAdjusted': Timestamp.now(),
    });

    // Log control action
    await _metricsCollection.doc('control_log').collection('actions').add({
      'type': 'inflation_control',
      'inflationRate': inflationRate,
      'action': 'reduce_minting_increase_burn',
      'timestamp': Timestamp.now(),
    });
  }

  /// Start automatic inflation monitoring
  void startInflationMonitoring({Duration interval = const Duration(hours: 1)}) {
    _inflationControlTimer?.cancel();
    _inflationControlTimer = Timer.periodic(interval, (_) {
      realTimeCoinInflationControl();
    });
    debugPrint('⏱️ [Economy] Inflation monitoring started');
  }

  void stopInflationMonitoring() {
    _inflationControlTimer?.cancel();
    debugPrint('⏱️ [Economy] Inflation monitoring stopped');
  }

  // ============================================================
  // CREATOR MARKET BALANCING
  // ============================================================

  /// Balance creator market distribution
  Future<CreatorMarketMetrics> creatorMarketBalancing() async {
    debugPrint('⚖️ [Economy] Balancing creator market');

    // Get creator earnings data
    final creatorsSnapshot = await _firestore
        .collection('creators')
        .orderBy('totalEarnings', descending: true)
        .get();

    final earnings = <double>[];
    final earningsByCategory = <String, double>{};

    for (final doc in creatorsSnapshot.docs) {
      final data = doc.data();
      final creatorEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0;
      earnings.add(creatorEarnings);

      final category = data['primaryCategory'] as String? ?? 'general';
      earningsByCategory[category] =
          (earningsByCategory[category] ?? 0) + creatorEarnings;
    }

    if (earnings.isEmpty) {
      return CreatorMarketMetrics(
        totalCreators: 0,
        activeCreators: 0,
        totalEarnings: 0,
        averageEarnings: 0,
        medianEarnings: 0,
        giniCoefficient: 0,
        topTenPercent: 0,
        timestamp: DateTime.now(),
      );
    }

    // Calculate metrics
    final totalEarnings = earnings.fold<double>(0, (total, e) => total + e);
    final averageEarnings = totalEarnings / earnings.length;

    earnings.sort();
    final medianEarnings = earnings[earnings.length ~/ 2].toDouble();

    final giniCoefficient = _calculateGiniCoefficient(earnings);

    // Top 10% earnings share
    final topTenCount = (earnings.length * 0.1).ceil();
    final topTenEarnings = earnings.reversed.take(topTenCount).fold<double>(0.0, (s, e) => s + e);
    final topTenPercent = totalEarnings > 0 ? topTenEarnings / totalEarnings * 100 : 0.0;

    // Apply balancing measures if needed
    if (giniCoefficient > 0.5) {
      await _applyMarketBalancing(giniCoefficient);
    }

    final metrics = CreatorMarketMetrics(
      totalCreators: creatorsSnapshot.docs.length,
      activeCreators: earnings.where((e) => e > 0).length,
      totalEarnings: totalEarnings,
      averageEarnings: averageEarnings,
      medianEarnings: medianEarnings,
      giniCoefficient: giniCoefficient,
      topTenPercent: topTenPercent,
      earningsByCategory: earningsByCategory,
      timestamp: DateTime.now(),
    );

    await _metricsCollection.doc('creator_market').set(metrics.toFirestore());
    _marketController.add(metrics);

    debugPrint('📊 [Economy] Gini coefficient: ${giniCoefficient.toStringAsFixed(3)}');
    return metrics;
  }

  double _calculateGiniCoefficient(List<double> values) {
    if (values.isEmpty) return 0;

    final n = values.length;
    final sorted = List<double>.from(values)..sort();
    final total = sorted.fold<double>(0, (total, v) => total + v);

    if (total == 0) return 0;

    var sumOfDifferences = 0.0;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        sumOfDifferences += (sorted[i] - sorted[j]).abs();
      }
    }

    return sumOfDifferences / (2 * n * n * (total / n));
  }

  Future<void> _applyMarketBalancing(double giniCoefficient) async {
    debugPrint('⚖️ [Economy] Applying market balancing measures');

    // Boost smaller creators
    await _metricsCollection.doc('creator_config').set({
      'smallCreatorBoostMultiplier': 1.2,
      'topCreatorCapMultiplier': 0.95,
      'lastAdjusted': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // ============================================================
  // DYNAMIC GIFT PRICING
  // ============================================================

  /// Adjust gift pricing based on supply and demand
  Future<List<GiftPricing>> dynamicGiftPricing() async {
    debugPrint('🎁 [Economy] Adjusting gift pricing');

    final pricingSnapshot = await _giftPricingCollection.get();
    final updatedPricing = <GiftPricing>[];

    for (final doc in pricingSnapshot.docs) {
      final pricing = GiftPricing.fromFirestore(doc);

      // Get gift transaction volume
      final volumeSnapshot = await _transactionsCollection
          .where('giftId', isEqualTo: pricing.giftId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 24)),
          ))
          .get();

      final volume = volumeSnapshot.docs.length;

      // Calculate demand multiplier
      final baselineVolume = 100; // Expected daily volume
      final demandMultiplier = math.max(0.8, math.min(1.5, volume / baselineVolume));

      // Calculate new price
      final newPrice = (pricing.basePrice * demandMultiplier).round();

      // Limit price changes to ±20% per day
      final maxChange = (pricing.currentPrice * 0.2).round();
      final finalPrice = (newPrice - pricing.currentPrice).abs() > maxChange
          ? pricing.currentPrice + (newPrice > pricing.currentPrice ? maxChange : -maxChange)
          : newPrice;

      final updated = GiftPricing(
        giftId: pricing.giftId,
        name: pricing.name,
        basePrice: pricing.basePrice,
        currentPrice: finalPrice,
        demandMultiplier: demandMultiplier,
        supplyMultiplier: pricing.supplyMultiplier,
        lastAdjusted: DateTime.now(),
        priceHistory: [...pricing.priceHistory.skip((pricing.priceHistory.length - 30).clamp(0, pricing.priceHistory.length)), finalPrice],
      );

      await _giftPricingCollection.doc(pricing.giftId).set(updated.toFirestore());
      updatedPricing.add(updated);
    }

    debugPrint('✅ [Economy] Updated ${updatedPricing.length} gift prices');
    return updatedPricing;
  }

  /// Get current gift pricing
  Future<List<GiftPricing>> getGiftPricing() async {
    final snapshot = await _giftPricingCollection.get();
    return snapshot.docs.map((doc) => GiftPricing.fromFirestore(doc)).toList();
  }

  /// Start automatic pricing adjustment
  void startPricingAdjustment({Duration interval = const Duration(hours: 6)}) {
    _pricingAdjustmentTimer?.cancel();
    _pricingAdjustmentTimer = Timer.periodic(interval, (_) {
      dynamicGiftPricing();
    });
    debugPrint('⏱️ [Economy] Pricing adjustment started');
  }

  void stopPricingAdjustment() {
    _pricingAdjustmentTimer?.cancel();
    debugPrint('⏱️ [Economy] Pricing adjustment stopped');
  }

  // ============================================================
  // GLOBAL EVENT ECONOMY BOOSTS
  // ============================================================

  /// Create and manage economy boost events
  Future<EconomyBoost> globalEventEconomyBoosts({
    required String name,
    required String description,
    required double multiplier,
    required List<MarketSector> sectors,
    required Duration duration,
    Map<String, dynamic>? conditions,
  }) async {
    debugPrint('🚀 [Economy] Creating economy boost: $name');

    final boostRef = _boostsCollection.doc();
    final now = DateTime.now();

    final boost = EconomyBoost(
      boostId: boostRef.id,
      name: name,
      description: description,
      multiplier: multiplier,
      affectedSectors: sectors,
      startTime: now,
      endTime: now.add(duration),
      isActive: true,
      conditions: conditions ?? {},
    );

    await boostRef.set(boost.toFirestore());

    debugPrint('✅ [Economy] Boost created: ${boost.boostId}');
    return boost;
  }

  /// Get active boosts
  Future<List<EconomyBoost>> getActiveBoosts() async {
    final now = Timestamp.now();
    final snapshot = await _boostsCollection
        .where('isActive', isEqualTo: true)
        .where('endTime', isGreaterThan: now)
        .get();

    return snapshot.docs.map((doc) => EconomyBoost.fromFirestore(doc)).toList();
  }

  /// Get boost multiplier for a sector
  Future<double> getBoostMultiplier(MarketSector sector) async {
    final boosts = await getActiveBoosts();
    var multiplier = 1.0;

    for (final boost in boosts) {
      if (boost.isCurrentlyActive && boost.affectedSectors.contains(sector)) {
        multiplier *= boost.multiplier;
      }
    }

    return multiplier;
  }

  /// End boost early
  Future<void> endBoost(String boostId) async {
    await _boostsCollection.doc(boostId).update({
      'isActive': false,
      'endTime': Timestamp.now(),
    });
    debugPrint('🛑 [Economy] Boost ended: $boostId');
  }

  // ============================================================
  // ECONOMIC STABILITY
  // ============================================================

  /// Get economic stability indicators
  Future<EconomicStability> getEconomicStability() async {
    final supplyMetrics = await realTimeCoinInflationControl();
    final marketMetrics = await creatorMarketBalancing();

    // Calculate velocity of money (transactions / circulating supply)
    final transactionsSnapshot = await _transactionsCollection
        .where('timestamp', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        ))
        .get();

    final weeklyTransactionVolume = transactionsSnapshot.docs
        .fold<double>(0, (total, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return total + ((data['amount'] as num?)?.toDouble() ?? 0);
    });

    final velocityOfMoney = supplyMetrics.circulatingSupply > 0
        ? (weeklyTransactionVolume / supplyMetrics.circulatingSupply) * 52
        : 0.0;

    // Determine overall health
    EconomyHealth health;
    final warnings = <String>[];
    final recommendations = <String>[];

    if (supplyMetrics.trend == InflationTrend.hyperinflation) {
      health = EconomyHealth.critical;
      warnings.add('Hyperinflation detected');
      recommendations.add('Immediately reduce minting and increase burn rates');
    } else if (supplyMetrics.trend == InflationTrend.high) {
      health = EconomyHealth.stressed;
      warnings.add('High inflation rate');
      recommendations.add('Consider reducing reward distributions');
    } else if (marketMetrics.giniCoefficient > 0.6) {
      health = EconomyHealth.stressed;
      warnings.add('High wealth inequality among creators');
      recommendations.add('Boost visibility for smaller creators');
    } else if (velocityOfMoney < 2) {
      health = EconomyHealth.stable;
      warnings.add('Low transaction velocity');
      recommendations.add('Consider promotional events to stimulate spending');
    } else {
      health = EconomyHealth.healthy;
    }

    return EconomicStability(
      overallHealth: health,
      velocityOfMoney: velocityOfMoney,
      savingsRate: 0.3, // Placeholder
      spendingRate: 0.7,
      transactionVolume: weeklyTransactionVolume,
      sectorHealth: {
        'gifts': 0.8,
        'subscriptions': 0.75,
        'tipping': 0.85,
      },
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  void dispose() {
    _inflationControlTimer?.cancel();
    _pricingAdjustmentTimer?.cancel();
    _supplyController.close();
    _marketController.close();
  }
}
