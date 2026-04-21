class SimulationPhase {
  static String? _currentPhase;

  static void start(String phase) {
    _currentPhase = phase;
    print("🧪 PHASE START: $phase");
  }

  static void end() {
    print("🧪 PHASE END: $_currentPhase");
    _currentPhase = null;
  }

  static String get current {
    print("Current phase: $_currentPhase");
    return _currentPhase ?? "UNKNOWN";
  }
}