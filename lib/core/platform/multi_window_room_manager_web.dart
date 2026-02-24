// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Multi-window room manager for Flutter Web
class MultiWindowRoomManager {
  /// Cache of open room windows
  static final Map<String, web.Window?> _openWindows = {};

  /// Open a room in a new browser window/tab.
  /// Returns true if window opened successfully.
  /// If room is already open, focuses that window instead (collision detection).
  static bool openRoomWindow({
    required String roomId,
    required String roomName,
    required String userId,
    String windowName = '_blank',
  }) {
    try {
      if (isWindowOpen(roomId)) {
        final existingWindow = _openWindows[roomId];
        if (existingWindow != null) {
          try {
            existingWindow.focus();
            debugPrint('[MULTI_WINDOW] Focused existing room window: $roomId');
            return true;
          } catch (e) {
            debugPrint('[MULTI_WINDOW] Could not focus window: $e');
          }
        }
      }

      final url = _buildRoomUrl(roomId, roomName, userId);
      final window = web.window.open(url, windowName, '');

      if (window != null) {
        _openWindows[roomId] = window;
        debugPrint('[MULTI_WINDOW] Opened room: $roomId in new window');
        return true;
      }

      debugPrint('[MULTI_WINDOW] Failed to open window for room: $roomId');
      return false;
    } catch (e) {
      debugPrint('[MULTI_WINDOW] Error opening room window: $e');
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
      debugPrint('[MULTI_WINDOW] Navigated to room: $roomId');
    } catch (e) {
      debugPrint('[MULTI_WINDOW] Error navigating to room: $e');
    }
  }

  /// Close a specific room window
  static void closeRoomWindow(String roomId) {
    try {
      final window = _openWindows[roomId];
      if (window != null) {
        window.close();
        _openWindows.remove(roomId);
        debugPrint('[MULTI_WINDOW] Closed room window: $roomId');
      }
    } catch (e) {
      debugPrint('[MULTI_WINDOW] Error closing window: $e');
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
        deadRooms.add(entry.key);
      }
    }

    for (final roomId in deadRooms) {
      _openWindows.remove(roomId);
    }

    return openRooms;
  }

  static int getOpenRoomCount() => getOpenRooms().length;
  static bool hasOpenWindow(String roomId) => getOpenRooms().contains(roomId);

  static void closeAllRooms() {
    for (final roomId in getOpenRooms()) {
      closeRoomWindow(roomId);
    }
  }

  static String _buildRoomUrl(String roomId, String roomName, String userId) {
    final currentUrl = web.window.location.href;
    final baseUrl = _getBaseUrl(currentUrl);
    return '$baseUrl/room/$roomId?name=${Uri.encodeComponent(roomName)}&userId=$userId';
  }

  static String _getBaseUrl(String href) {
    final uri = Uri.parse(href);
    final portSuffix = (uri.port != 0 && uri.port != 80 && uri.port != 443)
        ? ':${uri.port}'
        : '';
    return '${uri.scheme}://${uri.host}$portSuffix';
  }
}
