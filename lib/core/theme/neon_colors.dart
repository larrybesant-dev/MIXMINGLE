import 'package:flutter/material.dart';

/// MIXVY Neon Club Color Palette
/// Electric aesthetic with vibrant neon accents - based on official brand
class NeonColors {
  // Primary Brand Colors - MIXVY Official
  static const Color neonOrange = Color(0xFFFF7A3C);      // Legacy accent (kept for compatibility)
  static const Color neonBlue = Color(0xFF00D9FF);        // Electric blue (primary brand)
  static const Color neonViolet = Color(0xFF7B2BFF);      // Violet (Neon Pulse mid)
  static const Color neonMagenta = Color(0xFFFF2BD7);     // Magenta (Neon Pulse end)
  static const Color neonPurple = Color(0xFFBD00FF);      // Electric purple accent
  static const Color neonPink = Color(0xFFFF2BD7);        // Hot pink accent

  // Background & Foundation - Nightclub Deep Black
  static const Color darkBg = Color(0xFF0A0E27);          // Deep navy black (primary bg)
  static const Color darkBg2 = Color(0xFF1A1F3A);         // Slightly lighter navy
  static const Color darkBg3 = Color(0xFF2A2F4A);         // Medium dark navy
  static const Color darkCard = Color(0xFF15192D);        // Card background with depth

  // Neutral & Text
  static const Color textPrimary = Color(0xFFFFFFFF);     // Bright white text
  static const Color textSecondary = Color(0xFFB0B8D4);   // Light gray-blue
  static const Color textTertiary = Color(0xFF7A8099);    // Medium gray-blue
  static const Color divider = Color(0xFF3A3F5A);         // Subtle divider

  // Accent Colors
  static const Color successGreen = Color(0xFF00FF88);   // Neon green
  static const Color warningYellow = Color(0xFFFFD700);  // Gold yellow
  static const Color errorRed = Color(0xFFFF1744);       // Bright red
  static const Color infoLightBlue = Color(0xFF00B8FF);  // Light blue

  // Gradients
  static const LinearGradient neonGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      neonBlue,
      neonViolet,
      neonMagenta,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient mixvyPulseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      neonBlue,
      neonViolet,
      neonMagenta,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient neonBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      neonBlue,
      Color(0xFF0099FF),
    ],
    stops: [0.0, 1.0],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      darkBg,
      darkBg2,
    ],
    stops: [0.0, 1.0],
  );
}
