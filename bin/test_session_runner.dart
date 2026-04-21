import 'package:mixvy/dev/load_simulator.dart';
import 'package:mixvy/dev/test_session_controller.dart';
import 'package:mixvy/observability/simulation_phase.dart';

void main() {
  TestSessionController.startSession("ROOM_LOAD_VALIDATION");

  final typingStormPhase = SimulationPhase("typing_storm");
  typingStormPhase.start();
  LoadSimulator.runTypingStorm("room_1");
  typingStormPhase.end();

  final messageBurstPhase = SimulationPhase("message_burst");
  messageBurstPhase.start();
  LoadSimulator.runMessageBurst("room_1");
  messageBurstPhase.end();

  final presenceFlapPhase = SimulationPhase("presence_flap");
  presenceFlapPhase.start();
  LoadSimulator.runPresenceFlap("user_1");
  presenceFlapPhase.end();

  Future.delayed(const Duration(seconds: 5), () {
    TestSessionController.endSession();
  });
}