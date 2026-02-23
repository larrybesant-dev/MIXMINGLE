
import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription tiers available in the app
enum SubscriptionTier {
  basic,
  premium,
  vip,
}

/// Subscription duration options
enum SubscriptionDuration {
  monthly,
  quarterly,
  yearly,
}

/// Subscription status
enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  paused,
}

/// A subscription package that users can purchase
class SubscriptionPackage {
  final String id;
  final SubscriptionTier tier;
  final SubscriptionDuration duration;
  final double price;
  final List<String> features;

  SubscriptionPackage({
    required this.id,
    required this.tier,
    required this.duration,
    required this.price,
    required this.features,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tier': tier.toString().split('.').last,
      'duration': duration.toString().split('.').last,
      'price': price,
      'features': features,
    };
  }

  factory SubscriptionPackage.fromMap(Map<String, dynamic> map) {
    return SubscriptionPackage(
      id: map['id'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.toString().split('.').last == map['tier'],
        orElse: () => SubscriptionTier.basic,
      ),
      duration: SubscriptionDuration.values.firstWhere(
        (e) => e.toString().split('.').last == map['duration'],
        orElse: () => SubscriptionDuration.monthly,
      ),
      price: (map['price'] ?? 0.0).toDouble(),
      features: List<String>.from(map['features'] ?? []),
    );
  }
}

/// A user's active subscription
class UserSubscription {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final bool autoRenew;
  final double price;
  final String paymentMethod;
  final DateTime? cancelledAt;
  final DateTime? renewedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.autoRenew,
    required this.price,
    required this.paymentMethod,
    this.cancelledAt,
    this.renewedAt,
  });

  bool get isActive => status == SubscriptionStatus.active && endDate.isAfter(DateTime.now());

  int get daysRemaining => endDate.difference(DateTime.now()).inDays.clamp(0, 999);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tier': tier.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.toString().split('.').last,
      'autoRenew': autoRenew,
      'price': price,
      'paymentMethod': paymentMethod,
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (renewedAt != null) 'renewedAt': Timestamp.fromDate(renewedAt!),
    };
  }

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.toString().split('.').last == map['tier'],
        orElse: () => SubscriptionTier.basic,
      ),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      autoRenew: map['autoRenew'] ?? true,
      price: (map['price'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'stripe',
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      renewedAt: (map['renewedAt'] as Timestamp?)?.toDate(),
    );
  }

  UserSubscription copyWith({
    String? id,
    String? userId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    bool? autoRenew,
    double? price,
    String? paymentMethod,
    DateTime? cancelledAt,
    DateTime? renewedAt,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      autoRenew: autoRenew ?? this.autoRenew,
      price: price ?? this.price,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      renewedAt: renewedAt ?? this.renewedAt,
    );
  }
}


