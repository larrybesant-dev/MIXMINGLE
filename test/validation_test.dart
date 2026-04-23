import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/dev/test_session_controller.dart';
import 'package:mixvy/dev/load_simulator.dart';
import 'package:mixvy/observability/event_timeline.dart';
import 'package:mixvy/observability/runtime_telemetry.dart';

void main() {
  test('Validation Test: ROOM_LOAD_VALIDATION', () async {
    TestSessionController.startSession("ROOM_LOAD_VALIDATION");

    final ctx = TestSessionController.context!;
    final sim = LoadSimulator(EventTimeline());
    sim.runTypingStorm("room_1", ctx);
    sim.runmessageBurst("room_1", ctx);
    sim.runPresenceFlap("user_1", ctx);

    await Future.delayed(const Duration(seconds: 5));

    TestSessionController.endSession();

    // Assertions can be added here to validate results
    expect(RuntimeTelemetry.snapshotListeners().isNotEmpty, true);
    expect(RuntimeTelemetry.snapshotRebuilds().isNotEmpty, true);
  });
}
