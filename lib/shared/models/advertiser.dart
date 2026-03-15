// lib/shared/models/advertiser.dart
//
// Represents a paying (or promo) advertiser in the MixMingle ad platform.
// Firestore path: /advertisers/{advertiserId}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BillingStatus { paid, promo, free }

class Advertiser {
  final String id;
  final String name;
  final String website;
  final bool active;
  final BillingStatus billingStatus;
  final String? promoCode;
  final int impressionsRemaining;
  final int clicksRemaining;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Advertiser({
    required this.id,
    required this.name,
    required this.website,
    required this.active,
    required this.billingStatus,
    this.promoCode,
    required this.impressionsRemaining,
    required this.clicksRemaining,
    required this.createdAt,
    this.updatedAt,
  });

  // ── Firestore deserialization ─────────────────────────────────────────────

  factory Advertiser.fromMap(String id, Map<String, dynamic> data) {
    return Advertiser(
      id: id,
      name: data['name'] as String? ?? '',
      website: data['website'] as String? ?? '',
      active: data['active'] as bool? ?? false,
      billingStatus: _parseBillingStatus(data['billingStatus'] as String?),
      promoCode: data['promoCode'] as String?,
      impressionsRemaining: data['impressionsRemaining'] as int? ?? 0,
      clicksRemaining: data['clicksRemaining'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Advertiser.fromDoc(DocumentSnapshot doc) {
    return Advertiser.fromMap(doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'name': name,
        'website': website,
        'active': active,
        'billingStatus': billingStatus.name,
        'promoCode': promoCode,
        'impressionsRemaining': impressionsRemaining,
        'clicksRemaining': clicksRemaining,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get canServeAds {
    if (!active) return false;
    if (billingStatus == BillingStatus.free) return true;
    return impressionsRemaining > 0;
  }

  Advertiser copyWith({
    String? name,
    String? website,
    bool? active,
    BillingStatus? billingStatus,
    String? promoCode,
    int? impressionsRemaining,
    int? clicksRemaining,
    DateTime? updatedAt,
  }) {
    return Advertiser(
      id: id,
      name: name ?? this.name,
      website: website ?? this.website,
      active: active ?? this.active,
      billingStatus: billingStatus ?? this.billingStatus,
      promoCode: promoCode ?? this.promoCode,
      impressionsRemaining: impressionsRemaining ?? this.impressionsRemaining,
      clicksRemaining: clicksRemaining ?? this.clicksRemaining,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static BillingStatus _parseBillingStatus(String? value) {
    switch (value) {
      case 'paid':
        return BillingStatus.paid;
      case 'promo':
        return BillingStatus.promo;
      case 'free':
        return BillingStatus.free;
      default:
        return BillingStatus.paid;
    }
  }
}
