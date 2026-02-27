// lib/shared/providers/ads_providers.dart
//
// Riverpod providers for the MixMingle Ad Monetization system.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ads/ads_service.dart';
import '../models/advertiser.dart';
import '../models/ad_entry.dart';

// ── Service ───────────────────────────────────────────────────────────────

final adsServiceProvider = Provider<AdsService>((ref) => AdsService());

// ── Admin streams ─────────────────────────────────────────────────────────

/// All advertisers ordered by creation date (admin use).
final allAdvertisersProvider = StreamProvider<List<Advertiser>>((ref) {
  return ref.watch(adsServiceProvider).watchAllAdvertisers();
});

/// All ad entries ordered by creation date (admin use).
final allAdsProvider = StreamProvider<List<AdEntry>>((ref) {
  return ref.watch(adsServiceProvider).watchAllAds();
});

/// Ads belonging to a specific advertiser.
final advertiserAdsProvider =
    StreamProvider.family<List<AdEntry>, String>((ref, advertiserId) {
  return ref.watch(adsServiceProvider).watchAdsForAdvertiser(advertiserId);
});

// ── Ad serving ────────────────────────────────────────────────────────────

/// Fetches a single ad for a given placement.
/// The [userIsAdult] flag gates age-restricted creatives.
final adForPlacementProvider = FutureProvider.family<AdEntry?, AdPlacementQuery>(
  (ref, query) async {
    final service = ref.watch(adsServiceProvider);
    return service.getAdForPlacement(
      query.placement,
      userIsAdult: query.userIsAdult,
    );
  },
);

/// Query params for [adForPlacementProvider].
class AdPlacementQuery {
  final AdPlacement placement;
  final bool userIsAdult;

  const AdPlacementQuery({required this.placement, this.userIsAdult = false});

  @override
  bool operator ==(Object other) =>
      other is AdPlacementQuery &&
      other.placement == placement &&
      other.userIsAdult == userIsAdult;

  @override
  int get hashCode => Object.hash(placement, userIsAdult);
}

// ── Convenience helpers ───────────────────────────────────────────────────

/// Shorthand to get a discover-placement ad.
/// Usage: ref.watch(discoverAdProvider(isAdult))
final discoverAdProvider = FutureProvider.autoDispose.family<AdEntry?, bool>(
  (ref, isAdult) => ref.watch(adsServiceProvider).getAdForPlacement(
        AdPlacement.discover,
        userIsAdult: isAdult,
      ),
);

/// Shorthand to get a feed-placement ad.
final feedAdProvider = FutureProvider.autoDispose.family<AdEntry?, bool>(
  (ref, isAdult) => ref.watch(adsServiceProvider).getAdForPlacement(
        AdPlacement.feed,
        userIsAdult: isAdult,
      ),
);

// ── Impression / click actions ────────────────────────────────────────────

/// Record an impression. Fire-and-forget.
final recordImpressionProvider =
    FutureProvider.family<void, AdEntry>((ref, ad) async {
  await ref.watch(adsServiceProvider).recordImpression(ad);
});

/// Record a click. Fire-and-forget.
final recordClickProvider =
    FutureProvider.family<void, AdEntry>((ref, ad) async {
  await ref.watch(adsServiceProvider).recordClick(ad);
});

// ── Promo code ────────────────────────────────────────────────────────────

/// Redeems a promo code. Returns [PromoRedemptionResult].
final redeemPromoCodeProvider =
    FutureProvider.family<PromoRedemptionResult, String>((ref, code) async {
  return ref.watch(adsServiceProvider).redeemPromoCode(code);
});
