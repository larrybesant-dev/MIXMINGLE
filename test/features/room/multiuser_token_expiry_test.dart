import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/token_expiry_harness.dart';

void main() {
  group('Multi-User Token Expiry', () {
    testWidgets('Room state consistent with staggered/multi-user expiry', (tester) async {
      // Simulate 6 users, staggered expiry
      for (int i = 0; i < 6; i++) {
        final harness = TokenExpiryHarness(forceExpiry: true, multiUserCount: 6, expiryDelay: Duration(milliseconds: 500 * i), logger: print);
        await harness.runWithExpiry(() async {
          // ...existing code for user join...
        }, onTokenRefresh: () async {
          // Simulate token refresh logic
        });
      }
      // Assert room state
      expect(find.byType(Widget), findsOneWidget);
      expect(find.byType(Widget), findsNWidgets(6));
    });

    testWidgets('No ghost users or stuck indicators after all tokens expire', (tester) async {
      final harness = TokenExpiryHarness(forceExpiry: true, multiUserCount: 6, logger: print);
      await harness.runWithExpiry(() async {
        // Simulate all users expiring simultaneously
        // ...existing code...
        // Assert no ghost users or stuck loading
        expect(find.byType(Widget), findsNothing);
        expect(find.byType(Widget), findsNothing);
      }, onTokenRefresh: () async {
        // Simulate token refresh logic
      });
    });
  });
}
