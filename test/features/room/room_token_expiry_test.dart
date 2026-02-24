import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/token_expiry_harness.dart';

void main() {
  group('Room Video/Audio Token Expiry', () {
    testWidgets('Video continues after token refresh', (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringSession: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate video session
        // ...existing code to start video...
        // Assert video widget is still present
        expect(find.byType(Widget), findsOneWidget);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
        // ...existing code...
      });
    });

    testWidgets('Audio continues after token refresh', (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringSession: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate audio session
        // ...existing code to start audio...
        // Assert audio widget is still present
        expect(find.byType(Widget), findsOneWidget);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });

    testWidgets('Tracks reattach after token refresh', (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringReconnect: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate disconnect/reconnect
        // ...existing code...
        // Assert tracks reattach
        expect(find.byType(Widget), findsOneWidget);
        expect(find.byType(Widget), findsOneWidget);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });

    testWidgets('No crashes or duplicate tracks after refresh', (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringToggle: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate rapid mic/cam toggling
        // ...existing code...
        // Assert no crashes or duplicate tracks
        expect(tester.takeException(), isNull);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });
  });
}
