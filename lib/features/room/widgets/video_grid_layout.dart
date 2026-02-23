import 'package:flutter/material.dart';

/// Layout type for video grids
enum VideoGridLayoutType {
  single,
  sideBySide,
  grid2x2,
  grid3x3,
  grid4x4,
  dynamicGrid,
}

/// Helper class to determine adaptive video grid layout
class VideoGridLayout {
  /// Determine layout type based on participant count
  static VideoGridLayoutType getLayoutType(int participantCount) {
    if (participantCount == 0) {
      return VideoGridLayoutType.single;
    } else if (participantCount == 1) {
      return VideoGridLayoutType.single;
    } else if (participantCount == 2) {
      return VideoGridLayoutType.sideBySide;
    } else if (participantCount <= 4) {
      return VideoGridLayoutType.grid2x2;
    } else if (participantCount <= 9) {
      return VideoGridLayoutType.grid3x3;
    } else if (participantCount <= 16) {
      return VideoGridLayoutType.grid4x4;
    } else {
      return VideoGridLayoutType.dynamicGrid;
    }
  }

  /// Get grid dimensions for a layout type
  static (int rows, int cols) getGridDimensions(
    VideoGridLayoutType layoutType,
    int participantCount,
  ) {
    switch (layoutType) {
      case VideoGridLayoutType.single:
        return (1, 1);
      case VideoGridLayoutType.sideBySide:
        return (1, 2);
      case VideoGridLayoutType.grid2x2:
        return (2, 2);
      case VideoGridLayoutType.grid3x3:
        return (3, 3);
      case VideoGridLayoutType.grid4x4:
        return (4, 4);
      case VideoGridLayoutType.dynamicGrid:
        // For 5+, use 3x3 by default, allow scrolling for overflow
        return (3, 3);
    }
  }

  /// Get aspect ratio for tiles in layout
  static double getAspectRatio(VideoGridLayoutType layoutType) {
    switch (layoutType) {
      case VideoGridLayoutType.single:
      case VideoGridLayoutType.sideBySide:
        return 16 / 9;
      case VideoGridLayoutType.grid2x2:
      case VideoGridLayoutType.grid3x3:
      case VideoGridLayoutType.grid4x4:
      case VideoGridLayoutType.dynamicGrid:
        return 1.0; // Square tiles for grid
    }
  }

  /// Get spacing between tiles (in logical pixels)
  static const double defaultSpacing = 8.0;
  static const double compactSpacing = 4.0;
  static const double expandedSpacing = 12.0;

  /// Get padding around grid (in logical pixels)
  static const EdgeInsets defaultPadding = EdgeInsets.all(8.0);
  static const EdgeInsets compactPadding = EdgeInsets.all(4.0);
  static const EdgeInsets expandedPadding = EdgeInsets.all(12.0);

  /// Get appropriate spacing for layout type
  static double getSpacing(VideoGridLayoutType layoutType) {
    switch (layoutType) {
      case VideoGridLayoutType.single:
        return expandedSpacing;
      case VideoGridLayoutType.sideBySide:
        return defaultSpacing;
      case VideoGridLayoutType.grid2x2:
      case VideoGridLayoutType.grid3x3:
      case VideoGridLayoutType.grid4x4:
        return compactSpacing;
      case VideoGridLayoutType.dynamicGrid:
        return compactSpacing;
    }
  }

  /// Get appropriate padding for layout type
  static EdgeInsets getPadding(VideoGridLayoutType layoutType) {
    switch (layoutType) {
      case VideoGridLayoutType.single:
        return expandedPadding;
      case VideoGridLayoutType.sideBySide:
        return defaultPadding;
      case VideoGridLayoutType.grid2x2:
      case VideoGridLayoutType.grid3x3:
      case VideoGridLayoutType.grid4x4:
        return compactPadding;
      case VideoGridLayoutType.dynamicGrid:
        return compactPadding;
    }
  }

  /// Get tile border radius
  static BorderRadius getTileBorderRadius() {
    return BorderRadius.circular(12);
  }

  /// Get tile background color
  static Color getTileBackgroundColor() {
    return const Color(0xFF1E1E2F);
  }

  /// Get tile border color (default/inactive)
  static Color getTileBorderColor() {
    return const Color(0xFF2A2A3D);
  }

  /// Get active speaker highlight color
  static Color getActiveSpeakerGlowColor() {
    return Colors.greenAccent;
  }

  /// Get active speaker highlight border width
  static double getActiveSpeakerBorderWidth() {
    return 3.0;
  }

  /// Get default border width
  static double getDefaultBorderWidth() {
    return 1.0;
  }

  /// Get shadow for elevated tiles
  static List<BoxShadow> getActiveSpeakerShadow() {
    return [
      BoxShadow(
        color: Colors.greenAccent.withValues(alpha: 0.3),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ];
  }

  /// Get shadow for default tiles
  static List<BoxShadow> getDefaultShadow() {
    return [];
  }
}
