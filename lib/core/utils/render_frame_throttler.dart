import 'dart:async';
import 'package:flutter/foundation.dart';

/// Throttles expensive operations to maintain 60 FPS
/// Prevents frame drops from excessive state updates
class RenderFrameThrottler {
  static final RenderFrameThrottler _instance =
      RenderFrameThrottler._internal();
  factory RenderFrameThrottler() => _instance;
  RenderFrameThrottler._internal();

  Timer? _throttleTimer;
  final Duration _frameTime = const Duration(milliseconds: 16); // ~60 FPS
  final List<Function> _pendingCallbacks = [];
  bool _processing = false;

  /// Throttle a callback to execute at most once per frame
  void throttle(Function callback, {String? label}) {
    _pendingCallbacks.add(callback);

    if (_processing) {
      if (kDebugMode) {
        debugPrint(
            '[RenderFrameThrottler] Queueing ${label ?? "callback"}. Queue size: ${_pendingCallbacks.length}');
      }
      return;
    }

    _processCallbacks(label);
  }

  void _processCallbacks(String? label) {
    if (_processing || _pendingCallbacks.isEmpty) return;

    _processing = true;

    try {
      final callback = _pendingCallbacks.removeAt(0);
      if (kDebugMode) {
        debugPrint('[RenderFrameThrottler] Executing ${label ?? "callback"}');
      }
      callback();
    } catch (e) {
      debugPrint('[RenderFrameThrottler] Error executing callback: $e');
    }

    // Schedule next batch
    _throttleTimer = Timer(_frameTime, () {
      _processing = false;
      if (_pendingCallbacks.isNotEmpty) {
        _processCallbacks(label);
      }
    });
  }

  /// Get pending callback count
  int get pendingCallbacks => _pendingCallbacks.length;

  /// Clear all pending callbacks
  void clear() {
    _pendingCallbacks.clear();
  }

  /// Dispose and clean up
  void dispose() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _pendingCallbacks.clear();
  }
}
