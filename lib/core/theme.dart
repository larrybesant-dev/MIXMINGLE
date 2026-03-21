// Final Production Theme (v2) for MixVy
import 'package:flutter/material.dart';

final ThemeData midnightCreativeTheme = ThemeData(
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
    displayLarge: TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 32,
      letterSpacing: -1,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Colors.white70,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Colors.white54,
      fontSize: 12,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0C0E12),
    elevation: 0,
    foregroundColor: Colors.white,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFAC8EFF), width: 1.5),
    ),
    labelStyle: const TextStyle(fontSize: 14, color: Colors.white70),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFAC8EFF),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFAC8EFF),
    secondary: Color(0xFF6C47FF),
    surface: Color(0xFF181A20),
    background: Color(0xFF0C0E12),
    error: Color(0xFFFF5A5A),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  dividerTheme: const DividerThemeData(
    color: Colors.white24,
    thickness: 1,
    space: 32,
  ),
  iconTheme: const IconThemeData(color: Colors.white70),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF181A20),
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
);
