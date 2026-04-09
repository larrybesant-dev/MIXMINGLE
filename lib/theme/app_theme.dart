import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: VelvetNoir.surface,
    colorScheme: const ColorScheme.dark(
      primary: VelvetNoir.primary,
      secondary: VelvetNoir.secondary,
      surface: VelvetNoir.surface,
      error: VelvetNoir.error,
      onPrimary: VelvetNoir.surface,
      onSecondary: VelvetNoir.surface,
      onSurface: VelvetNoir.onSurface,
      onError: VelvetNoir.surface,
      surfaceContainerLow: VelvetNoir.surfaceLow,
      surfaceContainer: VelvetNoir.surfaceContainer,
      surfaceContainerHigh: VelvetNoir.surfaceHigh,
      surfaceContainerHighest: VelvetNoir.surfaceHighest,
      outline: VelvetNoir.outlineVariant,
    ),
    textTheme: TextTheme(
      // Display & Headline — Playfair Display (elegant serif)
      displayLarge:   GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.5, color: VelvetNoir.onSurface),
      headlineLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 26, color: VelvetNoir.onSurface),
      headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 22, color: VelvetNoir.onSurface),
      headlineSmall:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18, color: VelvetNoir.onSurface),
      titleLarge:     GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20, color: VelvetNoir.onSurface),
      // Body & Labels — Raleway (clean modern — brand-spec)
      titleMedium: GoogleFonts.raleway(fontWeight: FontWeight.w600, fontSize: 16, color: VelvetNoir.onSurface),
      titleSmall:  GoogleFonts.raleway(fontWeight: FontWeight.w500, fontSize: 14, color: VelvetNoir.onSurface),
      bodyLarge:   GoogleFonts.raleway(fontSize: 16, color: VelvetNoir.onSurface),
      bodyMedium:  GoogleFonts.raleway(fontSize: 14, color: VelvetNoir.onSurfaceVariant),
      bodySmall:   GoogleFonts.raleway(fontSize: 12, color: VelvetNoir.onSurfaceVariant),
      labelLarge:  GoogleFonts.raleway(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.8, color: VelvetNoir.onSurface),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: VelvetNoir.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: VelvetNoir.onSurface,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: VelvetNoir.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1A73757D)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VelvetNoir.surfaceHighest,
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
        borderSide: const BorderSide(color: VelvetNoir.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: VelvetNoir.onSurfaceVariant, fontSize: 14),
      labelStyle: const TextStyle(color: VelvetNoir.onSurfaceVariant, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VelvetNoir.primary,
        foregroundColor: VelvetNoir.surface,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VelvetNoir.primary,
        side: const BorderSide(color: VelvetNoir.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VelvetNoir.primary,
      ),
    ),
    iconTheme: const IconThemeData(color: VelvetNoir.onSurfaceVariant),
    dividerTheme: const DividerThemeData(
      color: Color(0x1A73757D),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: VelvetNoir.surfaceHigh,
      contentTextStyle: GoogleFonts.inter(color: VelvetNoir.onSurface, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
