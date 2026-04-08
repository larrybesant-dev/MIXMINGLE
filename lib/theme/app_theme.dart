import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeonPulse.surface,
    colorScheme: const ColorScheme.dark(
      primary: NeonPulse.primary,
      secondary: NeonPulse.secondary,
      surface: NeonPulse.surface,
      error: NeonPulse.error,
      onPrimary: NeonPulse.surface,
      onSecondary: NeonPulse.surface,
      onSurface: NeonPulse.onSurface,
      onError: NeonPulse.surface,
      surfaceContainerLow: NeonPulse.surfaceLow,
      surfaceContainer: NeonPulse.surfaceContainer,
      surfaceContainerHigh: NeonPulse.surfaceHigh,
      surfaceContainerHighest: NeonPulse.surfaceHighest,
      outline: NeonPulse.outlineVariant,
    ),
    textTheme: TextTheme(
      // Display & Headline — Playfair Display (elegant serif)
      displayLarge:   GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.5, color: NeonPulse.onSurface),
      headlineLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 26, color: NeonPulse.onSurface),
      headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 22, color: NeonPulse.onSurface),
      headlineSmall:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18, color: NeonPulse.onSurface),
      titleLarge:     GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20, color: NeonPulse.onSurface),
      // Body & Labels — Inter (clean, readable)
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: NeonPulse.onSurface),
      titleSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: NeonPulse.onSurface),
      bodyLarge:   GoogleFonts.inter(fontSize: 16, color: NeonPulse.onSurface),
      bodyMedium:  GoogleFonts.inter(fontSize: 14, color: NeonPulse.onSurfaceVariant),
      bodySmall:   GoogleFonts.inter(fontSize: 12, color: NeonPulse.onSurfaceVariant),
      labelLarge:  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: NeonPulse.onSurface),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NeonPulse.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: NeonPulse.onSurface,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NeonPulse.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1A73757D)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeonPulse.surfaceHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: NeonPulse.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: NeonPulse.onSurfaceVariant, fontSize: 14),
      labelStyle: const TextStyle(color: NeonPulse.onSurfaceVariant, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NeonPulse.primary,
        foregroundColor: NeonPulse.surface,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NeonPulse.onSurface,
        side: const BorderSide(color: Color(0x1A73757D)),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NeonPulse.primary,
      ),
    ),
    iconTheme: const IconThemeData(color: NeonPulse.onSurfaceVariant),
    dividerTheme: const DividerThemeData(
      color: Color(0x1A73757D),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NeonPulse.surfaceHigh,
      contentTextStyle: GoogleFonts.inter(color: NeonPulse.onSurface, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
