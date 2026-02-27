// lib/shared/widgets/ad_tile_widget.dart
//
// Drop-in ad widget that:
//   1. Loads an AdEntry for the given placement
//   2. Records an impression once visible
//   3. Opens the ad URL in browser on tap (recording a click)
//   4. Silently disappears when there are no available ads
//
// Usage:
//   AdTileWidget(placement: AdPlacement.discover, userIsAdult: false)
//   AdBannerWidget(placement: AdPlacement.feed, userIsAdult: true)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_entry.dart';
import '../providers/ads_providers.dart';
import '../../core/utils/app_logger.dart';
import '../../core/analytics/analytics_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AD TILE  (square / card format — use in grid/list views)
// ═══════════════════════════════════════════════════════════════════════════

class AdTileWidget extends ConsumerStatefulWidget {
  final AdPlacement placement;
  final bool userIsAdult;

  const AdTileWidget({
    super.key,
    required this.placement,
    this.userIsAdult = false,
  });

  @override
  ConsumerState<AdTileWidget> createState() => _AdTileWidgetState();
}

class _AdTileWidgetState extends ConsumerState<AdTileWidget> {
  bool _impressionRecorded = false;

  void _recordImpression(AdEntry ad) {
    if (_impressionRecorded) return;
    _impressionRecorded = true;
    ref.read(adsServiceProvider).recordImpression(ad);
    AnalyticsService.instance.logAdImpression(
      adId: ad.id,
      advertiserId: ad.advertiserId,
      placement: widget.placement.name,
    );
  }

  Future<void> _handleTap(AdEntry ad) async {
    ref.read(adsServiceProvider).recordClick(ad);
    AnalyticsService.instance.logAdClick(
      adId: ad.id,
      advertiserId: ad.advertiserId,
      placement: widget.placement.name,
    );
    final uri = Uri.tryParse(ad.linkUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adAsync = ref.watch(
      adForPlacementProvider(
        AdPlacementQuery(
          placement: widget.placement,
          userIsAdult: widget.userIsAdult,
        ),
      ),
    );

    return adAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) {
        AppLogger.error('AdTileWidget failed to load ad', e, st);
        return const SizedBox.shrink();
      },
      data: (ad) {
        if (ad == null) return const SizedBox.shrink();
        _recordImpression(ad);
        return _AdTileCard(ad: ad, onTap: () => _handleTap(ad));
      },
    );
  }
}

class _AdTileCard extends StatelessWidget {
  final AdEntry ad;
  final VoidCallback onTap;

  const _AdTileCard({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF4C4C).withValues(alpha: 0.4),
            width: 1,
          ),
          color: Colors.black.withValues(alpha: 0.6),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.white38),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Sponsored label
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Sponsored',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Bottom content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad.headline != null)
                      Text(
                        ad.headline!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4C4C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ad.ctaLabel ?? 'Learn More',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AD BANNER (full-width horizontal strip — use between list items)
// ═══════════════════════════════════════════════════════════════════════════

class AdBannerWidget extends ConsumerStatefulWidget {
  final AdPlacement placement;
  final bool userIsAdult;
  final double height;

  const AdBannerWidget({
    super.key,
    required this.placement,
    this.userIsAdult = false,
    this.height = 80,
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  bool _impressionRecorded = false;

  void _recordImpression(AdEntry ad) {
    if (_impressionRecorded) return;
    _impressionRecorded = true;
    ref.read(adsServiceProvider).recordImpression(ad);
    AnalyticsService.instance.logAdImpression(
      adId: ad.id,
      advertiserId: ad.advertiserId,
      placement: widget.placement.name,
    );
  }

  Future<void> _handleTap(AdEntry ad) async {
    ref.read(adsServiceProvider).recordClick(ad);
    AnalyticsService.instance.logAdClick(
      adId: ad.id,
      advertiserId: ad.advertiserId,
      placement: widget.placement.name,
    );
    final uri = Uri.tryParse(ad.linkUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adAsync = ref.watch(
      adForPlacementProvider(
        AdPlacementQuery(
          placement: widget.placement,
          userIsAdult: widget.userIsAdult,
        ),
      ),
    );

    return adAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) {
        AppLogger.error('AdBannerWidget failed to load ad', e, st);
        return const SizedBox.shrink();
      },
      data: (ad) {
        if (ad == null) return const SizedBox.shrink();
        _recordImpression(ad);
        return GestureDetector(
          onTap: () => _handleTap(ad),
          child: Container(
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    ad.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[900]),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 8,
                  child: Text(
                    'AD',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (ad.headline != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ad.headline!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
