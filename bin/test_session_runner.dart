import 'package:mixvy/dev/load_simulator.dart';
import 'package:mixvy/dev/test_session_controller.dart';
import 'package:mixvy/observability/simulation_phase.dart';

void main() {
  TestSessionController.startSession("ROOM_LOAD_VALIDATION");

  SimulationPhase.start("typing_storm");
  LoadSimulator.runTypingStorm("room_1");
  SimulationPhase.end();

  SimulationPhase.start("message_burst");
  LoadSimulator.runMessageBurst("room_1");
  SimulationPhase.end();

  SimulationPhase.start("presence_flap");
  LoadSimulator.runPresenceFlap("user_1");
  SimulationPhase.end();

  Future.delayed(const Duration(seconds: 5), () {
    TestSessionController.endSession();
  });
}