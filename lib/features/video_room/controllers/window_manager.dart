import 'package:flutter/material.dart';
import '../../../shared/models/window_state_model.dart';
import 'video_window_controller.dart';

class WindowManager {
  final List<VideoWindowController> _windows = [];
  int _nextZIndex = 0;

  // Registry
  void registerWindow(VideoWindowController window) {
    _windows.add(window);
    _bringToFront(window);
  }

  void unregisterWindow(VideoWindowController window) {
    _windows.remove(window);
  }

  // Lifecycle
  void createWindow(VideoWindowController window) {
    registerWindow(window);
  }

  void destroyWindow(VideoWindowController window) {
    unregisterWindow(window);
  }

  // Z-index management
  void _bringToFront(VideoWindowController window) {
    _nextZIndex++;
    window.bringToFront(_nextZIndex);
  }

  void bringWindowToFront(VideoWindowController window) {
    _bringToFront(window);
  }

  // Focus management
  VideoWindowController? getTopWindow() {
    if (_windows.isEmpty) return null;
    return _windows.reduce((a, b) =>
      a.windowState.zIndex > b.windowState.zIndex ? a : b);
  }

  void focusWindow(VideoWindowController window) {
    _bringToFront(window);
  }

  // Snapping
  void snapWindowToEdge(VideoWindowController window, Size screenSize) {
    final pos = window.windowState.position;
    final size = window.windowState.size;

    EdgeInsets? edges;
    if (pos.dx <= 10) {
      edges = const EdgeInsets.only(left: 0);
    } else if (pos.dx + size.width >= screenSize.width - 10) {
      edges = const EdgeInsets.only(right: 0);
    }
    if (pos.dy <= 10) {
      edges = (edges ?? EdgeInsets.zero).copyWith(top: 0);
    }
    if (edges != null) {
      window.snapToEdge(edges);
    }
  }

  void unsnapWindow(VideoWindowController window) {
    window.unsnap();
  }

  // Window operations
  void minimizeWindow(VideoWindowController window) {
    window.minimize();
  }

  void maximizeWindow(VideoWindowController window) {
    window.maximize();
  }

  void togglePinWindow(VideoWindowController window) {
    window.togglePin();
  }

  // Get windows by state
  List<VideoWindowController> getFloatingWindows() {
    return _windows.where((w) => w.windowState.mode == WindowMode.floating).toList();
  }

  List<VideoWindowController> getMinimizedWindows() {
    return _windows.where((w) => w.windowState.mode == WindowMode.minimized).toList();
  }

  List<VideoWindowController> getPinnedWindows() {
    return _windows.where((w) => w.isPinned).toList();
  }

  // Collision detection
  bool checkCollision(VideoWindowController window, Offset position, Size size) {
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    for (final other in _windows) {
      if (other == window) continue;
      final otherRect = Rect.fromLTWH(
        other.windowState.position.dx,
        other.windowState.position.dy,
        other.windowState.size.width,
        other.windowState.size.height,
      );
      if (rect.overlaps(otherRect)) return true;
    }
    return false;
  }

  // Auto-arrange
  void arrangeWindows(Size containerSize, {bool floatingOnly = false}) {
    final windows = floatingOnly ? getFloatingWindows() : _windows;
    if (windows.isEmpty) return;

    final count = windows.length;
    final cols = count <= 4 ? 2 : count <= 9 ? 3 : 4;
    final rows = (count / cols).ceil();

    final tileWidth = containerSize.width / cols;
    final tileHeight = containerSize.height / rows;

    for (int i = 0; i < count; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final position = Offset(col * tileWidth, row * tileHeight);
      final size = Size(tileWidth, tileHeight);

      windows[i].moveTo(position);
      windows[i].resizeTo(size);
      windows[i].changeMode(WindowMode.docked);
    }
  }

  // Get all windows
  List<VideoWindowController> getAllWindows() => List.unmodifiable(_windows);
}
