library;

import 'package:flutter/material.dart';
import '../../core/design_system/design_constants.dart';
/// UI Constants - Centralized theme, spacing, and animation constants


/// Animation durations for smooth transitions
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// Spacing values for consistent layout
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius values
class BorderRadii {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double circular = 100;
}

/// Responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}

/// Color palette
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFEC407A);
  static const Color primaryLight = Color(0xFFFF7FA0);
  static const Color primaryDark = Color(0xFFD9135A);

  // Secondary Colors
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF4DD0E1);
  static const Color secondaryDark = Color(0xFF0097A7);

  // Accent Colors
  static const Color accent = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = DesignColors.background;
  static const Color transparent = Color(0x00000000);

  // Light mode colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF212121);
  static const Color lightSubtext = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFBDBDBD);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSubtext = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF424242);
  static const Color darkDivider = Color(0xFF616161);
}

/// Text styles
class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.75,
  );
}

/// Shadows
class AppShadows {
  static final List<BoxShadow> elevation1 = [
    BoxShadow(
      color: DesignColors.accent.withValues(alpha: 0.12),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> elevation2 = [
    BoxShadow(
      color: DesignColors.accent.withValues(alpha: 0.12),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> elevation3 = [
    BoxShadow(
      color: DesignColors.accent.withValues(alpha: 0.14),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  static final List<BoxShadow> elevation4 = [
    BoxShadow(
      color: DesignColors.accent.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Curves for animations
class AppCurves {
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
}

/// Size constants for common widgets
class WidgetSizes {
  // Heights
  static const double topBarHeight = 56;
  static const double sidebarWidth = 320;
  static const double sidebarWidthMobile = 280;
  static const double videoTileMinSize = 150;
  static const double chatBoxHeight = 200;
  static const double buttonHeight = 40;
  static const double inputFieldHeight = 44;

  // Button sizes
  static const double smallIconSize = 16;
  static const double mediumIconSize = 24;
  static const double largeIconSize = 32;
  static const double extraLargeIconSize = 48;
}

/// Z-index values for stacking context
class ZIndices {
  static const int background = 0;
  static const int modal = 100;
  static const int dropdown = 110;
  static const int tooltip = 120;
  static const int overlay = 130;
}
