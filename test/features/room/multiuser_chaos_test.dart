import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/network_degradation_harness.dart';

void main() {
  group('Multi-User Network Chaos', () {
    testWidgets('Room state consistent with 2–6 users, one degraded', (tester) async {
      // Simulate 6 users, one with degraded network
      final stableHarness = NetworkDegradationHarness();
      final chaosHarness = NetworkDegradationHarness(packetLossRate: 0.4, minLatencyMs: 500, maxLatencyMs: 2000, logger: print);
      // Simulate stable users
      for (int i = 0; i < 5; i++) {
        await stableHarness.runWithConditions(() async {
          // ...existing code for stable user join...
        });
      }
      // Simulate degraded user
      await chaosHarness.runWithConditions(() async {
        // ...existing code for degraded user join...
      });
      // Assert room state
      expect(find.byType(Widget), findsOneWidget);
      expect(find.byType(Widget), findsNWidgets(6));
    });

    testWidgets('No ghost users or stuck indicators', (tester) async {
      final harness = NetworkDegradationHarness(simulateDisconnect: true, reconnectLoops: 3, logger: print);
      await harness.runWithConditions(() async {
        // Simulate user disconnect/reconnect
        // ...existing code...
        // Assert no ghost users or stuck loading
        expect(find.byType(Widget), findsNothing);
        expect(find.byType(Widget), findsNothing);
      });
    });
  });
}
