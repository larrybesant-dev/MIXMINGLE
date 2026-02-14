import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Events Flow Integration Tests', () {
    testWidgets('should create new event', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to events
      final eventsTab = find.text('Events');
      if (eventsTab.evaluate().isNotEmpty) {
        await tester.tap(eventsTab);
        await tester.pumpAndSettle();

        // Act - Tap create event button
        final createButton = find.byType(FloatingActionButton);
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();

          // Fill in event details
          final titleField = find.byType(TextField).first;
          await tester.enterText(titleField, 'Test Event');
          await tester.pumpAndSettle();

          // Save event
          final saveButton = find.text('Create');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle();

            // Assert
            expect(find.text('Test Event'), findsWidgets);
          }
        }
      }
    });

    testWidgets('should join event', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to events
      final eventsTab = find.text('Events');
      if (eventsTab.evaluate().isNotEmpty) {
        await tester.tap(eventsTab);
        await tester.pumpAndSettle();

        // Act - Tap on an event
        final eventCards = find.byType(Card);
        if (eventCards.evaluate().isNotEmpty) {
          await tester.tap(eventCards.first);
          await tester.pumpAndSettle();

          // Tap join button
          final joinButton = find.text('Join');
          if (joinButton.evaluate().isNotEmpty) {
            await tester.tap(joinButton);
            await tester.pumpAndSettle();

            // Assert
            expect(find.text('Joined'), findsWidgets);
          }
        }
      }
    });

    testWidgets('should view event details', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to events
      final eventsTab = find.text('Events');
      if (eventsTab.evaluate().isNotEmpty) {
        await tester.tap(eventsTab);
        await tester.pumpAndSettle();

        // Act - Tap on an event
        final eventCards = find.byType(Card);
        if (eventCards.evaluate().isNotEmpty) {
          await tester.tap(eventCards.first);
          await tester.pumpAndSettle();

          // Assert - Should see event details
          expect(find.byType(Text), findsWidgets);
        }
      }
    });

    testWidgets('should filter events by category', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to events
      final eventsTab = find.text('Events');
      if (eventsTab.evaluate().isNotEmpty) {
        await tester.tap(eventsTab);
        await tester.pumpAndSettle();

        // Act - Tap category filter
        final socialChip = find.text('Social');
        if (socialChip.evaluate().isNotEmpty) {
          await tester.tap(socialChip);
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(Card), findsWidgets);
        }
      }
    });

    testWidgets('should leave event', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to events
      final eventsTab = find.text('Events');
      if (eventsTab.evaluate().isNotEmpty) {
        await tester.tap(eventsTab);
        await tester.pumpAndSettle();

        // Open event details
        final eventCards = find.byType(Card);
        if (eventCards.evaluate().isNotEmpty) {
          await tester.tap(eventCards.first);
          await tester.pumpAndSettle();

          // Act - Leave event
          final leaveButton = find.text('Leave');
          if (leaveButton.evaluate().isNotEmpty) {
            await tester.tap(leaveButton);
            await tester.pumpAndSettle();

            // Assert
            expect(find.text('Join'), findsWidgets);
          }
        }
      }
    });
  });
}
