// Neon Pulse Design System — MixVy v3
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Neon Pulse colour tokens ──────────────────────────────────────────────────
class NeonPulse {
  // Surfaces
  static const Color surface       = Color(0xFF0B0E14);
  static const Color surfaceLow    = Color(0xFF10131A);
  static const Color surfaceContainer     = Color(0xFF161A21);
  static const Color surfaceHigh   = Color(0xFF1C2028);
  static const Color surfaceBright = Color(0xFF282C36);
  static const Color surfaceHighest = Color(0xFF22262F);

  // Brand
  static const Color primary    = Color(0xFFBA9EFF); // lavender
  static const Color primaryDim = Color(0xFF8455EF); // deep purple
  static const Color secondary  = Color(0xFF00E3FD); // cyan

  // On-surface
  static const Color onSurface        = Color(0xFFECEDF6);
  static const Color onSurfaceVariant = Color(0xFFA9ABB3);
  static const Color outlineVariant   = Color(0xFF45484F);

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
  textTheme: GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge:  TextStyle(fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1,   color: NeonPulse.onSurface),
      displayMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.5, color: NeonPulse.onSurface),
      headlineLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 26, color: NeonPulse.onSurface),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: NeonPulse.onSurface),
      headlineSmall:  TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: NeonPulse.onSurface),
      titleLarge:  TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: NeonPulse.onSurface),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: NeonPulse.onSurface),
      titleSmall:  TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: NeonPulse.onSurface),
      bodyLarge:   TextStyle(fontSize: 16, color: NeonPulse.onSurface),
      bodyMedium:  TextStyle(fontSize: 14, color: NeonPulse.onSurfaceVariant),
      bodySmall:   TextStyle(fontSize: 12, color: NeonPulse.onSurfaceVariant),
      labelLarge:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: NeonPulse.onSurface),
      labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: NeonPulse.onSurface),
      labelSmall:  TextStyle(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: NeonPulse.onSurfaceVariant),
    ),
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
    contentTextStyle: GoogleFonts.inter(color: NeonPulse.onSurface, fontSize: 14),
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
