import 'package:flutter/material.dart';

// Electric Velvet ThemeData for MixVy
final ThemeData electricVelvetTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6200EE), // #6200EE
  scaffoldBackgroundColor: const Color(0xFF18181A),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6200EE),
    brightness: Brightness.dark,
    primary: const Color(0xFF6200EE),
    secondary: const Color(0xFF03DAC6),
    background: const Color(0xFF18181A),
    surface: const Color(0xFF23232B),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF23232B),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(
      color: Color(0xFF6200EE),
      fontWeight: FontWeight.bold,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6200EE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF03DAC6), width: 2),
    ),
  ),
);
