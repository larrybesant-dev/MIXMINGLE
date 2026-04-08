// Neon Pulse Design System — MixVy v3
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Velvet Noir Design Tokens — MixVy ────────────────────────────────────────
// Deep warm-black surfaces · champagne gold · rose wine · warm cream
class NeonPulse {
  // Surfaces — warm deep-black with burgundy undertones
  static const Color surface        = Color(0xFF0D0A0C);
  static const Color surfaceLow     = Color(0xFF130C0F);
  static const Color surfaceContainer = Color(0xFF1B1216);
  static const Color surfaceHigh    = Color(0xFF241820);
  static const Color surfaceBright  = Color(0xFF302229);
  static const Color surfaceHighest = Color(0xFF2A1C23);

  // Brand — champagne gold · rose wine
  static const Color primary    = Color(0xFFD4A853); // champagne gold
  static const Color primaryDim = Color(0xFF8C6020); // deep amber
  static const Color secondary  = Color(0xFFC45E7A); // rose wine

  // On-surface — warm cream tones
  static const Color onSurface        = Color(0xFFF2EBE0);
  static const Color onSurfaceVariant = Color(0xFFB09080);
  static const Color outlineVariant   = Color(0xFF5A3845);

  // Status
  static const Color error = Color(0xFFFF6E84); // LIVE badge / error

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDim],
  );
}

final ThemeData midnightCreativeTheme = ThemeData(
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
    displayLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.5, color: NeonPulse.onSurface),
    displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.3, color: NeonPulse.onSurface),
    headlineLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 26, color: NeonPulse.onSurface),
    headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 22, color: NeonPulse.onSurface),
    headlineSmall:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18, color: NeonPulse.onSurface),
    titleLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20, color: NeonPulse.onSurface),
    // Body & Labels — Inter (clean, readable)
    titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: NeonPulse.onSurface),
    titleSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: NeonPulse.onSurface),
    bodyLarge:   GoogleFonts.inter(fontSize: 16, color: NeonPulse.onSurface),
    bodyMedium:  GoogleFonts.inter(fontSize: 14, color: NeonPulse.onSurfaceVariant),
    bodySmall:   GoogleFonts.inter(fontSize: 12, color: NeonPulse.onSurfaceVariant),
    labelLarge:  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: NeonPulse.onSurface),
    labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: NeonPulse.onSurface),
    labelSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: NeonPulse.onSurfaceVariant),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: NeonPulse.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: NeonPulse.onSurface,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: NeonPulse.onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
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
    space: 24,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: NeonPulse.surfaceHigh,
    contentTextStyle: GoogleFonts.inter(color: NeonPulse.onSurface, fontSize: 14, height: 1.4),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: NeonPulse.surfaceLow,
    selectedItemColor: NeonPulse.primary,
    unselectedItemColor: NeonPulse.onSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);
