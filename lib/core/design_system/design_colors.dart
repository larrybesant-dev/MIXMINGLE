// lib/design/design_colors.dart
// Minimal DesignColors stub used by tests to unblock analyzer.
// Replace with real design tokens later.

import 'package:flutter/material.dart';

class DesignColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color secondary = Color(0xFF00D9FF);

  /// accent as a MaterialColor so tests can use DesignColors.accent[900] etc.
  static const MaterialColor accent = MaterialColor(
    0xFFFFC107,
    <int, Color>{
      50: Color(0xFFFFF8E1),
      100: Color(0xFFFFECB3),
      200: Color(0xFFFFE082),
      300: Color(0xFFFFD54F),
      400: Color(0xFFFFCA28),
      500: Color(0xFFFFC107),
      600: Color(0xFFFFB300),
      700: Color(0xFFFFA000),
      800: Color(0xFFFF8F00),
      900: Color(0xFFFF6F00),
    },
  );

  /// Opacity variants — pre-computed as const Color values
  /// alpha = 0x87 * 255 / 100 ≈ 0xDE (87%), 0x8A (54%), 0xB3 (70%), 0x61 (38%)
  static const Color accent87 = Color(0xDEFFC107); // 87% opacity
  static const Color accent70 = Color(0xB3FFC107); // 70% opacity
  static const Color accent54 = Color(0x8AFFC107); // 54% opacity
  static const Color accent38 = Color(0x61FFC107); // 38% opacity
  static const Color accentLight = Color(0x1FFFC107); // ~12% opacity

  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color white = Color(0xFFFFFFFF);
}
