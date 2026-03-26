import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mixvy/main.dart' as app;
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  patrolWidgetTest(
    'Launches and navigates through main pages',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Verify Splash or Onboarding
      expect(find.text('Welcome'), findsOneWidget);

      // Navigate to Home
      await $.tap(find.byIcon(Icons.home));
      await $.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Navigate to Feed
      await $.tap(find.byIcon(Icons.dynamic_feed));
      await $.pumpAndSettle();
      expect(find.text('Feed'), findsOneWidget);

      // Navigate to Chat
      await $.tap(find.byIcon(Icons.chat));
      await $.pumpAndSettle();
      expect(find.text('Chat'), findsOneWidget);

      // Navigate to Payments
      await $.tap(find.byIcon(Icons.payment));
      await $.pumpAndSettle();
      expect(find.text('Payments'), findsOneWidget);

      // Navigate to Profile
      await $.tap(find.byIcon(Icons.person));
      await $.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
    },
    skip: skipIntegrationTests,
  );
}
