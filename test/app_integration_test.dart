import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/onboarding/onboarding_screen.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  testWidgets(
    'Onboarding renders and advances pages',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Directionality), findsWidgets);
      expect(find.text('Step Into The Hottest Rooms'), findsOneWidget);

      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      expect(find.text('Find Your Night Crew Fast'), findsOneWidget);
    },
  );
}
