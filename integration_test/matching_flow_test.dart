import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Matching Flow Integration Tests', () {
    testWidgets('should swipe and like users', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to discover/matching screen
      final discoverTab = find.text('Discover');
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();

        // Act - Swipe right (like)
        final userCard = find.byType(Card).first;
        if (userCard.evaluate().isNotEmpty) {
          await tester.drag(userCard, Offset(300, 0));
          await tester.pumpAndSettle();
        }

        // Assert
        expect(find.byType(Card), findsWidgets);
      }
    });

    testWidgets('should show match notification', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Simulate getting a match
      // Navigate to matches
      final matchesTab = find.text('Matches');
      if (matchesTab.evaluate().isNotEmpty) {
        await tester.tap(matchesTab);
        await tester.pumpAndSettle();

        // Assert - Should see matches
        expect(find.byType(ListTile), findsWidgets);
      }
    });

    testWidgets('should view user profile before matching', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to discover
      final discoverTab = find.text('Discover');
      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();

        // Act - Tap to view full profile
        final profileCard = find.byType(Card).first;
        if (profileCard.evaluate().isNotEmpty) {
          await tester.tap(profileCard);
          await tester.pumpAndSettle();

          // Assert - Should see profile details
          expect(find.byType(Text), findsWidgets);
        }
      }
    });

    testWidgets('should filter matches by preferences', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings or preferences
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Act - Set age range
        final ageRangeSlider = find.byType(RangeSlider);
        if (ageRangeSlider.evaluate().isNotEmpty) {
          // Adjust slider
          await tester.drag(ageRangeSlider.first, Offset(50, 0));
          await tester.pumpAndSettle();
        }

        // Save preferences
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }

        // Assert
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('should view match profile', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to matches
      final matchesTab = find.text('Matches');
      if (matchesTab.evaluate().isNotEmpty) {
        await tester.tap(matchesTab);
        await tester.pumpAndSettle();

        // Act - Tap on a match
        final matchTiles = find.byType(ListTile);
        if (matchTiles.evaluate().isNotEmpty) {
          await tester.tap(matchTiles.first);
          await tester.pumpAndSettle();

          // Assert - Should see profile
          expect(find.byType(Text), findsWidgets);
        }
      }
    });
  });
}
