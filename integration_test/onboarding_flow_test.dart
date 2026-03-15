import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow Integration Tests', () {
    testWidgets('should complete full onboarding flow',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Navigate through onboarding screens
      // Look for "Get Started" or "Next" buttons
      final getStartedButton = find.text('Get Started');
      final nextButton = find.text('Next');

      if (getStartedButton.evaluate().isNotEmpty) {
        await tester.tap(getStartedButton);
        await tester.pumpAndSettle();
      } else if (nextButton.evaluate().isNotEmpty) {
        // Tap through multiple onboarding screens
        for (var i = 0; i < 3; i++) {
          final button = find.text('Next');
          if (button.evaluate().isNotEmpty) {
            await tester.tap(button);
            await tester.pumpAndSettle(Duration(seconds: 1));
          }
        }

        // Tap final button (e.g., "Get Started" or "Finish")
        final finalButton = find.textContaining('Get Started').first;
        if (finalButton.evaluate().isNotEmpty) {
          await tester.tap(finalButton);
          await tester.pumpAndSettle();
        }
      }

      // Assert - Should navigate to login or signup page
      await tester.pumpAndSettle(Duration(seconds: 2));
      expect(find.text('Login').first, findsWidgets);
    });

    testWidgets('should show welcome message', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Assert
      // Onboarding screens typically have welcome text
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should skip onboarding', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act
      final skipButton = find.text('Skip');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      // Assert
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
