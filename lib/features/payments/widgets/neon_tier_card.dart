/// Neon Tier Card Widget
///
/// Displays membership tier card with neon VIP Lounge aesthetic.
/// Features animated glow effects and gold trim for premium tiers.
library;

import 'package:flutter/material.dart';
import '../models/membership_tier.dart';
import '../../../../core/design_system/design_constants.dart';

/// Neon styled membership tier card
class NeonTierCard extends StatefulWidget {
  final MembershipTier tier;
  final bool isSelected;
  final bool isCurrentTier;
  final bool isYearly;
  final VoidCallback onTap;
  final bool showSpotlight;

  const NeonTierCard({
    super.key,
    required this.tier,
    this.isSelected = false,
    this.isCurrentTier = false,
    this.isYearly = false,
    required this.onTap,
    this.showSpotlight = false,
  });

  @override
  State<NeonTierCard> createState() => _NeonTierCardState();
}

class _NeonTierCardState extends State<NeonTierCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _spotlightController;
  late Animation<double> _glowAnimation;
  late Animation<double> _spotlightAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _spotlightController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _spotlightAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _spotlightController, curve: Curves.easeInOut),
    );

    if (widget.showSpotlight && widget.tier == MembershipTier.vipPlus) {
      _spotlightController.repeat();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _spotlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVipPlus = widget.tier == MembershipTier.vipPlus;
    final pricing = widget.tier.pricing;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnimation, _spotlightAnimation]),
        builder: (context, child) {
          final glowIntensity = _glowAnimation.value;
          final isHighlighted = widget.isSelected || isVipPlus;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                // Main card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.tier.primaryColor.withAlpha(isHighlighted ? 38 : 26),
                        widget.tier.secondaryColor.withAlpha(isHighlighted ? 38 : 26),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? widget.tier.primaryColor
                          : widget.tier.primaryColor.withAlpha(isHighlighted ? 102 : 51),
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isHighlighted)
                        BoxShadow(
                          color: widget.tier.primaryColor.withAlpha((50 + 50 * glowIntensity).round()),
                          blurRadius: 16 + 8 * glowIntensity,
                          spreadRadius: 0,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Spotlight sweep for VIP+
                        if (isVipPlus && widget.showSpotlight)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _spotlightAnimation,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _SpotlightPainter(
                                    position: _spotlightAnimation.value,
                                    color: DesignColors.gold,
                                  ),
                                );
                              },
                            ),
                          ),

                        // Card content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  // Tier icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: widget.tier.primaryColor.withAlpha(51),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: widget.tier.primaryColor.withAlpha(102),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      widget.tier.icon,
                                      color: widget.tier.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Tier name and price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              widget.tier.displayName,
                                              style: TextStyle(
                                                color: widget.tier.primaryColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            if (isVipPlus) ...[
                                              const SizedBox(width: 8),
                                              _BestValueBadge(),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (pricing != null)
                                          Text(
                                            widget.isYearly
                                                ? '${pricing.yearlyPriceDisplay}/year'
                                                : '${pricing.monthlyPriceDisplay}/month',
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(179),
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Selection indicator
                                  if (widget.isSelected || widget.isCurrentTier)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: widget.isCurrentTier
                                            ? Colors.green.withAlpha(51)
                                            : widget.tier.primaryColor.withAlpha(51),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        widget.isCurrentTier
                                            ? Icons.check_circle
                                            : Icons.radio_button_checked,
                                        color: widget.isCurrentTier
                                            ? Colors.green
                                            : widget.tier.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Benefits list
                              ...widget.tier.benefits.take(4).map((benefit) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      NeonCheckmark(
                                        color: widget.tier.primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          benefit.title,
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(230),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // "And more" indicator
                              if (widget.tier.benefits.length > 4)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '+ ${widget.tier.benefits.length - 4} more benefits',
                                    style: TextStyle(
                                      color: widget.tier.primaryColor.withAlpha(179),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),

                              // Yearly savings
                              if (pricing != null && widget.isYearly) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00FF88).withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF00FF88).withAlpha(77),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Save ${pricing.yearlySavingsPercent}% with annual plan',
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Current membership indicator
                if (widget.isCurrentTier)
                  Positioned(
                    top: 0,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Best Value badge for VIP+
class _BestValueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DesignColors.gold,
            Color(0xFFFF7A3C),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'BEST VALUE',
        style: TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Neon checkmark indicator
class NeonCheckmark extends StatelessWidget {
  final Color color;
  final double size;

  const NeonCheckmark({
    super.key,
    required this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withAlpha(128),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        color: color,
        size: size * 0.7,
      ),
    );
  }
}

/// Spotlight sweep painter for VIP+ card
class _SpotlightPainter extends CustomPainter {
  final double position;
  final Color color;

  _SpotlightPainter({
    required this.position,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.4;
    final startX = size.width * position;

    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        color.withAlpha(26),
        color.withAlpha(51),
        color.withAlpha(26),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    );

    final rect = Rect.fromLTWH(startX, 0, width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.position != position;
  }
}

/// Free tier card (minimal styling)
class FreeTierCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const FreeTierCard({
    super.key,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withAlpha(128)
                : Colors.white.withAlpha(26),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                MembershipTier.free.icon,
                color: Colors.white.withAlpha(179),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Basic features included',
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white.withAlpha(179),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
