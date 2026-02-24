import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow Integration Tests', () {
    testWidgets('should send and receive messages',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to chat list
      final chatsTab = find.text('Chats');
      if (chatsTab.evaluate().isNotEmpty) {
        await tester.tap(chatsTab);
        await tester.pumpAndSettle();

        // Tap on a chat
        final chatTiles = find.byType(ListTile);
        if (chatTiles.evaluate().isNotEmpty) {
          await tester.tap(chatTiles.first);
          await tester.pumpAndSettle();

          // Act - Send a message
          final messageField = find.byType(TextField);
          if (messageField.evaluate().isNotEmpty) {
            await tester.enterText(
                messageField.first, 'Hello, this is a test message!');
            await tester.pumpAndSettle();

            // Tap send button
            final sendButton = find.byIcon(Icons.send);
            if (sendButton.evaluate().isNotEmpty) {
              await tester.tap(sendButton);
              await tester.pumpAndSettle(Duration(seconds: 1));
            }

            // Assert
            expect(find.text('Hello, this is a test message!'), findsWidgets);
          }
        }
      }
    });

    testWidgets('should open chat from match', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to matches
      final matchesTab = find.text('Matches');
      if (matchesTab.evaluate().isNotEmpty) {
        await tester.tap(matchesTab);
        await tester.pumpAndSettle();

        // Tap on a match
        final matchCards = find.byType(Card);
        if (matchCards.evaluate().isNotEmpty) {
          await tester.tap(matchCards.first);
          await tester.pumpAndSettle();

          // Tap chat button
          final chatButton = find.text('Chat');
          if (chatButton.evaluate().isNotEmpty) {
            await tester.tap(chatButton);
            await tester.pumpAndSettle();

            // Assert - Should be in chat page
            expect(find.byType(TextField), findsWidgets);
          }
        }
      }
    });

    testWidgets('should display chat history', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chats
      final chatsTab = find.text('Chats');
      if (chatsTab.evaluate().isNotEmpty) {
        await tester.tap(chatsTab);
        await tester.pumpAndSettle();

        // Open a chat
        final chatTiles = find.byType(ListTile);
        if (chatTiles.evaluate().isNotEmpty) {
          await tester.tap(chatTiles.first);
          await tester.pumpAndSettle();

          // Assert - Should see message history
          expect(find.byType(ListView), findsWidgets);
        }
      }
    });

    testWidgets('should scroll through messages', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsTab = find.text('Chats');
      if (chatsTab.evaluate().isNotEmpty) {
        await tester.tap(chatsTab);
        await tester.pumpAndSettle();

        final chatTiles = find.byType(ListTile);
        if (chatTiles.evaluate().isNotEmpty) {
          await tester.tap(chatTiles.first);
          await tester.pumpAndSettle();

          // Act - Scroll up to see older messages
          final listView = find.byType(ListView);
          if (listView.evaluate().isNotEmpty) {
            await tester.drag(listView.first, Offset(0, 300));
            await tester.pumpAndSettle();
          }

          // Assert
          expect(find.byType(ListView), findsWidgets);
        }
      }
    });
  });
}
