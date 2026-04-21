import 'package:test/test.dart';
import '../lib/dev/test_session_controller.dart';
import '../lib/dev/load_simulator.dart';
import '../lib/observability/runtime_telemetry.dart';

void main() {
  test('Validation Test: ROOM_LOAD_VALIDATION', () async {
    TestSessionController.startSession("ROOM_LOAD_VALIDATION");

    final ctx = TestSessionController.context!;

    LoadSimulator.runTypingStorm("room_1", ctx);
    LoadSimulator.runMessageBurst("room_1", ctx);
    LoadSimulator.runPresenceFlap("user_1", ctx);

    await Future.delayed(const Duration(seconds: 5));

    TestSessionController.endSession();

    // Assertions can be added here to validate results
    expect(RuntimeTelemetry.snapshotListeners().isNotEmpty, true);
    expect(RuntimeTelemetry.snapshotRebuilds().isNotEmpty, true);
  });
}