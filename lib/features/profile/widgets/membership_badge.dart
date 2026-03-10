
import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

/// Membership tier levels used across the app.
enum MembershipTier {
  free,
  vip,
  vipPlus;

  /// Parse from raw Firestore string value.
  static MembershipTier fromString(String? value) {
    switch (value) {
      case 'vip':
        return MembershipTier.vip;
      case 'vip_plus':
        return MembershipTier.vipPlus;
      default:
        return MembershipTier.free;
    }
  }

  String get label {
    switch (this) {
      case MembershipTier.free:
        return 'FREE';
      case MembershipTier.vip:
        return 'VIP';
      case MembershipTier.vipPlus:
        return 'VIP+';
    }
  }

  IconData get icon {
    switch (this) {
      case MembershipTier.free:
        return Icons.person_outline;
      case MembershipTier.vip:
        return Icons.star;
      case MembershipTier.vipPlus:
        return Icons.auto_awesome;
    }
  }

  Color get color {
    switch (this) {
      case MembershipTier.free:
        return DesignColors.textSecondary;
      case MembershipTier.vip:
        return DesignColors.gold;
      case MembershipTier.vipPlus:
        return DesignColors.tertiary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case MembershipTier.free:
        return DesignColors.surfaceLight;
      case MembershipTier.vip:
        return DesignColors.goldDark.withValues(alpha: 0.2);
      case MembershipTier.vipPlus:
        return DesignColors.tertiaryDark.withValues(alpha: 0.2);
    }
  }

  List<Shadow>? get glow {
    switch (this) {
      case MembershipTier.free:
        return null;
      case MembershipTier.vip:
        return const [
          Shadow(color: DesignColors.gold, blurRadius: 8, offset: Offset(0, 0)),
        ];
      case MembershipTier.vipPlus:
        return DesignColors.tertiaryGlow;
    }
  }
}

/// Size variants for the badge.
enum MembershipBadgeSize { small, medium, large }

/// Displays a styled membership tier badge (FREE / VIP / VIP+).
///
/// Usage:
/// ```dart
/// MembershipBadge(tier: MembershipTier.vip)
/// MembershipBadge.fromString('vip_plus')
/// MembershipBadge(tier: MembershipTier.vipPlus, size: MembershipBadgeSize.large)
/// ```
class MembershipBadge extends StatelessWidget {
  final MembershipTier tier;
  final MembershipBadgeSize size;

  /// Whether to show the icon alongside the label.
  final bool showIcon;

  const MembershipBadge({
    required this.tier,
    this.size = MembershipBadgeSize.medium,
    this.showIcon = true,
    super.key,
  });

  /// Convenience constructor that parses tier from a raw string.
  factory MembershipBadge.fromString(
    String? tierString, {
    MembershipBadgeSize size = MembershipBadgeSize.medium,
    bool showIcon = true,
    Key? key,
  }) {
    return MembershipBadge(
      tier: MembershipTier.fromString(tierString),
      size: size,
      showIcon: showIcon,
      key: key,
    );
  }

  double get _fontSize {
    switch (size) {
      case MembershipBadgeSize.small:
        return 9;
      case MembershipBadgeSize.medium:
        return 11;
      case MembershipBadgeSize.large:
        return 13;
    }
  }

  double get _iconSize {
    switch (size) {
      case MembershipBadgeSize.small:
        return 10;
      case MembershipBadgeSize.medium:
        return 12;
      case MembershipBadgeSize.large:
        return 14;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case MembershipBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 5, vertical: 2);
      case MembershipBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 7, vertical: 3);
      case MembershipBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything for free tier if icon hidden — keeps layouts clean.
    if (tier == MembershipTier.free && !showIcon) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: tier.backgroundColor,
        borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
        border: Border.all(
          color: tier.color.withValues(alpha: tier == MembershipTier.free ? 0.3 : 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              tier.icon,
              size: _iconSize,
              color: tier.color,
              shadows: tier.glow,
            ),
            SizedBox(width: _fontSize * 0.3),
          ],
          Text(
            tier.label,
            style: DesignTypography.label.copyWith(
              fontSize: _fontSize,
              color: tier.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              shadows: tier.glow,
            ),
          ),
        ],
      ),
    );
  }
}



