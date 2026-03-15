// lib/shared/models/promo_code.dart
//
// A promo code that grants free or discounted ad campaigns.
// Firestore path: /promoCodes/{code}

import 'package:cloud_firestore/cloud_firestore.dart';

enum PromoType { free, discount, impressions }

class PromoCode {
  final String code;
  final String advertiserId;
  final PromoType type;

  /// Meaning depends on type:
  ///   free        → ignored (full free access)
  ///   discount    → percentage discount (0-100)
  ///   impressions → number of free impressions granted
  final int value;

  final DateTime expiresAt;
  final bool active;
  final DateTime? redeemedAt;

  const PromoCode({
    required this.code,
    required this.advertiserId,
    required this.type,
    required this.value,
    required this.expiresAt,
    required this.active,
    this.redeemedAt,
  });

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory PromoCode.fromMap(String code, Map<String, dynamic> data) {
    return PromoCode(
      code: code,
      advertiserId: data['advertiserId'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      value: data['value'] as int? ?? 0,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] as bool? ?? false,
      redeemedAt: (data['redeemedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PromoCode.fromDoc(DocumentSnapshot doc) =>
      PromoCode.fromMap(doc.id, doc.data() as Map<String, dynamic>? ?? {});

  Map<String, dynamic> toMap() => {
        'advertiserId': advertiserId,
        'type': type.name,
        'value': value,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'active': active,
        'redeemedAt':
            redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canRedeem => active && !isExpired && redeemedAt == null;

  static PromoType _parseType(String? v) {
    switch (v) {
      case 'discount':
        return PromoType.discount;
      case 'impressions':
        return PromoType.impressions;
      default:
        return PromoType.free;
    }
  }
}
