/// Monetization Strategy Service
///
/// Manages VIP upsells, limited-time offers, and behavior-based
/// monetization prompts to drive conversions.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing monetization strategies and VIP conversions
class MonetizationStrategy {
  static MonetizationStrategy? _instance;
  static MonetizationStrategy get instance =>
      _instance ??= MonetizationStrategy._();

  MonetizationStrategy._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Offer cooldown durations
  static const Duration _vipUpsellCooldown = Duration(hours: 24);
  static const Duration _limitedOfferCooldown = Duration(days: 3);

  // ============================================================
  // VIP UPSELLS
  // ============================================================

  /// Check if VIP upsell should be shown
  /// Returns an upsell offer if conditions are met
  Future<VipUpsellOffer?> showVipUpsell(
    String userId,
    UpsellTrigger trigger,
  ) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return null;

      // Check if already VIP
      final membershipTier = userData['membershipTier'] ?? 'free';
      if (membershipTier == 'vip' || membershipTier == 'vip_plus') {
        return null;
      }

      // Check cooldown
      final upsellsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('monetization')
          .doc('upsells');

      final upsellsDoc = await upsellsRef.get();
      if (upsellsDoc.exists) {
        final lastVipUpsell = upsellsDoc.data()?['lastVipUpsell'] as Timestamp?;
        if (lastVipUpsell != null) {
          final timeSince = DateTime.now().difference(lastVipUpsell.toDate());
          if (timeSince < _vipUpsellCooldown) {
            return null;
          }
        }
      }

      // Create appropriate offer based on trigger
      final offer = _createVipUpsellOffer(trigger, userData);

      if (offer != null) {
        // Record upsell shown
        await upsellsRef.set({
          'lastVipUpsell': FieldValue.serverTimestamp(),
          'lastTrigger': trigger.name,
          'vipUpsellCount': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // Track analytics
        await _analytics.logEvent(
          name: 'vip_upsell_shown',
          parameters: {
            'user_id': userId,
            'trigger': trigger.name,
            'offer_type': offer.offerType,
          },
        );
      }

      return offer;
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to show VIP upsell: $e');
      return null;
    }
  }

  /// Check if VIP+ upsell should be shown (for existing VIP members)
  Future<VipPlusUpsellOffer?> showVipPlusUpsell(
    String userId,
    UpsellTrigger trigger,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return null;

      // Only show to VIP members
      final membershipTier = userData['membershipTier'] ?? 'free';
      if (membershipTier != 'vip') {
        return null;
      }

      // Check cooldown
      final upsellsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('monetization')
          .doc('upsells');

      final upsellsDoc = await upsellsRef.get();
      if (upsellsDoc.exists) {
        final lastUpgrade = upsellsDoc.data()?['lastVipPlusUpsell'] as Timestamp?;
        if (lastUpgrade != null) {
          final timeSince = DateTime.now().difference(lastUpgrade.toDate());
          if (timeSince < _vipUpsellCooldown) {
            return null;
          }
        }
      }

      const offer = VipPlusUpsellOffer(
        title: 'Upgrade to VIP+ ðŸ‘‘',
        subtitle: 'Unlock the ultimate experience',
        benefits: [
          'Unlimited room creation',
          'Priority matching',
          'Exclusive VIP+ badge',
          '150 bonus coins/week',
          'Ad-free experience',
          'Custom profile themes',
        ],
        monthlyPrice: 19.99,
        yearlyPrice: 149.99,
        savingsPercent: 38,
      );

      // Record upsell
      await upsellsRef.set({
        'lastVipPlusUpsell': FieldValue.serverTimestamp(),
        'vipPlusUpsellCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _analytics.logEvent(
        name: 'vip_plus_upsell_shown',
        parameters: {
          'user_id': userId,
          'trigger': trigger.name,
        },
      );

      return offer;
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to show VIP+ upsell: $e');
      return null;
    }
  }

  // ============================================================
  // LIMITED TIME OFFERS
  // ============================================================

  /// Create and show a limited-time offer
  Future<LimitedTimeOffer?> limitedTimeOffer(
    String userId, {
    required OfferType offerType,
    int? discountPercent,
    Duration? duration,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return null;

      // Check if user is eligible
      final membershipTier = userData['membershipTier'] ?? 'free';
      if (membershipTier == 'vip_plus' && offerType != OfferType.coinBundle) {
        return null; // VIP+ doesn't need membership offers
      }

      // Check cooldown
      final offersRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('monetization')
          .doc('limited_offers');

      final offersDoc = await offersRef.get();
      if (offersDoc.exists) {
        final lastOffer = offersDoc.data()?['lastLimitedOffer'] as Timestamp?;
        if (lastOffer != null) {
          final timeSince = DateTime.now().difference(lastOffer.toDate());
          if (timeSince < _limitedOfferCooldown) {
            return null;
          }
        }
      }

      // Create offer
      final discount = discountPercent ?? 30;
      final offerDuration = duration ?? const Duration(hours: 24);
      final expiresAt = DateTime.now().add(offerDuration);

      final offer = LimitedTimeOffer(
        id: '${offerType.name}_${DateTime.now().millisecondsSinceEpoch}',
        type: offerType,
        title: _getOfferTitle(offerType, discount),
        description: _getOfferDescription(offerType),
        discountPercent: discount,
        expiresAt: expiresAt,
        originalPrice: _getOriginalPrice(offerType),
        discountedPrice: _getDiscountedPrice(offerType, discount),
      );

      // Store offer in Firestore
      await offersRef.set({
        'lastLimitedOffer': FieldValue.serverTimestamp(),
        'currentOffer': offer.toMap(),
        'limitedOfferCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _analytics.logEvent(
        name: 'limited_offer_created',
        parameters: {
          'user_id': userId,
          'offer_type': offerType.name,
          'discount_percent': discount,
        },
      );

      return offer;
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to create limited offer: $e');
      return null;
    }
  }

  // ============================================================
  // BEHAVIOR-BASED OFFERS
  // ============================================================

  /// Show behavior-based offer based on user actions
  Future<BehaviorOffer?> behaviorBasedOffer(
    String userId,
    UserBehavior behavior,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return null;

      final membershipTier = userData['membershipTier'] ?? 'free';

      // Determine offer based on behavior
      BehaviorOffer? offer;

      switch (behavior) {
        case UserBehavior.triedVipRoomAccess:
          if (membershipTier == 'free') {
            await _trackVipRoomAttempt(userId);
            offer = const BehaviorOffer(
              type: BehaviorOfferType.vipRoomAccess,
              title: 'Want to join VIP rooms? ðŸŒŸ',
              message: 'Upgrade to VIP to access exclusive rooms with top creators!',
              ctaLabel: 'Unlock VIP Rooms',
              ctaRoute: '/membership',
              discount: 20,
            );
          }
          break;

        case UserBehavior.ranOutOfCoins:
          offer = const BehaviorOffer(
            type: BehaviorOfferType.coinBundle,
            title: 'Running low on coins? ðŸ’°',
            message: 'Get a special bonus with your next coin purchase!',
            ctaLabel: 'Get Coins',
            ctaRoute: '/coin-store',
            bonusPercent: 25,
          );
          break;

        case UserBehavior.frequentHosting:
          if (membershipTier == 'free') {
            offer = const BehaviorOffer(
              type: BehaviorOfferType.creatorPerk,
              title: 'You\'re a natural host! ðŸŽ¤',
              message: 'VIP members get unlimited room creation and creator tools.',
              ctaLabel: 'Become VIP',
              ctaRoute: '/membership',
            );
          }
          break;

        case UserBehavior.highEngagement:
          if (membershipTier == 'free') {
            offer = const BehaviorOffer(
              type: BehaviorOfferType.engagementReward,
              title: 'You\'re loving Mix & Mingle! â¤ï¸',
              message: 'Here\'s a special offer just for you - 25% off VIP!',
              ctaLabel: 'Claim Offer',
              ctaRoute: '/membership',
              discount: 25,
            );
          }
          break;

        case UserBehavior.referredFriends:
          offer = const BehaviorOffer(
            type: BehaviorOfferType.referralBonus,
            title: 'Thanks for spreading the word! ðŸŽ‰',
            message: 'Enjoy bonus coins for your referrals!',
            ctaLabel: 'See Rewards',
            ctaRoute: '/referrals',
          );
          break;
      }

      if (offer != null) {
        await _analytics.logEvent(
          name: 'behavior_offer_shown',
          parameters: {
            'user_id': userId,
            'behavior': behavior.name,
            'offer_type': offer.type.name,
          },
        );
      }

      return offer;
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to create behavior offer: $e');
      return null;
    }
  }

  // ============================================================
  // ANALYTICS TRACKING
  // ============================================================

  /// Track VIP room access attempt
  Future<void> _trackVipRoomAttempt(String userId) async {
    try {
      await _analytics.logEvent(
        name: 'vip_room_attempt',
        parameters: {'user_id': userId},
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .doc('behavior')
          .set({
        'vipRoomAttempts': FieldValue.increment(1),
        'lastVipRoomAttempt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to track VIP room attempt: $e');
    }
  }

  /// Track membership upgrade started
  Future<void> trackMembershipUpgradeStarted(
    String userId,
    String targetTier,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'membership_upgrade_started',
        parameters: {
          'user_id': userId,
          'target_tier': targetTier,
        },
      );
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to track upgrade started: $e');
    }
  }

  /// Track membership upgraded
  Future<void> trackMembershipUpgraded(
    String userId,
    String previousTier,
    String newTier,
    double price,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'membership_upgraded',
        parameters: {
          'user_id': userId,
          'previous_tier': previousTier,
          'new_tier': newTier,
          'price': price,
        },
      );

      // Update monetization stats
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monetization')
          .doc('stats')
          .set({
        'totalUpgrades': FieldValue.increment(1),
        'lastUpgrade': FieldValue.serverTimestamp(),
        'lifetimeValue': FieldValue.increment(price),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('âŒ [Monetization] Failed to track upgrade: $e');
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  VipUpsellOffer? _createVipUpsellOffer(
    UpsellTrigger trigger,
    Map<String, dynamic> userData,
  ) {
    switch (trigger) {
      case UpsellTrigger.vipRoomBlocked:
        return const VipUpsellOffer(
          offerType: 'vip_room_access',
          title: 'Unlock VIP Rooms ðŸ”“',
          subtitle: 'Get access to exclusive creator rooms',
          benefits: [
            'Join VIP-only rooms',
            'Priority room access',
            'Exclusive VIP badge',
            '50 bonus coins/week',
          ],
          monthlyPrice: 9.99,
          yearlyPrice: 79.99,
          highlightBenefit: 'VIP Room Access',
        );

      case UpsellTrigger.roomLimitReached:
        return const VipUpsellOffer(
          offerType: 'unlimited_rooms',
          title: 'Create Unlimited Rooms ðŸŽ¤',
          subtitle: 'No more limits on your creativity',
          benefits: [
            'Unlimited room creation',
            'Priority in discovery',
            'Creator analytics',
            'VIP badge',
          ],
          monthlyPrice: 9.99,
          yearlyPrice: 79.99,
          highlightBenefit: 'Unlimited Rooms',
        );

      case UpsellTrigger.coinsLow:
        return const VipUpsellOffer(
          offerType: 'coin_bonus',
          title: 'Get Weekly Coin Bonus ðŸ’°',
          subtitle: 'Never run out of coins again',
          benefits: [
            '50 free coins every week',
            'Coin purchase bonuses',
            'VIP-only shop items',
            'Priority support',
          ],
          monthlyPrice: 9.99,
          yearlyPrice: 79.99,
          highlightBenefit: '50 Coins/Week',
        );

      case UpsellTrigger.profileCompletion:
        return const VipUpsellOffer(
          offerType: 'profile_boost',
          title: 'Stand Out from the Crowd âœ¨',
          subtitle: 'Get noticed with VIP profile features',
          benefits: [
            'VIP profile badge',
            'Custom profile colors',
            'Priority in discovery',
            'Profile analytics',
          ],
          monthlyPrice: 9.99,
          yearlyPrice: 79.99,
          highlightBenefit: 'VIP Badge',
        );

      case UpsellTrigger.afterPurchase:
        return const VipUpsellOffer(
          offerType: 'value_upgrade',
          title: 'Get More for Your Money ðŸŒŸ',
          subtitle: 'VIP members save on every purchase',
          benefits: [
            '15% bonus on all coin purchases',
            'Exclusive discounts',
            'Early access to new features',
            'Priority support',
          ],
          monthlyPrice: 9.99,
          yearlyPrice: 79.99,
          highlightBenefit: '15% Coin Bonus',
        );

      case UpsellTrigger.general:
        return const VipUpsellOffer(
          offerType: 'general',
          title: 'Upgrade to VIP ðŸŒŸ',
          subtitle: 'Unlock the full Mix & Mingle experience',
          benefits: [
            'VIP-only rooms',
            'Unlimited room creation',
            '50 coins/week',
            'Exclusive badge',
          ],
          monthlyPrice: 9.99,
          yearlyPrice: 79.99,
        );
    }
  }

  String _getOfferTitle(OfferType type, int discount) {
    switch (type) {
      case OfferType.vipMonthly:
        return '$discount% off VIP Monthly! ðŸŽ‰';
      case OfferType.vipYearly:
        return '$discount% off VIP Yearly! ðŸŽ‰';
      case OfferType.vipPlusMonthly:
        return '$discount% off VIP+ Monthly! ðŸ‘‘';
      case OfferType.vipPlusYearly:
        return '$discount% off VIP+ Yearly! ðŸ‘‘';
      case OfferType.coinBundle:
        return '$discount% Bonus Coins! ðŸ’°';
    }
  }

  String _getOfferDescription(OfferType type) {
    switch (type) {
      case OfferType.vipMonthly:
      case OfferType.vipYearly:
        return 'Limited time offer - unlock all VIP features!';
      case OfferType.vipPlusMonthly:
      case OfferType.vipPlusYearly:
        return 'The ultimate Mix & Mingle experience awaits!';
      case OfferType.coinBundle:
        return 'Get extra coins with your purchase!';
    }
  }

  double _getOriginalPrice(OfferType type) {
    switch (type) {
      case OfferType.vipMonthly:
        return 9.99;
      case OfferType.vipYearly:
        return 79.99;
      case OfferType.vipPlusMonthly:
        return 19.99;
      case OfferType.vipPlusYearly:
        return 149.99;
      case OfferType.coinBundle:
        return 4.99;
    }
  }

  double _getDiscountedPrice(OfferType type, int discount) {
    final original = _getOriginalPrice(type);
    return (original * (1 - discount / 100) * 100).round() / 100;
  }
}

// ============================================================
// ENUMS
// ============================================================

enum UpsellTrigger {
  vipRoomBlocked,
  roomLimitReached,
  coinsLow,
  profileCompletion,
  afterPurchase,
  general,
}

enum OfferType {
  vipMonthly,
  vipYearly,
  vipPlusMonthly,
  vipPlusYearly,
  coinBundle,
}

enum UserBehavior {
  triedVipRoomAccess,
  ranOutOfCoins,
  frequentHosting,
  highEngagement,
  referredFriends,
}

enum BehaviorOfferType {
  vipRoomAccess,
  coinBundle,
  creatorPerk,
  engagementReward,
  referralBonus,
}

// ============================================================
// DATA CLASSES
// ============================================================

class VipUpsellOffer {
  final String offerType;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final double monthlyPrice;
  final double yearlyPrice;
  final String? highlightBenefit;

  const VipUpsellOffer({
    required this.offerType,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.highlightBenefit,
  });

  int get yearlySavingsPercent =>
      (100 - (yearlyPrice / (monthlyPrice * 12) * 100)).round();
}

class VipPlusUpsellOffer {
  final String title;
  final String subtitle;
  final List<String> benefits;
  final double monthlyPrice;
  final double yearlyPrice;
  final int savingsPercent;

  const VipPlusUpsellOffer({
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.savingsPercent,
  });
}

class LimitedTimeOffer {
  final String id;
  final OfferType type;
  final String title;
  final String description;
  final int discountPercent;
  final DateTime expiresAt;
  final double originalPrice;
  final double discountedPrice;

  const LimitedTimeOffer({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.discountPercent,
    required this.expiresAt,
    required this.originalPrice,
    required this.discountedPrice,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'discountPercent': discountPercent,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
    };
  }
}

class BehaviorOffer {
  final BehaviorOfferType type;
  final String title;
  final String message;
  final String ctaLabel;
  final String ctaRoute;
  final int? discount;
  final int? bonusPercent;

  const BehaviorOffer({
    required this.type,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.ctaRoute,
    this.discount,
    this.bonusPercent,
  });
}
