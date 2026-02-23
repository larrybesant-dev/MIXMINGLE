import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors_v2.dart';
import '../theme/spacing.dart';

/// GlassCard: frosted glassmorphism container with neon edge highlights.
/// Elevation levels: low, medium, high.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.elevation = GlassCardElevation.low,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final GlassCardElevation elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleForElevation(elevation);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: ElectricColors.surfaceElevated.withValues(alpha: style.surfaceOpacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElectricColors.glassBorder.withValues(alpha: style.borderOpacity),
              width: 1.2,
            ),
            boxShadow: style.shadows,
            gradient: style.gradient,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;

    // Use GestureDetector instead of Material+InkWell to avoid infinite height issue
    // Trade-off: No ripple effect, but clickable and no layout errors
    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

enum GlassCardElevation { low, medium, high }

class _GlassStyle {
  const _GlassStyle({
    required this.surfaceOpacity,
    required this.borderOpacity,
    required this.gradient,
    required this.shadows,
  });

  final double surfaceOpacity;
  final double borderOpacity;
  final Gradient? gradient;
  final List<BoxShadow> shadows;
}

_GlassStyle _styleForElevation(GlassCardElevation level) {
  switch (level) {
    case GlassCardElevation.low:
      return const _GlassStyle(
        surfaceOpacity: 0.32,
        borderOpacity: 0.28,
        gradient: LinearGradient(
          colors: [
            Color(0x14FFFFFF), // subtle top highlight
            Color(0x05000000), // subtle bottom shadow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadows: [
          BoxShadow(
            color: ElectricColors.glassShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      );
    case GlassCardElevation.medium:
      return _GlassStyle(
        surfaceOpacity: 0.30,
        borderOpacity: 0.28,
        gradient: const LinearGradient(
          colors: [
            Color(0x22FFFFFF),
            Color(0x0A000000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadows: [
          BoxShadow(
            color: ElectricColors.neonMagenta.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: ElectricColors.glassShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      );
    case GlassCardElevation.high:
      return _GlassStyle(
        surfaceOpacity: 0.44,
        borderOpacity: 0.40,
        gradient: const LinearGradient(
          colors: [
            Color(0x33FFFFFF),
            Color(0x14000000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadows: [
          BoxShadow(
            color: ElectricColors.neonMagenta.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: ElectricColors.electricCyan.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: ElectricColors.glassShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      );
  }
}
