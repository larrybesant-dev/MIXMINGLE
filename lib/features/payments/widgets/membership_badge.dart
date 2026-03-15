/// Membership Badge Widget
///
/// Displays membership tier as a badge with neon styling.
/// Used in profile headers, room UI, and chat displays.
library;

import 'package:flutter/material.dart';
import '../models/membership_tier.dart';
import '../../../../core/design_system/design_constants.dart';

/// Membership badge sizes
enum MembershipBadgeSize {
  small,
  medium,
  large,
}

/// Membership badge widget with neon effect
class MembershipBadge extends StatelessWidget {
  final MembershipTier tier;
  final MembershipBadgeSize size;
  final bool showLabel;
  final bool animated;
  final VoidCallback? onTap;

  const MembershipBadge({
    super.key,
    required this.tier,
    this.size = MembershipBadgeSize.medium,
    this.showLabel = false,
    this.animated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show badge for free tier unless explicitly shown
    if (tier == MembershipTier.free) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: animated
          ? _AnimatedBadgeContent(tier: tier, size: size, showLabel: showLabel)
          : _BadgeContent(tier: tier, size: size, showLabel: showLabel),
    );
  }
}

class _BadgeContent extends StatelessWidget {
  final MembershipTier tier;
  final MembershipBadgeSize size;
  final bool showLabel;

  const _BadgeContent({
    required this.tier,
    required this.size,
    required this.showLabel,
  });

  double get _iconSize {
    switch (size) {
      case MembershipBadgeSize.small:
        return 12;
      case MembershipBadgeSize.medium:
        return 16;
      case MembershipBadgeSize.large:
        return 24;
    }
  }

  double get _fontSize {
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
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case MembershipBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case MembershipBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tier.primaryColor.withAlpha(51),
            tier.secondaryColor.withAlpha(51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.primaryColor.withAlpha(153),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.primaryColor.withAlpha(77),
            blurRadius: size == MembershipBadgeSize.large ? 12 : 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            color: tier.primaryColor,
            size: _iconSize,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              tier.displayName,
              style: TextStyle(
                color: tier.primaryColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedBadgeContent extends StatefulWidget {
  final MembershipTier tier;
  final MembershipBadgeSize size;
  final bool showLabel;

  const _AnimatedBadgeContent({
    required this.tier,
    required this.size,
    required this.showLabel,
  });

  @override
  State<_AnimatedBadgeContent> createState() => _AnimatedBadgeContentState();
}

class _AnimatedBadgeContentState extends State<_AnimatedBadgeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _iconSize {
    switch (widget.size) {
      case MembershipBadgeSize.small:
        return 12;
      case MembershipBadgeSize.medium:
        return 16;
      case MembershipBadgeSize.large:
        return 24;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case MembershipBadgeSize.small:
        return 10;
      case MembershipBadgeSize.medium:
        return 12;
      case MembershipBadgeSize.large:
        return 14;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case MembershipBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case MembershipBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case MembershipBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = _glowAnimation.value;
        return Container(
          padding: _padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.tier.primaryColor
                    .withAlpha((51 * glowIntensity * 2).round()),
                widget.tier.secondaryColor
                    .withAlpha((51 * glowIntensity * 2).round()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.tier.primaryColor
                  .withAlpha((153 + 50 * glowIntensity).round()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.tier.primaryColor
                    .withAlpha((77 + 50 * glowIntensity).round()),
                blurRadius: 8 + 8 * glowIntensity,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.tier.icon,
            color: widget.tier.primaryColor,
            size: _iconSize,
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 4),
            Text(
              widget.tier.displayName,
              style: TextStyle(
                color: widget.tier.primaryColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact badge for chat messages and lists
class CompactMembershipBadge extends StatelessWidget {
  final MembershipTier tier;

  const CompactMembershipBadge({
    super.key,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == MembershipTier.free) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: tier.primaryColor.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tier.primaryColor.withAlpha(102),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            color: tier.primaryColor,
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            tier == MembershipTier.vipPlus ? 'VIP+' : 'VIP',
            style: TextStyle(
              color: tier.primaryColor,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge with upgrade indicator
class UpgradeBadge extends StatelessWidget {
  final VoidCallback onTap;

  const UpgradeBadge({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignColors.gold.withAlpha(51),
              const Color(0xFFFF7A3C).withAlpha(51),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DesignColors.gold.withAlpha(179),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignColors.gold.withAlpha(51),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars_rounded,
              color: DesignColors.gold,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              'Upgrade',
              style: TextStyle(
                color: DesignColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
