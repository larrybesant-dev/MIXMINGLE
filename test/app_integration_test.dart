import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mixvy/main.dart' as app;
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });
  patrolWidgetTest('Launches and navigates through main pages', ($) async {
    app.main();
    await $.pumpAndSettle();

    // Verify Splash or Onboarding
    expect($(find.text('Welcome')), findsOneWidget);

    // Navigate to Home
    await $(find.byIcon(Icons.home)).tap();
    await $.pumpAndSettle();
    expect($(find.text('Home')), findsOneWidget);

    // Navigate to Feed
    await $(find.byIcon(Icons.dynamic_feed)).tap();
    await $.pumpAndSettle();
    expect($(find.text('Feed')), findsOneWidget);

    // Navigate to Chat
    await $(find.byIcon(Icons.chat)).tap();
    await $.pumpAndSettle();
    expect($(find.text('Chat')), findsOneWidget);

    // Navigate to Payments
    await $(find.byIcon(Icons.payment)).tap();
    await $.pumpAndSettle();
    expect($(find.text('Payments')), findsOneWidget);

    // Navigate to Profile
    await $(find.byIcon(Icons.person)).tap();
    await $.pumpAndSettle();
    expect($(find.text('Profile')), findsOneWidget);
  });
}
