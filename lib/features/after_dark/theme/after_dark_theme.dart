// Ember Dark Design System — MixVy After Dark
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Ember Dark colour tokens ──────────────────────────────────────────────────
class EmberDark {
  // Surfaces — near-black with deep crimson undertones
  static const Color surface         = Color(0xFF070305);
  static const Color surfaceLow      = Color(0xFF0C0508);
  static const Color surfaceContainer = Color(0xFF15090F);
  static const Color surfaceHigh     = Color(0xFF1E0D16);
  static const Color surfaceBright   = Color(0xFF2A1220);
  static const Color surfaceHighest  = Color(0xFF231020);

  // Brand — crimson · hot pink
  static const Color primary     = Color(0xFFE0142A); // crimson
  static const Color primaryDim  = Color(0xFF9E0E1E); // deep crimson
  static const Color secondary   = Color(0xFFFF4F8B); // hot pink

  // On-surface — warm off-white with pink tint
  static const Color onSurface        = Color(0xFFF5E8EE);
  static const Color onSurfaceVariant = Color(0xFFBB96A4);
  static const Color outlineVariant   = Color(0xFF5A2A3A);

  // Status
  static const Color error  = Color(0xFFFF6E84);
  static const Color live   = Color(0xFFE0142A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDim],
  );

  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9E0E1E), Color(0xFF2A0010)],
  );
}

final ThemeData afterDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: EmberDark.surface,
  colorScheme: const ColorScheme.dark(
    primary: EmberDark.primary,
    secondary: EmberDark.secondary,
    surface: EmberDark.surface,
    error: EmberDark.error,
    onPrimary: EmberDark.onSurface,
    onSecondary: EmberDark.onSurface,
    onSurface: EmberDark.onSurface,
    onError: EmberDark.onSurface,
    surfaceContainerLow: EmberDark.surfaceLow,
    surfaceContainer: EmberDark.surfaceContainer,
    surfaceContainerHigh: EmberDark.surfaceHigh,
    surfaceContainerHighest: EmberDark.surfaceHighest,
    outline: EmberDark.outlineVariant,
  ),
  textTheme: TextTheme(
    displayLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.5, color: EmberDark.onSurface),
    displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.3, color: EmberDark.onSurface),
    headlineLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 26, color: EmberDark.onSurface),
    headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 22, color: EmberDark.onSurface),
    headlineSmall:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18, color: EmberDark.onSurface),
    titleLarge:  GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20, color: EmberDark.onSurface),
    titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: EmberDark.onSurface),
    titleSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: EmberDark.onSurface),
    bodyLarge:   GoogleFonts.inter(fontSize: 16, color: EmberDark.onSurface),
    bodyMedium:  GoogleFonts.inter(fontSize: 14, color: EmberDark.onSurfaceVariant),
    bodySmall:   GoogleFonts.inter(fontSize: 12, color: EmberDark.onSurfaceVariant),
    labelLarge:  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: EmberDark.onSurface),
    labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: EmberDark.onSurface),
    labelSmall:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: EmberDark.onSurfaceVariant),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: EmberDark.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: EmberDark.onSurface,
    centerTitle: true,
    titleTextStyle: GoogleFonts.playfairDisplay(
      color: EmberDark.onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: EmberDark.surfaceHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: EmberDark.outlineVariant.withValues(alpha: 0.5), width: 1),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: EmberDark.surfaceHighest,
    hintStyle: GoogleFonts.inter(color: EmberDark.onSurfaceVariant),
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
      borderSide: const BorderSide(color: EmberDark.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: EmberDark.primary,
      foregroundColor: EmberDark.onSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: EmberDark.primary,
      foregroundColor: EmberDark.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: EmberDark.onSurface,
      side: const BorderSide(color: EmberDark.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: EmberDark.outlineVariant,
    thickness: 1,
    space: 1,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return EmberDark.primary;
      return EmberDark.onSurfaceVariant;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return EmberDark.primary.withValues(alpha: 0.4);
      }
      return EmberDark.surfaceBright;
    }),
  ),
  iconTheme: const IconThemeData(color: EmberDark.onSurface, size: 24),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.selected)) return EmberDark.primary;
      return Colors.transparent;
    }),
    side: const BorderSide(color: EmberDark.outlineVariant),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
);
