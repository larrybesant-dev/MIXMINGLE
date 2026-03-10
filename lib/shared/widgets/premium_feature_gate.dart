/// Premium Feature Gate Widget
///
/// Restricts access to premium features based on membership tier.
/// Shows upgrade prompt when user lacks required access.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/payments/models/membership_tier.dart';
import '../../features/payments/services/membership_service.dart';
import '../../features/payments/screens/membership_upgrade_screen.dart';
import '../../core/design_system/design_constants.dart';
import '../../core/theme/neon_colors.dart';
import 'neon_components.dart';

/// Premium feature gate widget
class PremiumFeatureGate extends ConsumerWidget {
  /// Required membership tier to access feature
  final MembershipTier requiredTier;

  /// Child widget to show if user has access
  final Widget child;

  /// Optional custom upgrade message
  final String? upgradeMessage;

  /// Optional custom button text
  final String? upgradeButtonText;

  /// Show lock icon on gated content
  final bool showLockIcon;

  const PremiumFeatureGate({
    super.key,
    required this.requiredTier,
    required this.child,
    this.upgradeMessage,
    this.upgradeButtonText,
    this.showLockIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTier = MembershipService.instance.currentTier;
    final hasAccess = currentTier.includes(requiredTier);

    if (hasAccess) {
      return child;
    }

    // User doesn't have access - show upgrade prompt
    return _UpgradePrompt(
      requiredTier: requiredTier,
      message: upgradeMessage,
      buttonText: upgradeButtonText,
      showLockIcon: showLockIcon,
    );
  }
}

/// Upgrade prompt widget
class _UpgradePrompt extends StatelessWidget {
  final MembershipTier requiredTier;
  final String? message;
  final String? buttonText;
  final bool showLockIcon;

  const _UpgradePrompt({
    required this.requiredTier,
    this.message,
    this.buttonText,
    required this.showLockIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: requiredTier.primaryColor.withAlpha(51),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock icon
          if (showLockIcon)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    requiredTier.primaryColor,
                    requiredTier.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 32,
              ),
            ),

          if (showLockIcon) const SizedBox(height: 16),

          // Tier badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                requiredTier.icon,
                color: requiredTier.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${requiredTier.displayName} Only',
                style: TextStyle(
                  color: requiredTier.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            message ??
                'This feature is exclusive to ${requiredTier.displayName} members',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 20),

          // Upgrade button
          NeonButton(
            label: buttonText ?? 'Upgrade to ${requiredTier.displayName}',
            onPressed: () => _navigateToUpgrade(context),
            glowColor: requiredTier.primaryColor,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  void _navigateToUpgrade(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MembershipUpgradeScreen(),
      ),
    );
  }
}

/// Premium badge widget (for decorating premium features)
class PremiumBadge extends StatelessWidget {
  final MembershipTier tier;
  final double size;

  const PremiumBadge({
    super.key,
    this.tier = MembershipTier.vip,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.5,
        vertical: size * 0.25,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tier.primaryColor, tier.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            color: Colors.white,
            size: size * 0.8,
          ),
          SizedBox(width: size * 0.25),
          Text(
            tier.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium label widget (for marking premium content)
class PremiumLabel extends StatelessWidget {
  final String text;
  final MembershipTier tier;

  const PremiumLabel({
    super.key,
    this.text = 'Premium',
    this.tier = MembershipTier.vip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tier.primaryColor.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tier.primaryColor,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tier.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Verification badge widget
class VerificationBadge extends StatelessWidget {
  final double size;
  final bool showTooltip;

  const VerificationBadge({
    super.key,
    this.size = 20,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Icon(
      Icons.verified,
      color: NeonColors.neonBlue,
      size: size,
    );

    if (showTooltip) {
      return Tooltip(
        message: 'Verified User',
        child: badge,
      );
    }

    return badge;
  }
}
