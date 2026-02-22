import 'package:flutter/material.dart';

class DesignColors {
  static const Color primary = Colors.blue;
  static const Color grey = Colors.grey;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static Color withOpacity(Color color, double opacity) => color.withValues(alpha: opacity);
}
