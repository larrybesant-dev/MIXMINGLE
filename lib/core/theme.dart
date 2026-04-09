// Neon Pulse Design System — MixVy v3
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Velvet Noir Design Tokens — MixVy ────────────────────────────────────────
// Deep warm-black surfaces · champagne gold · rose wine · warm cream
class VelvetNoir {
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
    displayLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.5, color: VelvetNoir.onSurface),
    displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.3, color: VelvetNoir.onSurface),
    headlineLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 26, color: VelvetNoir.onSurface),
    headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 22, color: VelvetNoir.onSurface),
    headlineSmall:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18, color: VelvetNoir.onSurface),
    titleLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20, color: VelvetNoir.onSurface),
    // Body & Labels — Inter (clean, readable)
    titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: VelvetNoir.onSurface),
    titleSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: VelvetNoir.onSurface),
    bodyLarge:   GoogleFonts.inter(fontSize: 16, color: VelvetNoir.onSurface),
    bodyMedium:  GoogleFonts.inter(fontSize: 14, color: VelvetNoir.onSurfaceVariant),
    bodySmall:   GoogleFonts.inter(fontSize: 12, color: VelvetNoir.onSurfaceVariant),
    labelLarge:  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: VelvetNoir.onSurface),
    labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: VelvetNoir.onSurface),
    labelSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: VelvetNoir.onSurfaceVariant),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: VelvetNoir.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: VelvetNoir.onSurface,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: VelvetNoir.onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
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
      foregroundColor: VelvetNoir.onSurface,
      side: const BorderSide(color: Color(0x1A73757D)),
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
    space: 24,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: VelvetNoir.surfaceHigh,
    contentTextStyle: GoogleFonts.inter(color: VelvetNoir.onSurface, fontSize: 14, height: 1.4),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: VelvetNoir.surfaceLow,
    selectedItemColor: VelvetNoir.primary,
    unselectedItemColor: VelvetNoir.onSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);
