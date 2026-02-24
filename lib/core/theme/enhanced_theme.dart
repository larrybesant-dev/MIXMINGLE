import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'colors.dart';
import 'text_styles.dart';

// Enhanced Material 3 theme with dark/light mode support
class EnhancedTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color scheme matching flyer design
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? ClubColors.mixOrange : ClubColors.mingleBlue,
        brightness: brightness,
        primary: isDark ? ClubColors.mixOrange : ClubColors.mingleBlue,
        secondary: isDark ? ClubColors.mingleBlue : ClubColors.mixOrange,
        tertiary: isDark ? ClubColors.purpleAccent : ClubColors.purpleAccent,
        surface: isDark ? ClubColors.surface : Colors.white,
        onSurface: isDark ? ClubColors.onSurface : Colors.black87,
        error: ClubColors.error,
        onError: Colors.white,
      ),

      // Typography
      textTheme:
          isDark ? ClubTextStyles.textTheme : ClubTextStyles.lightTextTheme,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? ClubColors.darkBackground : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: isDark ? ClubColors.cardBackground : Colors.white,
        shadowColor: isDark
            ? ClubColors.glowingRed.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.1),
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button themes matching flyer buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? ClubColors.mingleBlue : ClubColors.mingleBlue,
          foregroundColor: Colors.white,
          shadowColor: isDark
              ? ClubColors.mingleBlue.withValues(alpha: 0.3)
              : ClubColors.mingleBlue.withValues(alpha: 0.3),
          elevation: isDark ? 8 : 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          // Add hover effect
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            return null;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return isDark ? 12 : 8;
            }
            if (states.contains(WidgetState.pressed)) {
              return isDark ? 4 : 2;
            }
            return isDark ? 8 : 4;
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:
              isDark ? ClubColors.mingleBlue : ClubColors.mingleBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return 8;
            }
            return 4;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? ClubColors.mixOrange : ClubColors.mixOrange,
          side: BorderSide(
            color: isDark ? ClubColors.mixOrange : ClubColors.mixOrange,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return 4;
            }
            return 0;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(
                color: isDark ? ClubColors.mixOrange : ClubColors.mixOrange,
                width: 2,
              );
            }
            return BorderSide(
              color: isDark ? ClubColors.mixOrange : ClubColors.mixOrange,
              width: 1.5,
            );
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return isDark
                  ? ClubColors.glowingRed.withValues(alpha: 0.1)
                  : ClubColors.deepNavy.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),

      // Icon button theme with hover effect
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: isDark
              ? ClubColors.mingleBlue.withValues(alpha: 0.2)
              : ClubColors.mingleBlue.withValues(alpha: 0.1),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return 4;
            }
            return 0;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return ClubColors.mingleBlue.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),

      // Floating action button theme with hover effect
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? ClubColors.mixOrange : ClubColors.mingleBlue,
        foregroundColor: Colors.white,
        elevation: isDark ? 8 : 6,
        hoverElevation: isDark ? 12 : 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? ClubColors.glowingRed.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? ClubColors.glowingRed.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ClubColors.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ClubColors.error,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black38,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? ClubColors.cardBackground : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? ClubColors.cardBackground : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
        linearTrackColor: isDark ? Colors.white24 : Colors.black12,
        circularTrackColor: isDark ? Colors.white24 : Colors.black12,
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? ClubColors.glowingRed : ClubColors.deepNavy;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? ClubColors.glowingRed : ClubColors.deepNavy;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? ClubColors.glowingRed.withValues(alpha: 0.5)
                : ClubColors.deepNavy.withValues(alpha: 0.3);
          }
          return isDark ? Colors.white24 : Colors.black26;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? ClubColors.glowingRed : ClubColors.deepNavy;
          }
          return isDark ? Colors.white54 : Colors.black54;
        }),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white24 : Colors.black12,
        thickness: 1,
        space: 16,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        textColor: isDark ? Colors.white : Colors.black87,
        iconColor: isDark ? Colors.white70 : Colors.black54,
        tileColor: Colors.transparent,
        selectedTileColor: isDark
            ? ClubColors.glowingRed.withValues(alpha: 0.1)
            : ClubColors.deepNavy.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? ClubColors.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: isDark ? Colors.black45 : Colors.black12,
        indicatorColor: isDark
            ? ClubColors.glowingRed.withValues(alpha: 0.2)
            : ClubColors.deepNavy.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          );
        }),
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
        indicatorColor: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white12 : Colors.black12,
        selectedColor: isDark
            ? ClubColors.glowingRed.withValues(alpha: 0.2)
            : ClubColors.deepNavy.withValues(alpha: 0.1),
        checkmarkColor: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
        deleteIconColor: isDark ? Colors.white70 : Colors.black54,
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        secondaryLabelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? ClubColors.cardBackground : Colors.white,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actionTextColor: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? ClubColors.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        textStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? ClubColors.surface : Colors.white,
        selectedItemColor: isDark ? ClubColors.glowingRed : ClubColors.deepNavy,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
      ),

      // Search bar theme
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          isDark ? ClubColors.cardBackground : Colors.white,
        ),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(4),
        shadowColor: WidgetStateProperty.all(
          isDark ? Colors.black45 : Colors.black12,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Search view theme
      searchViewTheme: SearchViewThemeData(
        backgroundColor: isDark ? ClubColors.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Border radius
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 20.0;

  // Elevation
  static const double lowElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;
  static const double extraHighElevation = 12.0;

  // Spacing
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 24.0;
  static const double hugeSpacing = 32.0;
}

// Theme mode provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
