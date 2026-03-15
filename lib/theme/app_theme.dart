import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkLounge => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6C63FF), // Gold accent
    scaffoldBackgroundColor: const Color(0xFF1a1a2e),
    cardColor: const Color(0xFF16213e),
    fontFamily: 'Noto Sans',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF16213e),
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFF6C63FF),
      labelStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF22223b),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFFFD700)),
  );
}
