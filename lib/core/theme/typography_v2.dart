import 'package:flutter/material.dart';
import 'colors_v2.dart';

/// Electric Lounge typography system
class ElectricTypography {
  ElectricTypography._();

  // Prefer a modern, high-contrast grotesk. Fallbacks ensure availability.
  static const String primaryFontFamily = 'Space Grotesk';
  static const String secondaryFontFamily = 'Manrope';

  static TextTheme textTheme = TextTheme(
    displayLarge: _display.copyWith(fontSize: 56, height: 1.05),
    displayMedium: _display.copyWith(fontSize: 48, height: 1.05),
    displaySmall: _display.copyWith(fontSize: 40, height: 1.08),
    headlineLarge: _headline.copyWith(fontSize: 34, height: 1.12),
    headlineMedium: _headline.copyWith(fontSize: 30, height: 1.14),
    headlineSmall: _headline.copyWith(fontSize: 26, height: 1.16),
    titleLarge: _title.copyWith(fontSize: 22, height: 1.2),
    titleMedium: _title.copyWith(fontSize: 18, height: 1.2),
    titleSmall: _title.copyWith(fontSize: 16, height: 1.2),
    bodyLarge: _body.copyWith(fontSize: 16, height: 1.5),
    bodyMedium: _body.copyWith(fontSize: 14, height: 1.5),
    bodySmall: _body.copyWith(fontSize: 12, height: 1.45),
    labelLarge: _label.copyWith(fontSize: 14, height: 1.3),
    labelMedium: _label.copyWith(fontSize: 12, height: 1.25),
    labelSmall: _label.copyWith(fontSize: 11, height: 1.2),
  );

  // Base styles
  static const TextStyle _display = TextStyle(
    fontFamily: primaryFontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: ElectricColors.onSurfacePrimary,
  );

  static const TextStyle _headline = TextStyle(
    fontFamily: primaryFontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: ElectricColors.onSurfacePrimary,
  );

  static const TextStyle _title = TextStyle(
    fontFamily: primaryFontFamily,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: ElectricColors.onSurfacePrimary,
  );

  static const TextStyle _body = TextStyle(
    fontFamily: secondaryFontFamily,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    color: ElectricColors.onSurfaceSecondary,
  );

  static const TextStyle _label = TextStyle(
    fontFamily: secondaryFontFamily,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: ElectricColors.onSurfacePrimary,
  );
}
