// lib/services/ads/ads_service.dart
//
// Core monetization service for MixMingle's ad platform.
//
// Billing Rules:
//   paid        → decrements impressionsRemaining on each serve; stops when zero
//   promo       → decrements impressionsRemaining; reverts to paid when zero
//   free        → no decrement; unlimited until manually disabled
//
// All billing‑sensitive fields are write‑protected by Firestore rules.
// Only users with the `admin` custom claim can modify them server‑side.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/models/advertiser.dart';
import '../../shared/models/ad_entry.dart';
import '../../shared/models/promo_code.dart';

class AdsService {
  final FirebaseFirestore _db;

  AdsService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Collections ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _advertisers =>
      _db.collection('advertisers');

  CollectionReference<Map<String, dynamic>> get _ads =>
      _db.collection('ads');

  CollectionReference<Map<String, dynamic>> get _promoCodes =>
      _db.collection('promoCodes');

  // ══════════════════════════════════════════════════════════════════════════
  // AD SERVING
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns a weighted-random ad for the given [placement].
  /// Returns null if no ads are available.
  /// Pass [userIsAdult] to gate age-restricted creatives.
  Future<AdEntry?> getAdForPlacement(
    AdPlacement placement, {
    bool userIsAdult = false,
  }) async {
    try {
      final snap = await _ads
          .where('active', isEqualTo: true)
          .where('placement', arrayContains: placement.name)
          .get();

      final candidates = snap.docs
          .map((d) => AdEntry.fromDoc(d))
          .where((ad) {
            if (ad.ageRestricted && !userIsAdult) return false;
            return true;
          })
          .toList();

      if (candidates.isEmpty) return null;

      // Filter to only ads whose advertisers can still serve
      final eligible = <AdEntry>[];
      for (final ad in candidates) {
        final adv = await getAdvertiser(ad.advertiserId);
        if (adv != null && adv.canServeAds) {
          eligible.add(ad);
        }
      }

      if (eligible.isEmpty) return null;

      // Weighted random selection
      final selected = _weightedRandom(eligible);
      return selected;
    } catch (e, st) {
      AppLogger.error('AdsService.getAdForPlacement failed', e, st);
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IMPRESSION TRACKING
  // ══════════════════════════════════════════════════════════════════════════

  /// Call this when an ad is actually displayed on screen.
  Future<void> recordImpression(AdEntry ad) async {
    try {
      // 1 – increment the ad's own counter
      await _ads.doc(ad.id).update({
        'impressionCount': FieldValue.increment(1),
      });

      // 2 – apply billing logic to the advertiser
      await _applyImpressionBilling(ad.advertiserId);
    } catch (e, st) {
      AppLogger.error('AdsService.recordImpression failed', e, st);
    }
  }

  Future<void> _applyImpressionBilling(String advertiserId) async {
    final ref = _advertisers.doc(advertiserId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final adv = Advertiser.fromDoc(snap);

      if (adv.billingStatus == BillingStatus.free) {
        // No billing — unlimited impressions
        return;
      }

      final newCount = adv.impressionsRemaining - 1;

      if (newCount <= 0) {
        if (adv.billingStatus == BillingStatus.promo) {
          // Promo exhausted → flip to paid (no more free impressions)
          tx.update(ref, {
            'impressionsRemaining': 0,
            'billingStatus': BillingStatus.paid.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Paid exhausted → pause ads
          tx.update(ref, {
            'impressionsRemaining': 0,
            'active': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          // Also deactivate all their ads
          _pauseAllAdsForAdvertiser(advertiserId);
        }
      } else {
        tx.update(ref, {
          'impressionsRemaining': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLICK TRACKING
  // ══════════════════════════════════════════════════════════════════════════

  /// Call this when a user taps the ad CTA / link.
  Future<void> recordClick(AdEntry ad) async {
    try {
      await _ads.doc(ad.id).update({
        'clickCount': FieldValue.increment(1),
      });

      final ref = _advertisers.doc(ad.advertiserId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final adv = Advertiser.fromDoc(snap);
        if (adv.billingStatus == BillingStatus.free) return;
        if (adv.clicksRemaining > 0) {
          tx.update(ref, {
            'clicksRemaining': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e, st) {
      AppLogger.error('AdsService.recordClick failed', e, st);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROMO CODE REDEMPTION
  // ══════════════════════════════════════════════════════════════════════════

  /// Validates and redeems a promo code.
  /// Returns a [PromoRedemptionResult] with success/failure details.
  Future<PromoRedemptionResult> redeemPromoCode(String code) async {
    try {
      final snap = await _promoCodes.doc(code.toUpperCase()).get();
      if (!snap.exists) {
        return PromoRedemptionResult.failure('Invalid promo code.');
      }

      final promo = PromoCode.fromDoc(snap);

      if (!promo.canRedeem) {
        if (promo.isExpired) {
          return PromoRedemptionResult.failure('This promo code has expired.');
        }
        if (!promo.active) {
          return PromoRedemptionResult.failure('This promo code is no longer active.');
        }
        return PromoRedemptionResult.failure('This promo code has already been redeemed.');
      }

      final advRef = _advertisers.doc(promo.advertiserId);

      await _db.runTransaction((tx) async {
        // Mark promo as redeemed
        tx.update(_promoCodes.doc(code.toUpperCase()), {
          'redeemedAt': FieldValue.serverTimestamp(),
        });

        switch (promo.type) {
          case PromoType.free:
            tx.update(advRef, {
              'billingStatus': BillingStatus.free.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          case PromoType.impressions:
            tx.update(advRef, {
              'impressionsRemaining': FieldValue.increment(promo.value),
              'billingStatus': BillingStatus.promo.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          case PromoType.discount:
            // Discount type is informational — handled by billing/invoice flow
            tx.update(advRef, {
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
        }
      });

      return PromoRedemptionResult.success(promo);
    } catch (e, st) {
      AppLogger.error('AdsService.redeemPromoCode failed', e, st);
      return PromoRedemptionResult.failure('Something went wrong. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Creates or updates an advertiser document. Admin only.
  Future<void> upsertAdvertiser(Advertiser advertiser) async {
    await _advertisers.doc(advertiser.id).set(
          advertiser.toMap()..['updatedAt'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true),
        );
  }

  /// Creates or updates an ad entry document. Admin only.
  Future<void> upsertAd(AdEntry ad) async {
    await _ads.doc(ad.id).set(
          ad.toMap()..['updatedAt'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true),
        );
  }

  /// Creates a new promo code. Admin only.
  Future<void> createPromoCode(PromoCode promo) async {
    await _promoCodes
        .doc(promo.code.toUpperCase())
        .set(promo.toMap());
  }

  /// Pauses an advertiser and all their ads. Admin only.
  Future<void> pauseAdvertiser(String advertiserId) async {
    await _advertisers.doc(advertiserId).update({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _pauseAllAdsForAdvertiser(advertiserId);
  }

  /// Re-activates a paused advertiser. Admin only.
  Future<void> resumeAdvertiser(String advertiserId) async {
    await _advertisers.doc(advertiserId).update({
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Re-activate all their ads
    final snap = await _ads
        .where('advertiserId', isEqualTo: advertiserId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'active': true});
    }
    await batch.commit();
  }

  /// Top up impressions for a paid advertiser. Admin only.
  Future<void> addImpressions(String advertiserId, int count) async {
    await _advertisers.doc(advertiserId).update({
      'impressionsRemaining': FieldValue.increment(count),
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // READS
  // ══════════════════════════════════════════════════════════════════════════

  Future<Advertiser?> getAdvertiser(String id) async {
    final snap = await _advertisers.doc(id).get();
    if (!snap.exists) return null;
    return Advertiser.fromDoc(snap);
  }

  Stream<List<Advertiser>> watchAllAdvertisers() {
    return _advertisers
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Advertiser.fromDoc).toList());
  }

  Stream<List<AdEntry>> watchAllAds() {
    return _ads
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AdEntry.fromDoc).toList());
  }

  Stream<List<AdEntry>> watchAdsForAdvertiser(String advertiserId) {
    return _ads
        .where('advertiserId', isEqualTo: advertiserId)
        .snapshots()
        .map((s) => s.docs.map(AdEntry.fromDoc).toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pauseAllAdsForAdvertiser(String advertiserId) async {
    final snap =
        await _ads.where('advertiserId', isEqualTo: advertiserId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'active': false});
    }
    await batch.commit();
  }

  AdEntry _weightedRandom(List<AdEntry> ads) {
    final totalWeight = ads.fold<int>(0, (acc, ad) => acc + ad.weight);
    var pick = Random().nextInt(totalWeight);
    for (final ad in ads) {
      pick -= ad.weight;
      if (pick < 0) return ad;
    }
    return ads.last;
  }
}

// ── Result wrapper ─────────────────────────────────────────────────────────

class PromoRedemptionResult {
  final bool success;
  final String? errorMessage;
  final PromoCode? promo;

  const PromoRedemptionResult._({
    required this.success,
    this.errorMessage,
    this.promo,
  });

  factory PromoRedemptionResult.success(PromoCode promo) =>
      PromoRedemptionResult._(success: true, promo: promo);

  factory PromoRedemptionResult.failure(String message) =>
      PromoRedemptionResult._(success: false, errorMessage: message);
}
