class SimulationPhase {
  final String phase;

  SimulationPhase(this.phase);

  void start() {
    print("🧪 PHASE START: $phase");
  }

  void end() {
    print("🧪 PHASE END: $phase");
  }
}