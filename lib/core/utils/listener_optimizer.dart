import 'dart:async';
import 'package:flutter/foundation.dart';

/// Optimizes Firestore listeners for web performance
/// Debounces rapid updates to prevent frame drops
class ListenerOptimizer {
  static final ListenerOptimizer _instance = ListenerOptimizer._internal();
  factory ListenerOptimizer() => _instance;
  ListenerOptimizer._internal();

  final Map<String, Timer> _debounceTimers = {};
  final Duration _debounceDelay = const Duration(milliseconds: 100);

  /// Debounce a listener callback
  void debounce(
    String key,
    Function callback, {
    Duration? delay,
  }) {
    // Cancel existing timer
    _debounceTimers[key]?.cancel();

    // Set new timer
    _debounceTimers[key] = Timer(delay ?? _debounceDelay, () {
      if (kDebugMode) {
        debugPrint('[ListenerOptimizer] Executing debounced callback: $key');
      }
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Cancel pending debounced callback
  void cancel(String key) {
    _debounceTimers[key]?.cancel();
    _debounceTimers.remove(key);
  }

  /// Cancel all pending debounced callbacks
  void cancelAll() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  /// Dispose and clean up resources
  void dispose() {
    cancelAll();
  }
}
