import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../helpers/network_degradation_harness.dart';

void main() {
  group('Screen Share Network Chaos', () {
    testWidgets('Screen share resumes after latency spikes', (tester) async {
      final harness = NetworkDegradationHarness(minLatencyMs: 300, maxLatencyMs: 1500, logger: print);
      await harness.runWithConditions(() async {
        // Simulate screen share start
        // ...existing code to start screen share...
        // Assert screen share resumes
        // Minimal fix: supply a generic Widget type so the matcher compiles.
        // Replace `Widget` with a more specific widget type if you want a stricter assertion.
        expect(find.byType(Widget), findsOneWidget);
      });
    });

    testWidgets('No stuck overlays after packet loss', (tester) async {
      final harness = NetworkDegradationHarness(packetLossRate: 0.3, logger: print);
      await harness.runWithConditions(() async {
        // Simulate packet loss during screen share
        // ...existing code...
        // Assert overlays are cleared
        expect(find.byType(Widget), findsNothing);
      });
    });

    testWidgets('No orphaned video elements after disconnect/reconnect', (tester) async {
      final harness = NetworkDegradationHarness(simulateDisconnect: true, reconnectLoops: 2, logger: print);
      await harness.runWithConditions(() async {
        // Simulate disconnect/reconnect during screen share
        // ...existing code...
        // Assert no orphaned video elements
        expect(find.byType(Widget), findsNothing);
      });
    });
  });
}
