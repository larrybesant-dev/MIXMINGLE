/// Coin Package Model
///
/// Defines coin packages for purchase via RevenueCat consumables.
library;

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
import 'membership_tier.dart';

/// Coin package for purchasing coins
class CoinPackage {
  final String id;
  final String productId;
  final int coins;
  final String price;
  final double priceValue;
  final int? bonusCoins;
  final bool isPopular;
  final bool isVipPlusBonus;

  const CoinPackage({
    required this.id,
    required this.productId,
    required this.coins,
    required this.price,
    required this.priceValue,
    this.bonusCoins,
    this.isPopular = false,
    this.isVipPlusBonus = false,
  });

  /// Total coins including bonus
  int get totalCoins => coins + (bonusCoins ?? 0);

  /// Get total coins considering VIP+ status
  int getTotalCoins(bool isVipPlus) {
    final base = totalCoins;
    if (isVipPlus && isVipPlusBonus) {
      return base + (coins * 0.2).round(); // 20% extra for VIP+
    }
    return base;
  }

  /// VIP+ extra bonus coins
  int get vipPlusBonusCoins {
    if (isVipPlusBonus) {
      return (coins * 0.2).round();
    }
    return 0;
  }

  /// Display formatted price
  String get priceDisplay => price;

  /// Display name
  String get displayName {
    switch (coins) {
      case 100:
        return 'Starter Pack';
      case 500:
        return 'Popular Pack';
      case 1000:
        return 'Value Pack';
      case 5000:
        return 'Ultimate Pack';
      default:
        return '$coins Coins';
    }
  }

  /// Whether this is the best value package
  bool get isBestValue => id == 'coins_5000';

  /// Price per coin
  double get pricePerCoin => priceValue / totalCoins;

  /// Display value (e.g., "100 coins")
  String get displayValue {
    if (bonusCoins != null && bonusCoins! > 0) {
      return '$coins + $bonusCoins bonus';
    }
    return '$coins coins';
  }

  /// Icon color based on package size
  Color get iconColor {
    if (isVipPlusBonus) return DesignColors.gold;
    if (isPopular) return NeonColors.neonOrange;
    return NeonColors.neonBlue;
  }

  /// Glow color for the card
  Color get glowColor {
    if (isVipPlusBonus) return DesignColors.gold;
    if (isPopular) return NeonColors.neonOrange;
    return NeonColors.neonBlue.withValues(alpha: 0.5);
  }

  /// Get all available coin packages
  static List<CoinPackage> get allPackages => [
        small,
        medium,
        large,
        xlarge,
      ];

  /// 100 coins package
  static const small = CoinPackage(
    id: 'coins_100',
    productId: 'coins_100',
    coins: 100,
    price: '\$0.99',
    priceValue: 0.99,
  );

  /// 500 coins package
  static const medium = CoinPackage(
    id: 'coins_500',
    productId: 'coins_500',
    coins: 500,
    price: '\$4.99',
    priceValue: 4.99,
    bonusCoins: 50,
    isPopular: true,
  );

  /// 1000 coins package
  static const large = CoinPackage(
    id: 'coins_1000',
    productId: 'coins_1000',
    coins: 1000,
    price: '\$9.99',
    priceValue: 9.99,
    bonusCoins: 150,
  );

  /// 5000 coins package (VIP+ bonus eligible)
  static const xlarge = CoinPackage(
    id: 'coins_5000',
    productId: 'coins_5000',
    coins: 5000,
    price: '\$39.99',
    priceValue: 39.99,
    bonusCoins: 1000,
    isVipPlusBonus: true,
  );

  /// Get bonus coins for VIP+ members
  int getVipPlusBonusCoins(MembershipTier tier) {
    if (tier == MembershipTier.vipPlus && isVipPlusBonus) {
      return (coins * 0.2).round(); // Extra 20% for VIP+
    }
    return 0;
  }

  /// Calculate total coins including VIP+ bonus
  int getTotalCoinsForTier(MembershipTier tier) {
    return totalCoins + getVipPlusBonusCoins(tier);
  }
}

/// Coin balance model for tracking user's coins
class CoinBalance {
  final int balance;
  final DateTime lastUpdated;
  final List<CoinTransaction> recentTransactions;

  const CoinBalance({
    required this.balance,
    required this.lastUpdated,
    this.recentTransactions = const [],
  });

  factory CoinBalance.initial() => CoinBalance(
        balance: 0,
        lastUpdated: DateTime.now(),
      );

  CoinBalance copyWith({
    int? balance,
    DateTime? lastUpdated,
    List<CoinTransaction>? recentTransactions,
  }) {
    return CoinBalance(
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }

  /// Check if user can afford a purchase
  bool canAfford(int amount) => balance >= amount;

  /// Format balance for display
  String get displayBalance {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    }
    return balance.toString();
  }
}

/// Coin transaction record
class CoinTransaction {
  final String id;
  final CoinTransactionType type;
  final int amount;
  final String? description;
  final DateTime timestamp;
  final String? recipientId;
  final String? giftType;

  const CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.timestamp,
    this.recipientId,
    this.giftType,
  });

  factory CoinTransaction.fromFirestore(Map<String, dynamic> data, String id) {
    return CoinTransaction(
      id: id,
      type: CoinTransactionType.fromString(data['type'] ?? 'other'),
      amount: data['amount'] ?? 0,
      description: data['description'],
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      recipientId: data['recipientId'],
      giftType: data['giftType'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'amount': amount,
      'description': description,
      'timestamp': timestamp,
      'recipientId': recipientId,
      'giftType': giftType,
    };
  }

  /// Check if this is a credit (positive) transaction
  bool get isCredit =>
      type == CoinTransactionType.purchase ||
      type == CoinTransactionType.bonus ||
      type == CoinTransactionType.giftReceived ||
      type == CoinTransactionType.refund;

  /// Check if this is a debit (negative) transaction
  bool get isDebit =>
      type == CoinTransactionType.giftSent ||
      type == CoinTransactionType.spotlight ||
      type == CoinTransactionType.other;

  /// Get display color for the transaction
  Color get displayColor =>
      isCredit ? NeonColors.successGreen : NeonColors.errorRed;

  /// Get display icon
  IconData get displayIcon {
    switch (type) {
      case CoinTransactionType.purchase:
        return Icons.shopping_cart;
      case CoinTransactionType.bonus:
        return Icons.card_giftcard;
      case CoinTransactionType.giftSent:
        return Icons.favorite;
      case CoinTransactionType.giftReceived:
        return Icons.favorite_border;
      case CoinTransactionType.spotlight:
        return Icons.highlight;
      case CoinTransactionType.refund:
        return Icons.refresh;
      case CoinTransactionType.other:
        return Icons.monetization_on;
    }
  }
}

/// Types of coin transactions
enum CoinTransactionType {
  purchase,
  bonus,
  giftSent,
  giftReceived,
  spotlight,
  refund,
  other;

  String get value {
    switch (this) {
      case CoinTransactionType.purchase:
        return 'purchase';
      case CoinTransactionType.bonus:
        return 'bonus';
      case CoinTransactionType.giftSent:
        return 'gift_sent';
      case CoinTransactionType.giftReceived:
        return 'gift_received';
      case CoinTransactionType.spotlight:
        return 'spotlight';
      case CoinTransactionType.refund:
        return 'refund';
      case CoinTransactionType.other:
        return 'other';
    }
  }

  static CoinTransactionType fromString(String value) {
    switch (value) {
      case 'purchase':
        return CoinTransactionType.purchase;
      case 'bonus':
        return CoinTransactionType.bonus;
      case 'gift_sent':
        return CoinTransactionType.giftSent;
      case 'gift_received':
        return CoinTransactionType.giftReceived;
      case 'spotlight':
        return CoinTransactionType.spotlight;
      case 'refund':
        return CoinTransactionType.refund;
      default:
        return CoinTransactionType.other;
    }
  }

  String get displayName {
    switch (this) {
      case CoinTransactionType.purchase:
        return 'Purchased';
      case CoinTransactionType.bonus:
        return 'Bonus';
      case CoinTransactionType.giftSent:
        return 'Gift Sent';
      case CoinTransactionType.giftReceived:
        return 'Gift Received';
      case CoinTransactionType.spotlight:
        return 'Spotlight';
      case CoinTransactionType.refund:
        return 'Refund';
      case CoinTransactionType.other:
        return 'Other';
    }
  }

  /// Icon for the transaction type
  IconData get icon {
    switch (this) {
      case CoinTransactionType.purchase:
        return Icons.shopping_cart;
      case CoinTransactionType.bonus:
        return Icons.card_giftcard;
      case CoinTransactionType.giftSent:
        return Icons.favorite;
      case CoinTransactionType.giftReceived:
        return Icons.favorite_border;
      case CoinTransactionType.spotlight:
        return Icons.highlight;
      case CoinTransactionType.refund:
        return Icons.refresh;
      case CoinTransactionType.other:
        return Icons.monetization_on;
    }
  }
}
