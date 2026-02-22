// lib/theme/mix_mingle_theme.dart
import 'package:flutter/material.dart';

class MixMingleTheme {
  // Color Palette
  static const Color primary = Color(0xFF2D3A4A);
  static const Color secondary = Color(0xFF4A90E2);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFF37475A);
  static const Color accent = Color(0xFFFFC107);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF43A047);

  // Typography Scale
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primary,
    letterSpacing: 0.5,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: secondary,
    letterSpacing: 0.2,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: surface,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: secondary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Spacing & Radius
  static const double spacing = 12.0;
  static const double radius = 16.0;
  static const double elevation = 8.0;

  // Shadow Rules
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // ThemeData
  static ThemeData get themeData => ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      elevation: elevation,
      titleTextStyle: title.copyWith(color: Colors.white),
    ),
    textTheme: TextTheme(
      displayLarge: title,
      titleLarge: subtitle,
      bodyLarge: body,
      bodySmall: caption,
      labelLarge: button,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        textStyle: button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: elevation,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      filled: true,
      fillColor: surface.withValues(alpha: 0.05),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: error,
      contentTextStyle: body.copyWith(color: Colors.white),
    ),
  );
}
