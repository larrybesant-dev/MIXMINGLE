import 'package:flutter/material.dart';
import '../../services/ads/ad_service.dart';

/// Cross-platform house-ad banner.
///
/// Pass [placement] so the ad service can serve placement-appropriate content.
/// Renders nothing when ads are disabled via Remote Config.
class AdBannerWidget extends StatelessWidget {
  final AdPlacement placement;

  const AdBannerWidget({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    final ad = AdService.instance.nextAd(placement);
    if (ad == null) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey('ad_${ad.id}'),
      direction: DismissDirection.up,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purpleAccent.withValues(alpha: 0.15),
              Colors.blueAccent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ad.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(ad.body,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, ad.ctaRoute),
              child: Text(ad.ctaLabel,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
