import 'package:flutter/material.dart';
import 'video_window_controller.dart';
import '../../../shared/models/window_state_model.dart';

class AdaptiveGridEngine {
  static const double minTileWidth = 200;
  static const double minTileHeight = 150;
  static const double spacing = 8;

  // Calculate optimal grid layout
  GridLayout calculateLayout(int itemCount, Size containerSize) {
    if (itemCount == 0) return GridLayout.empty();

    // Try different column counts
    GridLayout bestLayout = GridLayout.empty();
    double bestScore = double.infinity;

    for (int cols = 1; cols <= itemCount && cols <= 6; cols++) {
      final rows = (itemCount / cols).ceil();
      final tileWidth = (containerSize.width - (cols - 1) * spacing) / cols;
      final tileHeight = (containerSize.height - (rows - 1) * spacing) / rows;

      // Check minimum sizes
      if (tileWidth < minTileWidth || tileHeight < minTileHeight) continue;

      // Calculate aspect ratio score (prefer closer to 16:9)
      final aspectRatio = tileWidth / tileHeight;
      const targetRatio = 16 / 9;
      final ratioScore = (aspectRatio - targetRatio).abs();

      // Calculate wasted space score
      final usedWidth = cols * tileWidth + (cols - 1) * spacing;
      final usedHeight = rows * tileHeight + (rows - 1) * spacing;
      final wasteScore = (containerSize.width - usedWidth) +
                        (containerSize.height - usedHeight);

      final totalScore = ratioScore * 100 + wasteScore;

      if (totalScore < bestScore) {
        bestScore = totalScore;
        bestLayout = GridLayout(
          columns: cols,
          rows: rows,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          spacing: spacing,
        );
      }
    }

    return bestLayout;
  }

  // Apply grid layout to windows
  void applyGridLayout(List<VideoWindowController> windows, Size containerSize) {
    final layout = calculateLayout(windows.length, containerSize);

    for (int i = 0; i < windows.length; i++) {
      final row = i ~/ layout.columns;
      final col = i % layout.columns;

      final x = col * (layout.tileWidth + layout.spacing);
      final y = row * (layout.tileHeight + layout.spacing);

      windows[i].moveTo(Offset(x, y));
      windows[i].resizeTo(Size(layout.tileWidth, layout.tileHeight));
      windows[i].changeMode(WindowMode.docked);
    }
  }

  // Handle dynamic resize
  void handleContainerResize(
    List<VideoWindowController> windows,
    Size newSize,
    Size oldSize,
  ) {
    if (windows.isEmpty) return;

    final scaleX = newSize.width / oldSize.width;
    final scaleY = newSize.height / oldSize.height;

    for (final window in windows) {
      final newPos = Offset(
        window.windowState.position.dx * scaleX,
        window.windowState.position.dy * scaleY,
      );
      final newSize = Size(
        window.windowState.size.width * scaleX,
        window.windowState.size.height * scaleY,
      );

      window.moveTo(newPos);
      window.resizeTo(newSize);
    }
  }

  // Smart spacing adjustment
  double calculateOptimalSpacing(int itemCount, Size containerSize) {
    if (itemCount <= 1) return 0;

    // Reduce spacing for more items
    if (itemCount > 9) return spacing * 0.5;
    if (itemCount > 4) return spacing * 0.75;
    return spacing;
  }

  // Auto-resize tiles based on content
  void autoResizeTiles(List<VideoWindowController> windows, Size containerSize) {
    // Calculate layout for future use (grid metrics available if needed)
    calculateLayout(windows.length, containerSize);
    applyGridLayout(windows, containerSize);
  }
}

class GridLayout {
  final int columns;
  final int rows;
  final double tileWidth;
  final double tileHeight;
  final double spacing;

  GridLayout({
    required this.columns,
    required this.rows,
    required this.tileWidth,
    required this.tileHeight,
    required this.spacing,
  });

  factory GridLayout.empty() => GridLayout(
    columns: 0,
    rows: 0,
    tileWidth: 0,
    tileHeight: 0,
    spacing: 0,
  );

  bool get isEmpty => columns == 0;
}
