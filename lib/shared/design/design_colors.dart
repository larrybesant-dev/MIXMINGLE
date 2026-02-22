import 'package:flutter/material.dart';

/// Centralized color palette for MixMingle design system
class DesignColors {
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.purple;
  static const Color accent = Colors.orange;
  static const Color background = Colors.white;
  static const Color surface = Colors.grey;
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.yellow;
  static const Color info = Colors.lightBlue;
  static const Color dialogBackground = Colors.white;

  static Color withOpacity(Color color, double opacity) => color.withValues(alpha: opacity);
}

/// Club-specific color palette
class ClubColors {
  static const Color clubPrimary = Color(0xFF4A90E2);
  static const Color clubAccent = Color(0xFFFF4C4C);
  static const Color clubBackground = Color(0xFF1A1A1A);
  static const Color clubText = Color(0xFFFFFFFF);
  static const Color glowingRed = Color(0xFFFF4C4C);
  static const Color cardBackground = Color(0xFF232323);
  static const Color goldenYellow = Color(0xFFFFD700);
}

const Color textColor = ClubColors.clubText;
