import 'package:flutter/material.dart';

class NeonTheme {
  static const Color primary = Colors.blueAccent;
  static const Color accent = Colors.orangeAccent;
  static const Color background = Colors.black;
  static const List<String> fontFallbacks = <String>[
    'Segoe UI',
    'Arial',
    'sans-serif',
    'Segoe UI Emoji',
    'Noto Color Emoji',
    'Noto Emoji',
    'Apple Color Emoji',
  ];

  // Dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamilyFallback: fontFallbacks,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: Color(0xFF1a1a1a),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFF1a1a1a),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
