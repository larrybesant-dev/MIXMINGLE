class RuntimeTelemetry {
  static final Map<String, int> _listenerCounts = {};
  static final Map<String, int> _rebuildCounts = {};
  static final Map<String, DateTime> _lastEvent = {};

  // ─────────────────────────────
  // LISTENER TRACKING
  // ─────────────────────────────

  static void registerListener(String key) {
    _listenerCounts[key] = (_listenerCounts[key] ?? 0) + 1;
  }

  static void unregisterListener(String key) {
    _listenerCounts[key] = (_listenerCounts[key] ?? 1) - 1;
  }

  static Map<String, int> get listeners => _listenerCounts;

  // ─────────────────────────────
  // REBUILD TRACKING
  // ─────────────────────────────

  static void recordRebuild(String widget) {
    _rebuildCounts[widget] = (_rebuildCounts[widget] ?? 0) + 1;
    _lastEvent[widget] = DateTime.now();
  }

  static Map<String, int> get rebuilds => _rebuildCounts;

  static DateTime? lastEvent(String widget) => _lastEvent[widget];

  // ─────────────────────────────
  // RESET (for testing)
  // ─────────────────────────────

  static void reset() {
    _listenerCounts.clear();
    _rebuildCounts.clear();
    _lastEvent.clear();
  }
}
