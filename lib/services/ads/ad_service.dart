import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Ad placement contexts.
enum AdPlacement { feed, roomBanner, profilePage }

/// A house ad — an internal promotional banner shown when no external ad is
/// configured. Entirely cross-platform (web, Windows, Android).
class HouseAd {
  final String id;
  final String title;
  final String body;
  final String ctaLabel;
  final String ctaRoute;
  final bool isActive;

  const HouseAd({
    required this.id,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaRoute,
    this.isActive = true,
  });
}

/// Default house ads — always visible even without a remote config fetch.
const List<HouseAd> kDefaultHouseAds = [
  HouseAd(
    id: 'premium_promo',
    title: '✨ Go Premium',
    body: 'Unlimited rooms, exclusive badges & more.',
    ctaLabel: 'Upgrade',
    ctaRoute: '/wallet',
  ),
  HouseAd(
    id: 'coins_promo',
    title: '🪙 Get Coins',
    body: 'Gift your favourite hosts and boost your profile.',
    ctaLabel: 'Buy Coins',
    ctaRoute: '/buy-coins',
  ),
  HouseAd(
    id: 'room_promo',
    title: '🎙️ Go Live',
    body: 'Start your own live room — it\'s free!',
    ctaLabel: 'Go Live',
    ctaRoute: '/go-live',
  ),
  HouseAd(
    id: 'discover_promo',
    title: '🔍 Discover People',
    body: 'Find your vibe — browse trending rooms & creators.',
    ctaLabel: 'Explore',
    ctaRoute: '/discover-rooms',
  ),
];

/// Platform-agnostic ad service.
///
/// Reads `ads_enabled` and `feed_ad_interval` from Firebase Remote Config.
/// Falls back to house ads when external ads are unavailable or disabled.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _adsEnabled = true;
  int _feedAdInterval = 5; // show an ad every N feed items
  List<HouseAd> _currentAds = List.of(kDefaultHouseAds);
  int _adIndex = 0;

  bool get adsEnabled => _adsEnabled;
  int get feedAdInterval => _feedAdInterval;

  /// Call once at app startup.
  Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      _adsEnabled = rc.getBool('ads_enabled');
      final interval = rc.getInt('feed_ad_interval');
      if (interval > 0) _feedAdInterval = interval.clamp(3, 20);
    } catch (e) {
      debugPrint('AdService.init: remote config unavailable — using defaults.');
    }
  }

  /// Returns the next house ad in round-robin rotation, or null if ads are off.
  HouseAd? nextAd(AdPlacement placement) {
    if (!_adsEnabled || _currentAds.isEmpty) return null;
    final ad = _currentAds[_adIndex % _currentAds.length];
    _adIndex++;
    return ad;
  }

  /// Returns true if the feed item at [index] should be replaced with an ad.
  bool showAdAtFeedIndex(int index) =>
      _adsEnabled && index > 0 && index % _feedAdInterval == 0;

  /// Allows the admin panel to override the current ad list at runtime.
  void overrideAds(List<HouseAd> ads) {
    _currentAds = ads.isNotEmpty ? ads : List.of(kDefaultHouseAds);
  }
}
