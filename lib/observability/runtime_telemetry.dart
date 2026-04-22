import 'package:flutter/foundation.dart';

class SimulationContext {
  final String phase;

  SimulationContext(this.phase);
}

class RuntimeTelemetry {
  static final Map<String, int> _listenerCounts = {};
  static final Map<String, int> _rebuildCounts = {};
  static final Map<String, DateTime> _lastEvent = {};

  // ─────────────────────────────
  // LISTENER TRACKING
  // ─────────────────────────────

  static void registerListener(String key) {
    _listenerCounts.update(key, (v) => v + 1, ifAbsent: () => 1);
    debugPrint("Listener registered: $key, Total: ${_listenerCounts[key]}");
  }

  static void unregisterListener(String key) {
    if (_listenerCounts.containsKey(key)) {
      final next = _listenerCounts[key]! - 1;
      if (next <= 0) {
        _listenerCounts.remove(key);
      } else {
        _listenerCounts[key] = next;
      }
      debugPrint("Listener unregistered: $key, Remaining: ${_listenerCounts[key] ?? 0}");
    }
  }

  static Map<String, int> snapshotListeners() => Map.from(_listenerCounts);

  // ─────────────────────────────
  // REBUILD TRACKING
  // ─────────────────────────────

  static void recordRebuild(String widget, [SimulationContext? ctx]) {
    _rebuildCounts[widget] = (_rebuildCounts[widget] ?? 0) + 1;
    _lastEvent[widget] = DateTime.now();
    if (ctx != null) {
      debugPrint("[${ctx.phase}] Rebuild recorded for: $widget, Total: ${_rebuildCounts[widget]}");
    }
  }

  static Map<String, int> snapshotRebuilds() => Map.from(_rebuildCounts);

  static DateTime? lastEvent(String widget) => _lastEvent[widget];

  // ─────────────────────────────
  // RESET (for testing)
  // ─────────────────────────────

  static void reset() {
    _listenerCounts.clear();
    _rebuildCounts.clear();
    _lastEvent.clear();
  }

  // Public getters for listeners and rebuilds
  static Map<String, int> get listeners => Map.unmodifiable(_listenerCounts);
  static Map<String, int> get rebuilds => Map.unmodifiable(_rebuildCounts);
}
