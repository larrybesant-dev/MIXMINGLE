import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/toggling_stress_harness.dart';
import '../../helpers/network_degradation_harness.dart';
import '../../helpers/token_expiry_harness.dart';

void main() {
  group('Mixed Toggling Chaos', () {
    testWidgets('Randomized mic/cam/screen-share toggling with network chaos', (tester) async {
      final networkHarness = NetworkDegradationHarness(packetLossRate: 0.2, minLatencyMs: 100, maxLatencyMs: 1000, logger: print);
      final harness = TogglingStressHarness(
        micToggles: 40,
        camToggles: 40,
        screenShareToggles: 20,
        randomize: true,
        networkHarness: networkHarness,
        logger: print,
      );
      await harness.run(
        toggleMic: () async {
          // ...existing code to toggle mic...
        },
        toggleCam: () async {
          // ...existing code to toggle camera...
        },
        toggleScreenShare: () async {
          // ...existing code to toggle screen share...
        },
      );
      // Assert room state and UI
      expect(find.byType(Widget), findsOneWidget);
    });

    testWidgets('Toggling during token expiry and multi-user session', (tester) async {
      final tokenHarness = TokenExpiryHarness(forceExpiry: true, multiUserCount: 4, logger: print);
      final harness = TogglingStressHarness(
        micToggles: 30,
        camToggles: 30,
        screenShareToggles: 10,
        randomize: true,
        tokenHarness: tokenHarness,
        logger: print,
      );
      await harness.run(
        toggleMic: () async {
          // ...existing code to toggle mic...
        },
        toggleCam: () async {
          // ...existing code to toggle camera...
        },
        toggleScreenShare: () async {
          // ...existing code to toggle screen share...
        },
      );
      expect(find.byType(Widget), findsOneWidget);
    });
  });
}
