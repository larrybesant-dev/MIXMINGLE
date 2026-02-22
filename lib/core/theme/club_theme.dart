import 'package:flutter/material.dart';

final clubTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B0F1A),
  primaryColor: const Color(0xFF8F00FF),
  colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8F00FF), secondary: Color(0xFF00E6FF)),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF151A26),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
);
