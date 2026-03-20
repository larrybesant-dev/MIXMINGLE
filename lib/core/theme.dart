// Midnight Creative Theme for MixVy
import 'package:flutter/material.dart';

ThemeData midnightCreativeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFAC8EFF),
  scaffoldBackgroundColor: const Color(0xFF0C0E12),
  fontFamily: 'Plus Jakarta Sans',
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
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFAC8EFF),
    surface: const Color(0xFF0C0E12),
    onSurface: Colors.white,
    secondary: const Color(0xFF1A73E8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);
}
