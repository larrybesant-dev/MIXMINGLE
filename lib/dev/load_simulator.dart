import 'dart:async';
import '../observability/runtime_telemetry.dart';
import '../observability/event_timeline.dart';
import '../observability/simulation_phase.dart';

class LoadSimulator {
  static void runTypingStorm(String roomId) {
    SimulationPhase.start("typing_storm");
    print("Running typing storm for room: \$roomId");
    for (int i = 0; i < 20; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        EventTimeline.record("SIM_EVENT", "typing:\$roomId");
        RuntimeTelemetry.recordRebuild("SIM:typing:\$roomId");
      });
    }
    SimulationPhase.end();
  }

  static void runMessageBurst(String roomId) {
    SimulationPhase.start("message_burst");
    print("Running message burst for room: \$roomId");
    for (int i = 0; i < 30; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        EventTimeline.record("SIM_EVENT", "message:\$roomId");
        RuntimeTelemetry.recordRebuild("SIM:message:\$roomId");
      });
    }
    SimulationPhase.end();
  }

  static void runPresenceFlap(String userId) {
    SimulationPhase.start("presence_flap");
    print("Running presence flap for user: \$userId");
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        EventTimeline.record("SIM_EVENT", "presence:\$userId");
        RuntimeTelemetry.recordRebuild("SIM:presence:\$userId");
      });
    }
    SimulationPhase.end();
  }
}