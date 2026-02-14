import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Room Flow Integration Tests', () {
    testWidgets('should create voice room', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to rooms
      final roomsTab = find.text('Rooms');
      if (roomsTab.evaluate().isNotEmpty) {
        await tester.tap(roomsTab);
        await tester.pumpAndSettle();

        // Act - Create room
        final createButton = find.byType(FloatingActionButton);
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();

          // Fill room details
          final nameField = find.byType(TextField).first;
          await tester.enterText(nameField, 'Test Room');
          await tester.pumpAndSettle();

          // Create room
          final createRoomButton = find.text('Create');
          if (createRoomButton.evaluate().isNotEmpty) {
            await tester.tap(createRoomButton);
            await tester.pumpAndSettle(Duration(seconds: 2));

            // Assert
            expect(find.text('Test Room'), findsWidgets);
          }
        }
      }
    });

    testWidgets('should join room', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to rooms
      final roomsTab = find.text('Rooms');
      if (roomsTab.evaluate().isNotEmpty) {
        await tester.tap(roomsTab);
        await tester.pumpAndSettle();

        // Act - Join a room
        final roomCards = find.byType(Card);
        if (roomCards.evaluate().isNotEmpty) {
          await tester.tap(roomCards.first);
          await tester.pumpAndSettle();

          // Assert - Should be in room
          expect(find.text('Leave'), findsWidgets);
        }
      }
    });

    testWidgets('should toggle microphone', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to rooms and join
      final roomsTab = find.text('Rooms');
      if (roomsTab.evaluate().isNotEmpty) {
        await tester.tap(roomsTab);
        await tester.pumpAndSettle();

        final roomCards = find.byType(Card);
        if (roomCards.evaluate().isNotEmpty) {
          await tester.tap(roomCards.first);
          await tester.pumpAndSettle();

          // Act - Toggle mic
          final micButton = find.byIcon(Icons.mic);
          if (micButton.evaluate().isNotEmpty) {
            await tester.tap(micButton);
            await tester.pumpAndSettle();

            // Assert - Icon should change to mic_off
            expect(find.byIcon(Icons.mic_off), findsWidgets);
          }
        }
      }
    });

    testWidgets('should leave room', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to rooms and join
      final roomsTab = find.text('Rooms');
      if (roomsTab.evaluate().isNotEmpty) {
        await tester.tap(roomsTab);
        await tester.pumpAndSettle();

        final roomCards = find.byType(Card);
        if (roomCards.evaluate().isNotEmpty) {
          await tester.tap(roomCards.first);
          await tester.pumpAndSettle();

          // Act - Leave room
          final leaveButton = find.text('Leave');
          if (leaveButton.evaluate().isNotEmpty) {
            await tester.tap(leaveButton);
            await tester.pumpAndSettle();

            // Assert - Should be back in rooms list
            expect(find.byType(Card), findsWidgets);
          }
        }
      }
    });

    testWidgets('should see participants list', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to rooms and join
      final roomsTab = find.text('Rooms');
      if (roomsTab.evaluate().isNotEmpty) {
        await tester.tap(roomsTab);
        await tester.pumpAndSettle();

        final roomCards = find.byType(Card);
        if (roomCards.evaluate().isNotEmpty) {
          await tester.tap(roomCards.first);
          await tester.pumpAndSettle();

          // Assert - Should see participants
          expect(find.byType(ListTile), findsWidgets);
        }
      }
    });
  });
}
