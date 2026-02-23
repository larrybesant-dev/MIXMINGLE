library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Onboarding Neon Button
///
/// A premium neon button with glow effects and gold trim option.
/// Used throughout the onboarding flow for CTAs.

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';

class OnboardingNeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool useGoldTrim;
  final Color? glowColor;
  final double? width;
  final double height;
  final IconData? icon;
  final bool enabled;
  final bool pulsate;

  const OnboardingNeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.useGoldTrim = false,
    this.glowColor,
    this.width,
    this.height = 56,
    this.icon,
    this.enabled = true,
    this.pulsate = true,
  });

  @override
  State<OnboardingNeonButton> createState() => _OnboardingNeonButtonState();
}

class _OnboardingNeonButtonState extends State<OnboardingNeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.pulsate && widget.enabled) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OnboardingNeonButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsate && widget.enabled && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if ((!widget.pulsate || !widget.enabled) && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.useGoldTrim
        ? DesignColors.gold
        : (widget.glowColor ?? NeonColors.neonOrange);
    final glowColor = widget.useGoldTrim
        ? DesignColors.gold
        : (widget.glowColor ?? NeonColors.neonOrange);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = widget.enabled ? _glowAnimation.value : 0.2;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.enabled
                ? [
                    // Inner glow
                    BoxShadow(
                      color: glowColor.withValues(alpha: glowIntensity * 0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                    // Outer glow
                    BoxShadow(
                      color: glowColor.withValues(alpha: glowIntensity * 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled && !widget.isLoading ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.enabled
                        ? [
                            baseColor.withValues(alpha: 0.9),
                            baseColor,
                            baseColor.withValues(alpha: 0.8),
                          ]
                        : [
                            Colors.grey.shade800,
                            Colors.grey.shade700,
                          ],
                  ),
                  border: widget.useGoldTrim
                      ? Border.all(
                          color: DesignColors.gold.withValues(alpha: 0.8),
                          width: 2,
                        )
                      : Border.all(
                          color: baseColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignColors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: DesignColors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                color: DesignColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Secondary outline button with neon effect
class OnboardingOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final IconData? icon;
  final double height;

  const OnboardingOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderColor,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? NeonColors.neonBlue;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
