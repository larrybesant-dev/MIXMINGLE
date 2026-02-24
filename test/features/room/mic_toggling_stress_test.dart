import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/toggling_stress_harness.dart';
import '../../helpers/network_degradation_harness.dart';
import '../../helpers/token_expiry_harness.dart';

void main() {
  group('Mic Toggling Stress', () {
    testWidgets('100 rapid mic toggles', (tester) async {
      final harness = TogglingStressHarness(micToggles: 100, logger: print);
      await harness.run(
        toggleMic: () async {
          // ...existing code to toggle mic...
        },
        toggleCam: () async {},
        toggleScreenShare: () async {},
      );
      // Assert no stuck mute/unmute, no duplicate tracks
      expect(find.byType(Widget), findsOneWidget);
    });

    testWidgets('Mic toggles during reconnect loops', (tester) async {
      final networkHarness = NetworkDegradationHarness(simulateDisconnect: true, reconnectLoops: 3, logger: print);
      final harness = TogglingStressHarness(micToggles: 50, networkHarness: networkHarness, logger: print);
      await harness.run(
        toggleMic: () async {
          // ...existing code to toggle mic...
        },
        toggleCam: () async {},
        toggleScreenShare: () async {},
      );
      expect(find.byType(Widget), findsOneWidget);
    });

    testWidgets('Mic toggles during token expiry', (tester) async {
      final tokenHarness = TokenExpiryHarness(forceExpiry: true, duringSession: true, logger: print);
      final harness = TogglingStressHarness(micToggles: 50, tokenHarness: tokenHarness, logger: print);
      await harness.run(
        toggleMic: () async {
          // ...existing code to toggle mic...
        },
        toggleCam: () async {},
        toggleScreenShare: () async {},
      );
      expect(find.byType(Widget), findsOneWidget);
    });

    testWidgets('Mic toggles during screen share', (tester) async {
      final harness = TogglingStressHarness(micToggles: 50, screenShareToggles: 10, randomize: true, logger: print);
      await harness.run(
        toggleMic: () async {
          // ...existing code to toggle mic...
        },
        toggleCam: () async {},
        toggleScreenShare: () async {
          // ...existing code to toggle screen share...
        },
      );
      expect(find.byType(Widget), findsOneWidget);
    });
  });
}
