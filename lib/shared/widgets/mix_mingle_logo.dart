import 'package:flutter/material.dart';
import 'package:mixmingle/core/theme/neon_colors.dart';

/// Vybe Social logo widget — Neon Pulse brand identity
/// Glowing "V" icon + "VYBE SOCIAL" text in electric blue/violet gradient
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
          // Glowing "V" neon icon
          Container(
            width: fontSize * 1.2,
            height: fontSize * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: NeonColors.vybePulseGradient,
              boxShadow: [
                BoxShadow(
                  color: NeonColors.neonBlue.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'V',
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          SizedBox(width: fontSize * 0.3),
        ],

        // "VYBE" in electric blue
        Text(
          'VYBE',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..shader = NeonColors.vybePulseGradient.createShader(
                Rect.fromLTWH(0, 0, fontSize * 4, fontSize),
              ),
            letterSpacing: 2,
          ),
        ),

        SizedBox(width: fontSize * 0.15),

        // "SOCIAL" in violet
        Text(
          'SOCIAL',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: NeonColors.neonViolet,
            letterSpacing: 2,
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
