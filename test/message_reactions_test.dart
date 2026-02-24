import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/models/direct_message.dart';
import 'package:mix_and_mingle/shared/models/message.dart';
import 'package:mix_and_mingle/features/messages/chat_screen.dart';

void main() {
  testWidgets('MessageBubble displays reactions correctly',
      (WidgetTester tester) async {
    // Create a test message with reactions
    final testMessage = DirectMessage(
      id: 'test-message-id',
      conversationId: 'test-conversation-id',
      senderId: 'test-sender-id',
      receiverId: 'test-receiver-id',
      content: 'Test message',
      timestamp: DateTime.now(),
      type: DirectMessageType.text,
      status: MessageStatus.sent,
      isEdited: false,
      reactions: {
        '👍': ['user1', 'user2'],
        '❤️': ['user3'],
      },
    );

    // Build the MessageBubble widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: testMessage,
              isCurrentUser: false,
              onEditMessage: null,
              onDeleteMessage: null,
              onAddReaction: null,
              onRemoveReaction: null,
            ),
          ),
        ),
      ),
    );

    // Verify the message content is displayed
    expect(find.text('Test message'), findsOneWidget);

    // Verify reactions are displayed
    expect(find.text('👍'), findsOneWidget);
    expect(find.text('❤️'), findsOneWidget);

    // Verify reaction counts
    expect(find.text('2'), findsOneWidget); // For 👍
    expect(find.text('1'), findsOneWidget); // For ❤️
  });

  testWidgets('MessageBubble long press shows reaction option',
      (WidgetTester tester) async {
    final testMessage = DirectMessage(
      id: 'test-message-id',
      conversationId: 'test-conversation-id',
      senderId: 'test-sender-id',
      receiverId: 'test-receiver-id',
      content: 'Test message',
      timestamp: DateTime.now(),
      type: DirectMessageType.text,
      status: MessageStatus.sent,
      isEdited: false,
      reactions: {},
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: testMessage,
              isCurrentUser: true,
              onEditMessage: null,
              onDeleteMessage: null,
              onAddReaction: null,
              onRemoveReaction: null,
            ),
          ),
        ),
      ),
    );

    // Long press the message bubble
    await tester.longPress(find.text('Test message'));
    await tester.pumpAndSettle();

    // Verify the reaction option appears
    expect(find.text('Add Reaction'), findsOneWidget);
  });
}
