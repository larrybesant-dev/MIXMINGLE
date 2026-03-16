import 'package:flutter/material.dart';

final customTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.deepPurple,
  colorScheme: ColorScheme.dark(
    primary: Colors.deepPurple,
    surface: Colors.black,
    onPrimary: Colors.white,
    onSurface: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.deepPurple.shade50,
  ),
);
