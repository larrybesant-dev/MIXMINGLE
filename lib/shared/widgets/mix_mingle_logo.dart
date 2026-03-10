import 'package:flutter/material.dart';
import 'package:mixmingle/core/theme/neon_colors.dart';

/// MIXVY logo widget — Neon brand identity
/// Glowing "M" icon + "MIXVY" gradient text
class VybeSocialLogo extends StatelessWidget {
  final double fontSize;
  final bool showIcon;

  const VybeSocialLogo({
    super.key,
    this.fontSize = 32,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showIcon) ...[
          // MIXVY icon — try asset first, fall back to drawn "M" circle
          Container(
            width: fontSize * 1.25,
            height: fontSize * 1.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NeonColors.neonPink.withValues(alpha: 0.6),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/brand/png/app_icon/mixvy_icon_96x96.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NeonColors.vybePulseGradient,
                  ),
                  child: Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: fontSize * 0.65,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: fontSize * 0.3),
        ],

        // "MIXVY" gradient text
        ShaderMask(
          shaderCallback: (bounds) => NeonColors.vybePulseGradient
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'MIXVY',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact version for small spaces (just text, no icon)
class VybeSocialLogoCompact extends StatelessWidget {
  final double fontSize;

  const VybeSocialLogoCompact({
    super.key,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return VybeSocialLogo(
      fontSize: fontSize,
      showIcon: false,
    );
  }
}

// Legacy aliases for backward compatibility
typedef MixMingleLogo = VybeSocialLogo;
typedef MixMingleLogoCompact = VybeSocialLogoCompact;
