import 'package:flutter/material.dart';

/// Electric Lounge color system
class ElectricColors {
  // Core brand gradient
  static const Color deepViolet = Color(0xFF120C2C);
  static const Color neonMagenta = Color(0xFFFF2BD7);
  static const Color electricCyan = Color(0xFF24E8FF);

  static const List<Color> electricGradient = [
    Color(0xFF1B103A),
    neonMagenta,
    electricCyan,
  ];

  // Accent tones
  static const Color neonLime = Color(0xFF9CFF43);
  static const Color hotOrange = Color(0xFFFF7A3C);
  static const Color warningAmber = Color(0xFFFFC857);
  static const Color successMint = Color(0xFF34EAB9);

  // Surfaces
  static const Color surface = Color(0xFF0B0B12);
  static const Color surfaceElevated = Color(0xFF131326);
  static const Color surfaceMuted = Color(0xFF1C1C30);

  // Overlays / glassmorphism
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassHighlight = Color(0x1AFFFFFF); // 10% white
  static const Color glassShadow = Color(0x33000000); // 20% black

  // Text on dark surfaces
  static const Color onSurfacePrimary = Color(0xFFEAF6FF);
  static const Color onSurfaceSecondary = Color(0xFFB9C4D0);
  static const Color onSurfaceMuted = Color(0xFF7A8392);

  // State
  static const Color error = Color(0xFFFF4D67);
  static const Color success = successMint;
  static const Color info = electricCyan;

  // Utility gradients
  static const LinearGradient electricDiagonal = LinearGradient(
    colors: electricGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonPulse = LinearGradient(
    colors: [neonMagenta, electricCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
