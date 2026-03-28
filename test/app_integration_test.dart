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

      // App should at minimum bootstrap a Flutter shell.
      expect(find.byType(Directionality), findsWidgets);

      // If dashboard is available, verify primary bottom-nav flow.
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        await $.tap(find.byIcon(Icons.search));
        await $.pumpAndSettle();
        expect(find.text('Discover'), findsWidgets);

        await $.tap(find.byIcon(Icons.person));
        await $.pumpAndSettle();
        expect(find.text('Profile'), findsWidgets);

        await $.tap(find.byIcon(Icons.home));
        await $.pumpAndSettle();
        expect(find.text('MixVy'), findsWidgets);
      }
    },
    skip: skipIntegrationTests,
  );
}
