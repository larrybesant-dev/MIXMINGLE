// lib/core/web/web_window_service_web.dart
// Web implementation — uses dart:js_interop + package:web
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Keeps track of opened windows so we can focus instead of re-opening.
final Map<String, web.Window?> _openWindows = {};

class WebWindowBridge {
  static void open({
    required String url,
    required String name,
    int width = 400,
    int height = 600,
    int left = 100,
    int top = 100,
  }) {
    if (!kIsWeb) return;

    // If the window is already open, focus it instead of opening a new one.
    final existing = _openWindows[name];
    if (existing != null) {
      try {
        existing.focus();
        return;
      } catch (_) {
        // Window may have been closed; fall through to open a new one.
        _openWindows.remove(name);
      }
    }

    final features =
        'width=$width,height=$height,left=$left,top=$top,'
        'resizable=yes,scrollbars=yes,status=no,toolbar=no,menubar=no';

    final w = web.window.open(url, name, features);
    if (w != null) {
      _openWindows[name] = w;
      debugPrint('[WebWindow] Opened $name → $url');
    } else {
      // Pop-up blocked: fall back to same-tab navigation
      debugPrint('[WebWindow] Pop-up blocked for $name, navigating in-tab');
      web.window.location.href = url;
    }
  }

  static void closeAll() {
    for (final w in _openWindows.values) {
      try {
        w?.close();
      } catch (_) {}
    }
    _openWindows.clear();
  }
}
