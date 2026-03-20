// MixVy Flutter Theme Config
// Replace this with the actual theme config from Stitch
import 'package:flutter/material.dart';

ThemeData buildMidnightTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Plus Jakarta Sans', // Replace with actual font if needed
    primaryColor: const Color(0xFF1A1A2E),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.dark,
      surface: const Color(0xFF0C0E12),
      onSurface: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white.withOpacity(0.05),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1, color: Colors.white),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: const Color(0xFF23234B),
    ),
  );
}
