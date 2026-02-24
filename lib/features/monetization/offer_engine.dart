/// Offer Engine
///
/// Manages personalized offers, churn prevention, creator support bundles,
/// and event-based promotional offers.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/analytics/analytics_service.dart';

/// Represents a personalized offer
class PersonalizedOffer {
  final String id;
  final String userId;
  final OfferType type;
  final String title;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final double discountPercent;
  final DateTime expiresAt;
  final String? productId;
  final Map<String, dynamic> metadata;
  final OfferStatus status;

  PersonalizedOffer({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.expiresAt,
    this.productId,
    this.metadata = const {},
    this.status = OfferStatus.active,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == OfferStatus.active && !isExpired;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'description': description,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'discountPercent': discountPercent,
        'expiresAt': expiresAt.toIso8601String(),
        'productId': productId,
        'metadata': metadata,
        'status': status.name,
      };

  factory PersonalizedOffer.fromMap(Map<String, dynamic> map) {
    return PersonalizedOffer(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: OfferType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => OfferType.general,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      originalPrice: (map['originalPrice'] as num).toDouble(),
      discountedPrice: (map['discountedPrice'] as num).toDouble(),
      discountPercent: (map['discountPercent'] as num).toDouble(),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      productId: map['productId'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      status: OfferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OfferStatus.active,
      ),
    );
  }
}

enum OfferType {
  general,
  churnPrevention,
  winBack,
  loyalty,
  creatorSupport,
  eventBased,
  firstPurchase,
  upgrade,
}

enum OfferStatus {
  active,
  redeemed,
  expired,
  dismissed,
}

/// Churn risk assessment
class ChurnRisk {
  final String userId;
  final double riskScore;
  final ChurnRiskLevel level;
  final List<String> riskFactors;
  final DateTime assessedAt;

  const ChurnRisk({
    required this.userId,
    required this.riskScore,
    required this.level,
    required this.riskFactors,
    required this.assessedAt,
  });

  factory ChurnRisk.fromMap(Map<String, dynamic> map) {
    final score = (map['riskScore'] as num).toDouble();
    return ChurnRisk(
      userId: map['userId'] as String,
      riskScore: score,
      level: _levelFromScore(score),
      riskFactors: List<String>.from(map['riskFactors'] ?? []),
      assessedAt: map['assessedAt'] != null
          ? DateTime.parse(map['assessedAt'] as String)
          : DateTime.now(),
    );
  }

  static ChurnRiskLevel _levelFromScore(double score) {
    if (score >= 0.8) return ChurnRiskLevel.critical;
    if (score >= 0.6) return ChurnRiskLevel.high;
    if (score >= 0.4) return ChurnRiskLevel.medium;
    return ChurnRiskLevel.low;
  }
}

enum ChurnRiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Creator support bundle
class CreatorSupportBundle {
  final String id;
  final String creatorId;
  final String name;
  final String description;
  final List<String> items;
  final double price;
  final double creatorShare;
  final bool isLimitedTime;
  final DateTime? expiresAt;

  const CreatorSupportBundle({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.description,
    required this.items,
    required this.price,
    required this.creatorShare,
    this.isLimitedTime = false,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'creatorId': creatorId,
        'name': name,
        'description': description,
        'items': items,
        'price': price,
        'creatorShare': creatorShare,
        'isLimitedTime': isLimitedTime,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory CreatorSupportBundle.fromMap(Map<String, dynamic> map) {
    return CreatorSupportBundle(
      id: map['id'] as String,
      creatorId: map['creatorId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      items: List<String>.from(map['items'] ?? []),
      price: (map['price'] as num).toDouble(),
      creatorShare: (map['creatorShare'] as num).toDouble(),
      isLimitedTime: map['isLimitedTime'] as bool? ?? false,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
    );
  }
}

/// Engine for managing personalized offers
class OfferEngine {
  static OfferEngine? _instance;
  static OfferEngine get instance => _instance ??= OfferEngine._();

  OfferEngine._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _offersCollection =>
      _firestore.collection('personalized_offers');

  CollectionReference<Map<String, dynamic>> get _bundlesCollection =>
      _firestore.collection('creator_bundles');

  CollectionReference<Map<String, dynamic>> get _churnRiskCollection =>
      _firestore.collection('churn_risk_assessments');

  // Cache
  final Map<String, List<PersonalizedOffer>> _userOffers = {};
  final Map<String, ChurnRisk> _churnRiskCache = {};

  // Stream controllers
  final _offerController = StreamController<PersonalizedOffer>.broadcast();

  /// Stream of new offers
  Stream<PersonalizedOffer> get offerStream => _offerController.stream;

  /// Initialize the engine
  Future<void> initialize() async {
    AnalyticsService.instance.logEvent(
      name: 'offer_engine_initialized',
      parameters: {},
    );
  }

  /// Generate personalized offers for a user
  Future<List<PersonalizedOffer>> personalizedOffers({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    // Check cache
    if (_userOffers.containsKey(uid)) {
      final cached = _userOffers[uid]!.where((o) => o.isActive).toList();
      if (cached.isNotEmpty) return cached;
    }

    // Load existing active offers
    final existingOffers = await _loadUserOffers(uid);
    if (existingOffers.isNotEmpty) {
      _userOffers[uid] = existingOffers;
      return existingOffers.where((o) => o.isActive).toList();
    }

    // Generate new offers based on user behavior
    final offers = await _generatePersonalizedOffers(uid);
    _userOffers[uid] = offers;

    for (final offer in offers) {
      _offerController.add(offer);
    }

    AnalyticsService.instance.logEvent(
      name: 'personalized_offers_generated',
      parameters: {
        'user_id': uid,
        'offer_count': offers.length,
      },
    );

    return offers;
  }

  /// Generate churn prevention offers
  Future<PersonalizedOffer?> churnPreventionOffers({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;

    // Assess churn risk
    final churnRisk = await _assessChurnRisk(uid);
    if (churnRisk.level == ChurnRiskLevel.low) return null;

    // Generate offer based on risk level
    final offer = await _generateChurnPreventionOffer(uid, churnRisk);
    if (offer == null) return null;

    // Save the offer
    await _offersCollection.doc(offer.id).set(offer.toMap());
    _userOffers[uid] = [...(_userOffers[uid] ?? []), offer];
    _offerController.add(offer);

    AnalyticsService.instance.logEvent(
      name: 'churn_prevention_offer_created',
      parameters: {
        'user_id': uid,
        'risk_level': churnRisk.level.name,
        'discount': offer.discountPercent,
      },
    );

    return offer;
  }

  /// Create support bundles for creators
  Future<CreatorSupportBundle> creatorSupportBundles({
    required String creatorId,
    required String name,
    required String description,
    required List<String> items,
    required double price,
    double creatorSharePercent = 0.80,
    bool limitedTime = false,
    Duration? duration,
  }) async {
    final docRef = _bundlesCollection.doc();

    final bundle = CreatorSupportBundle(
      id: docRef.id,
      creatorId: creatorId,
      name: name,
      description: description,
      items: items,
      price: price,
      creatorShare: price * creatorSharePercent,
      isLimitedTime: limitedTime,
      expiresAt:
          limitedTime && duration != null ? DateTime.now().add(duration) : null,
    );

    await docRef.set(bundle.toMap());

    AnalyticsService.instance.logEvent(
      name: 'creator_bundle_created',
      parameters: {
        'creator_id': creatorId,
        'bundle_name': name,
        'price': price,
      },
    );

    return bundle;
  }

  /// Generate event-based offers
  Future<List<PersonalizedOffer>> eventBasedOffers({
    required String eventId,
    required String eventName,
    double discountPercent = 0.20,
    Duration offerDuration = const Duration(days: 3),
  }) async {
    final offers = <PersonalizedOffer>[];

    // Get users who participated in the event
    final participantsSnapshot = await _firestore
        .collection('event_participants')
        .where('eventId', isEqualTo: eventId)
        .limit(1000)
        .get();

    for (final doc in participantsSnapshot.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId == null) continue;

      final offer = PersonalizedOffer(
        id: '${eventId}_${userId}_offer',
        userId: userId,
        type: OfferType.eventBased,
        title: '$eventName Special!',
        description:
            'Thank you for joining $eventName! Enjoy this exclusive discount.',
        originalPrice: 9.99,
        discountedPrice: 9.99 * (1 - discountPercent),
        discountPercent: discountPercent * 100,
        expiresAt: DateTime.now().add(offerDuration),
        metadata: {
          'eventId': eventId,
          'eventName': eventName,
        },
      );

      await _offersCollection.doc(offer.id).set(offer.toMap());
      offers.add(offer);
    }

    AnalyticsService.instance.logEvent(
      name: 'event_offers_created',
      parameters: {
        'event_id': eventId,
        'offer_count': offers.length,
      },
    );

    return offers;
  }

  /// Redeem an offer
  Future<bool> redeemOffer(String offerId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final offerDoc = await _offersCollection.doc(offerId).get();
    if (!offerDoc.exists) return false;

    final offer = PersonalizedOffer.fromMap(offerDoc.data()!);

    // Verify offer belongs to user and is active
    if (offer.userId != userId || !offer.isActive) return false;

    // Update offer status
    await _offersCollection.doc(offerId).update({
      'status': OfferStatus.redeemed.name,
      'redeemedAt': FieldValue.serverTimestamp(),
    });

    // Update cache
    _userOffers[userId]?.removeWhere((o) => o.id == offerId);

    AnalyticsService.instance.logEvent(
      name: 'offer_redeemed',
      parameters: {
        'offer_id': offerId,
        'offer_type': offer.type.name,
        'discount': offer.discountPercent,
      },
    );

    return true;
  }

  /// Dismiss an offer
  Future<bool> dismissOffer(String offerId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    await _offersCollection.doc(offerId).update({
      'status': OfferStatus.dismissed.name,
      'dismissedAt': FieldValue.serverTimestamp(),
    });

    _userOffers[userId]?.removeWhere((o) => o.id == offerId);

    AnalyticsService.instance.logEvent(
      name: 'offer_dismissed',
      parameters: {'offer_id': offerId},
    );

    return true;
  }

  /// Get creator's support bundles
  Future<List<CreatorSupportBundle>> getCreatorBundles(String creatorId) async {
    final snapshot =
        await _bundlesCollection.where('creatorId', isEqualTo: creatorId).get();

    return snapshot.docs
        .map((doc) => CreatorSupportBundle.fromMap(doc.data()))
        .toList();
  }

  /// Purchase a creator bundle
  Future<bool> purchaseCreatorBundle({
    required String bundleId,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return false;

    final bundleDoc = await _bundlesCollection.doc(bundleId).get();
    if (!bundleDoc.exists) return false;

    final bundle = CreatorSupportBundle.fromMap(bundleDoc.data()!);

    // Check if bundle is expired
    if (bundle.isLimitedTime &&
        bundle.expiresAt != null &&
        DateTime.now().isAfter(bundle.expiresAt!)) {
      return false;
    }

    // Get user balance
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final balance = (userDoc.data()?['coinBalance'] as num?)?.toDouble() ?? 0;

    if (balance < bundle.price) return false;

    // Process purchase
    final batch = _firestore.batch();

    // Deduct from buyer
    batch.update(_firestore.collection('users').doc(uid), {
      'coinBalance': FieldValue.increment(-bundle.price),
    });

    // Credit creator
    batch.update(_firestore.collection('creators').doc(bundle.creatorId), {
      'pendingBalance': FieldValue.increment(bundle.creatorShare),
      'totalEarnings': FieldValue.increment(bundle.creatorShare),
    });

    // Record purchase
    batch.set(_firestore.collection('bundle_purchases').doc(), {
      'bundleId': bundleId,
      'buyerId': uid,
      'creatorId': bundle.creatorId,
      'price': bundle.price,
      'creatorShare': bundle.creatorShare,
      'purchasedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    AnalyticsService.instance.logEvent(
      name: 'creator_bundle_purchased',
      parameters: {
        'bundle_id': bundleId,
        'creator_id': bundle.creatorId,
        'price': bundle.price,
      },
    );

    return true;
  }

  /// Get user's churn risk
  Future<ChurnRisk> getChurnRisk(String userId) async {
    if (_churnRiskCache.containsKey(userId)) {
      return _churnRiskCache[userId]!;
    }

    return _assessChurnRisk(userId);
  }

  // Private methods

  Future<List<PersonalizedOffer>> _loadUserOffers(String userId) async {
    final snapshot = await _offersCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: OfferStatus.active.name)
        .get();

    return snapshot.docs
        .map((doc) => PersonalizedOffer.fromMap(doc.data()))
        .where((o) => !o.isExpired)
        .toList();
  }

  Future<List<PersonalizedOffer>> _generatePersonalizedOffers(
      String userId) async {
    final offers = <PersonalizedOffer>[];

    // Get user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return offers;

    final userData = userDoc.data()!;
    final purchaseCount = (userData['purchaseCount'] as int?) ?? 0;
    final membershipTier = userData['membershipTier'] as String? ?? 'free';
    final lastPurchaseDate = userData['lastPurchaseDate'] != null
        ? (userData['lastPurchaseDate'] as Timestamp).toDate()
        : null;

    // First purchase offer for new users
    if (purchaseCount == 0) {
      offers.add(PersonalizedOffer(
        id: '${userId}_first_purchase',
        userId: userId,
        type: OfferType.firstPurchase,
        title: 'Welcome! Get 50% Off',
        description:
            'Make your first purchase and get 50% off any coin package!',
        originalPrice: 4.99,
        discountedPrice: 2.49,
        discountPercent: 50,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        productId: 'coins_medium',
      ));
    }

    // Loyalty offer for returning users
    if (purchaseCount >= 5 && membershipTier == 'free') {
      offers.add(PersonalizedOffer(
        id: '${userId}_upgrade_offer',
        userId: userId,
        type: OfferType.upgrade,
        title: 'Upgrade to VIP',
        description: 'As a valued user, get 25% off VIP membership!',
        originalPrice: 9.99,
        discountedPrice: 7.49,
        discountPercent: 25,
        expiresAt: DateTime.now().add(const Duration(days: 14)),
        productId: 'vip_monthly',
      ));
    }

    // Re-engagement offer if no recent purchase
    if (lastPurchaseDate != null) {
      final daysSinceLastPurchase =
          DateTime.now().difference(lastPurchaseDate).inDays;
      if (daysSinceLastPurchase > 30) {
        offers.add(PersonalizedOffer(
          id: '${userId}_reactivation',
          userId: userId,
          type: OfferType.winBack,
          title: 'We Miss You!',
          description: 'Come back and enjoy 30% off your next purchase!',
          originalPrice: 4.99,
          discountedPrice: 3.49,
          discountPercent: 30,
          expiresAt: DateTime.now().add(const Duration(days: 5)),
        ));
      }
    }

    // Save offers
    for (final offer in offers) {
      await _offersCollection.doc(offer.id).set(offer.toMap());
    }

    return offers;
  }

  Future<ChurnRisk> _assessChurnRisk(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return ChurnRisk(
        userId: userId,
        riskScore: 0.5,
        level: ChurnRiskLevel.medium,
        riskFactors: ['incomplete_profile'],
        assessedAt: DateTime.now(),
      );
    }

    final userData = userDoc.data()!;
    final riskFactors = <String>[];
    double riskScore = 0.0;

    // Check last activity
    final lastActive = userData['lastActive'] != null
        ? (userData['lastActive'] as Timestamp).toDate()
        : null;
    if (lastActive != null) {
      final daysSinceActive = DateTime.now().difference(lastActive).inDays;
      if (daysSinceActive > 30) {
        riskScore += 0.4;
        riskFactors.add('inactive_30_days');
      } else if (daysSinceActive > 14) {
        riskScore += 0.2;
        riskFactors.add('inactive_14_days');
      } else if (daysSinceActive > 7) {
        riskScore += 0.1;
        riskFactors.add('inactive_7_days');
      }
    }

    // Check engagement decline
    final engagementScore =
        (userData['engagementScore'] as num?)?.toDouble() ?? 0.5;
    if (engagementScore < 0.3) {
      riskScore += 0.3;
      riskFactors.add('low_engagement');
    } else if (engagementScore < 0.5) {
      riskScore += 0.15;
      riskFactors.add('declining_engagement');
    }

    // Check purchase history
    final purchaseCount = (userData['purchaseCount'] as int?) ?? 0;
    if (purchaseCount == 0) {
      riskScore += 0.1;
      riskFactors.add('no_purchases');
    } else {
      final lastPurchase = userData['lastPurchaseDate'] != null
          ? (userData['lastPurchaseDate'] as Timestamp).toDate()
          : null;
      if (lastPurchase != null) {
        final daysSincePurchase =
            DateTime.now().difference(lastPurchase).inDays;
        if (daysSincePurchase > 60) {
          riskScore += 0.2;
          riskFactors.add('no_recent_purchase');
        }
      }
    }

    // Check support tickets
    final openTickets = (userData['openSupportTickets'] as int?) ?? 0;
    if (openTickets > 0) {
      riskScore += 0.15 * openTickets.clamp(1, 3);
      riskFactors.add('has_support_issues');
    }

    riskScore = riskScore.clamp(0.0, 1.0);

    final churnRisk = ChurnRisk(
      userId: userId,
      riskScore: riskScore,
      level: ChurnRisk._levelFromScore(riskScore),
      riskFactors: riskFactors,
      assessedAt: DateTime.now(),
    );

    // Cache and store
    _churnRiskCache[userId] = churnRisk;
    await _churnRiskCollection.doc(userId).set({
      'userId': userId,
      'riskScore': riskScore,
      'riskFactors': riskFactors,
      'assessedAt': DateTime.now().toIso8601String(),
    });

    return churnRisk;
  }

  Future<PersonalizedOffer?> _generateChurnPreventionOffer(
    String userId,
    ChurnRisk churnRisk,
  ) async {
    double discount;
    String title;
    String description;
    Duration duration;

    switch (churnRisk.level) {
      case ChurnRiskLevel.critical:
        discount = 0.50;
        title = 'Special Offer Just For You!';
        description =
            'We noticed you haven\'t been around. Here\'s 50% off to welcome you back!';
        duration = const Duration(days: 3);
        break;
      case ChurnRiskLevel.high:
        discount = 0.35;
        title = 'Exclusive Discount';
        description = 'Don\'t miss out on 35% off your favorite features!';
        duration = const Duration(days: 5);
        break;
      case ChurnRiskLevel.medium:
        discount = 0.20;
        title = 'Limited Time Offer';
        description = 'Enjoy 20% off on us!';
        duration = const Duration(days: 7);
        break;
      default:
        return null;
    }

    return PersonalizedOffer(
      id: '${userId}_churn_prevention_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: OfferType.churnPrevention,
      title: title,
      description: description,
      originalPrice: 9.99,
      discountedPrice: 9.99 * (1 - discount),
      discountPercent: discount * 100,
      expiresAt: DateTime.now().add(duration),
      metadata: {
        'churnRiskLevel': churnRisk.level.name,
        'riskScore': churnRisk.riskScore,
        'riskFactors': churnRisk.riskFactors,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _offerController.close();
  }
}
