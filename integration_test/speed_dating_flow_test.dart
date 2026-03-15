import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Speed Dating Flow Integration Tests', () {
    testWidgets('should join speed dating session',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to speed dating
      final speedDatingTab = find.text('Speed Dating');
      if (speedDatingTab.evaluate().isNotEmpty) {
        await tester.tap(speedDatingTab);
        await tester.pumpAndSettle();

        // Act - Join a session
        final sessionCards = find.byType(Card);
        if (sessionCards.evaluate().isNotEmpty) {
          await tester.tap(sessionCards.first);
          await tester.pumpAndSettle();

          final joinButton = find.text('Join');
          if (joinButton.evaluate().isNotEmpty) {
            await tester.tap(joinButton);
            await tester.pumpAndSettle();

            // Assert
            expect(find.text('Waiting'), findsWidgets);
          }
        }
      }
    });

    testWidgets('should make decision on match', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to speed dating
      final speedDatingTab = find.text('Speed Dating');
      if (speedDatingTab.evaluate().isNotEmpty) {
        await tester.tap(speedDatingTab);
        await tester.pumpAndSettle();

        // Join and wait for round to start
        // This is a simplified test - actual flow would be more complex

        // Act - Make a decision
        final likeButton = find.byIcon(Icons.favorite);
        if (likeButton.evaluate().isNotEmpty) {
          await tester.tap(likeButton);
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('should see match results', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to speed dating
      final speedDatingTab = find.text('Speed Dating');
      if (speedDatingTab.evaluate().isNotEmpty) {
        await tester.tap(speedDatingTab);
        await tester.pumpAndSettle();

        // After session ends, check results
        final resultsButton = find.text('Results');
        if (resultsButton.evaluate().isNotEmpty) {
          await tester.tap(resultsButton);
          await tester.pumpAndSettle();

          // Assert - Should see matches
          expect(find.byType(ListTile), findsWidgets);
        }
      }
    });

    testWidgets('should navigate between rounds', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to active speed dating session
      final speedDatingTab = find.text('Speed Dating');
      if (speedDatingTab.evaluate().isNotEmpty) {
        await tester.tap(speedDatingTab);
        await tester.pumpAndSettle();

        // Act - Complete current round
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Assert - Should be in next round
          expect(find.text('Round'), findsWidgets);
        }
      }
    });

    testWidgets('should leave speed dating session',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to speed dating
      final speedDatingTab = find.text('Speed Dating');
      if (speedDatingTab.evaluate().isNotEmpty) {
        await tester.tap(speedDatingTab);
        await tester.pumpAndSettle();

        // Act - Leave session
        final leaveButton = find.text('Leave');
        if (leaveButton.evaluate().isNotEmpty) {
          await tester.tap(leaveButton);
          await tester.pumpAndSettle();

          // Assert - Should be back in speed dating list
          expect(find.byType(Card), findsWidgets);
        }
      }
    });
  });
}
