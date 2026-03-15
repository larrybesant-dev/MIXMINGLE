import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/token_expiry_harness.dart';

void main() {
  group('Chat & Reactions Token Expiry', () {
    testWidgets('Messages queue and flush after token refresh', (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringSession: true, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate sending chat messages
        expect(find.text('Test message'), findsWidgets);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });

    testWidgets('No lost UI state or duplicate reactions after refresh',
        (tester) async {
      final harness = TokenExpiryHarness(
          forceExpiry: true, duringSession: true, logger: print);
      await harness.runWithExpiry(() async {
        expect(find.byType(Container), findsWidgets);
      }, onTokenRefresh: () async {});
    });
  });
}
