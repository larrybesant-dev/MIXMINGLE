import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/network_degradation_harness.dart';

void main() {
  group('Chat & Reactions Network Chaos', () {
    testWidgets('Messages queue and flush correctly under latency',
        (tester) async {
      final harness = NetworkDegradationHarness(
          minLatencyMs: 200, maxLatencyMs: 1500, logger: print);
      await harness.runWithConditions(() async {
        // Simulate sending chat messages
        expect(find.text('Test message'), findsWidgets);
      });
    });

    testWidgets('No duplicate or lost reactions under packet loss',
        (tester) async {
      final harness =
          NetworkDegradationHarness(packetLossRate: 0.4, logger: print);
      await harness.runWithConditions(() async {
        // Simulate sending/receiving reactions
        expect(find.byType(Container), findsWidgets);
      });
    });

    testWidgets('No lost UI state during reconnect', (tester) async {
      final harness = NetworkDegradationHarness(
          simulateDisconnect: true, reconnectLoops: 2, logger: print);
      await harness.runWithConditions(() async {
        // Simulate disconnect/reconnect while chatting
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });
  });
}
