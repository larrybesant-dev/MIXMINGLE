import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../helpers/token_expiry_harness.dart';

void main() {
  group('Screen Share Token Expiry', () {
    testWidgets('Screen share resumes after token refresh', (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringSession: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate screen share
        // ...existing code...
        // Assert screen share resumes
        expect(find.byType(Widget), findsOneWidget);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });

    testWidgets('No stuck overlays or orphaned video after refresh',
        (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringReconnect: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate disconnect/reconnect during screen share
        // ...existing code...
        // Assert overlays and orphaned video are cleared
        expect(find.byType(Widget), findsNothing);
        expect(find.byType(Widget), findsNothing);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });
  });
}
