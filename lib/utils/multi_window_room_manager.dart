import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Multi-window room manager for Flutter Web
class MultiWindowRoomManager {
  /// Cache of open room windows
  static final Map<String, web.Window?> _openWindows = {};

  /// Open a room in a new browser window/tab
  /// Returns true if window opened successfully
  /// If room is already open, focuses that window instead (collision detection)
  static bool openRoomWindow({
    required String roomId,
    required String roomName,
    required String userId,
    String windowName = '_blank',
  }) {
    try {
      // Collision detection: Check if window is already open
      if (isWindowOpen(roomId)) {
        final existingWindow = _openWindows[roomId];
        if (existingWindow != null) {
          try {
            // Try to focus existing window
            existingWindow.focus();
            debugLog('[MULTI_WINDOW] Focused existing room window: $roomId');
            return true;
          } catch (e) {
            debugLog('[MULTI_WINDOW] Could not focus window: $e');
            // Fall through to open new window
          }
        }
      }

      final url = _buildRoomUrl(roomId, roomName, userId);

      // Open in new tab/window
      final window = web.window.open(url, windowName, '');

      if (window != null) {
        _openWindows[roomId] = window;
        debugLog('[MULTI_WINDOW] Opened room: $roomId in new window');
        return true;
      }

      debugLog('[MULTI_WINDOW] Failed to open window for room: $roomId');
      return false;
    } catch (e) {
      debugLog('[MULTI_WINDOW] Error opening room window: $e');
      return false;
    }
  }

  /// Open room in same window (navigation)
  static void openRoomInCurrentWindow({
    required String roomId,
    required String roomName,
    required String userId,
  }) {
    try {
      final url = _buildRoomUrl(roomId, roomName, userId);
      web.window.location.href = url;
      debugLog('[MULTI_WINDOW] Navigated to room: $roomId');
    } catch (e) {
      debugLog('[MULTI_WINDOW] Error navigating to room: $e');
    }
  }

  /// Close a specific room window
  static void closeRoomWindow(String roomId) {
    try {
      final window = _openWindows[roomId];
      if (window != null) {
        window.close();
        _openWindows.remove(roomId);
        debugLog('[MULTI_WINDOW] Closed room window: $roomId');
      }
    } catch (e) {
      debugLog('[MULTI_WINDOW] Error closing window: $e');
      _openWindows.remove(roomId);
    }
  }

  /// Check if room window is still open
  static bool isWindowOpen(String roomId) {
    final window = _openWindows[roomId];
    try {
      return window != null && !window.closed;
    } catch (e) {
      _openWindows.remove(roomId);
      return false;
    }
  }

  /// Get all open room windows (with cleanup of dead windows)
  static List<String> getOpenRooms() {
    final openRooms = <String>[];
    final deadRooms = <String>[];

    for (final entry in _openWindows.entries) {
      try {
        if (entry.value != null && !entry.value!.closed) {
          openRooms.add(entry.key);
        } else {
          deadRooms.add(entry.key);
        }
      } catch (e) {
        // Window reference is invalid
        deadRooms.add(entry.key);
      }
    }

    // Cleanup dead windows
    for (final roomId in deadRooms) {
      _openWindows.remove(roomId);
      debugLog('[MULTI_WINDOW] Cleaned up dead window for room: $roomId');
    }

    return openRooms;
  }

  /// Get count of open room windows
  static int getOpenRoomCount() {
    return getOpenRooms().length;
  }

  /// Check for collision (if multiple windows would open same room)
  /// Returns true if room is already open
  static bool hasOpenWindow(String roomId) {
    return getOpenRooms().contains(roomId);
  }

  /// Close all open room windows
  static void closeAllRooms() {
    for (final roomId in getOpenRooms()) {
      closeRoomWindow(roomId);
    }
  }

  /// Build room URL with parameters
  static String _buildRoomUrl(
    String roomId,
    String roomName,
    String userId,
  ) {
    final currentUrl = web.window.location.href;
    final baseUrl = _getBaseUrl(currentUrl);

    return '$baseUrl/room/$roomId?name=${Uri.encodeComponent(roomName)}&userId=$userId';
  }

  /// Extract base URL from current location
  static String _getBaseUrl(String href) {
    final uri = Uri.parse(href);
    // Include port only if non-standard (not 80/443)
    final portSuffix = (uri.port != 0 && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portSuffix';
  }

  /// Debug logging
  static void debugLog(String message) {
    // Only log in debug mode
    debugPrint(message);
  }
}


