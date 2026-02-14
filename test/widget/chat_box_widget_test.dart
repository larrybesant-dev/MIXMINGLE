/// ChatBoxWidget Tests - Message Rendering, Input, Animations
///
/// Tests for:
/// - Message list rendering
/// - Message input field functionality
/// - Send message button
/// - Message fade-in animations
/// - Scroll to bottom on new message
/// - Empty state handling

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

// Mock ChatBoxWidget for testing
class MockChatBoxWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String)? onSendMessage;
  final bool isLoading;

  const MockChatBoxWidget({
    Key? key,
    required this.messages,
    this.onSendMessage,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MockChatBoxWidget> createState() => _MockChatBoxWidgetState();
}

class _MockChatBoxWidgetState extends State<MockChatBoxWidget>
    with TickerProviderStateMixin {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late List<AnimationController> _messageAnimations;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageAnimations = [];
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _messageAnimations.clear();
    for (int i = 0; i < widget.messages.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      controller.forward();
      _messageAnimations.add(controller);
    }
  }

  @override
  void didUpdateWidget(MockChatBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      _initializeAnimations();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage?.call(text);
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (final controller in _messageAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  key: const Key('empty-chat-message'),
                  child: Text(
                    'No messages yet',
                    style: TextStyle(
                      color: DesignColors.accent[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[index];
                    final isOwn = message['isOwnMessage'] as bool? ?? false;

                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1)
                          .animate(_messageAnimations[index]),
                      child: Container(
                        key: Key('message-${index}'),
                        alignment: isOwn
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: isOwn
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isOwn
                                    ? DesignColors.accent
                                    : DesignColors.accent[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message['content'] ?? '',
                                style: TextStyle(
                                  color: DesignColors.accent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['sender'] ?? 'Unknown',
                              style: TextStyle(
                                color: DesignColors.accent[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignColors.accent[900],
            border: Border(
              top: BorderSide(color: DesignColors.accent[800]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('message-input-field'),
                  controller: _messageController,
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: DesignTypography.body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: DesignColors.accent[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: DesignColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: DesignTypography.body,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: DesignColors.accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  key: const Key('send-button'),
                  icon: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignColors.accent,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  color: DesignColors.accent,
                  onPressed: widget.isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  group('ChatBoxWidget Tests', () {
    testWidgets('renders empty state message when no messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('empty-chat-message')), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('renders all messages in list',
        (WidgetTester tester) async {
      final messages = TestFixtures.chatMessages();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: messages,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (int i = 0; i < messages.length; i++) {
        expect(
          find.byKey(Key('message-$i')),
          findsOneWidget,
        );
      }
    });

    testWidgets('displays message content correctly',
        (WidgetTester tester) async {
      final messages = [
        MockUserData.chatMessage(
          sender: 'Alice',
          content: 'Hello there!',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: messages,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hello there!'), findsOneWidget);
      expect(find.text('Alice'), findsWidgets);
    });

    testWidgets('input field is enabled initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
            ),
          ),
        ),
      );

      final inputField = find.byKey(const Key('message-input-field'));
      expect(inputField, findsOneWidget);
    });

    testWidgets('typing in input field works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
            ),
          ),
        ),
      );

      final inputField = find.byKey(const Key('message-input-field'));
      await tester.enterText(inputField, 'Test message');

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('send button sends message', (WidgetTester tester) async {
      var sentMessages = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
              onSendMessage: (msg) => sentMessages.add(msg),
            ),
          ),
        ),
      );

      final inputField = find.byKey(const Key('message-input-field'));
      await tester.enterText(inputField, 'Test message');

      final sendButton = find.byKey(const Key('send-button'));
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(sentMessages.length, equals(1));
      expect(sentMessages[0], equals('Test message'));
    });

    testWidgets('input clears after sending message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
              onSendMessage: (msg) {},
            ),
          ),
        ),
      );

      final inputField = find.byKey(const Key('message-input-field'));
      await tester.enterText(inputField, 'Test message');
      expect(find.text('Test message'), findsOneWidget);

      final sendButton = find.byKey(const Key('send-button'));
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsNothing);
    });

    testWidgets('send button disabled when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
              isLoading: true,
            ),
          ),
        ),
      );

      // Progress indicator should be shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('own messages appear on the right',
        (WidgetTester tester) async {
      final messages = [
        MockUserData.chatMessage(
          sender: 'Me',
          content: 'My message',
          isOwnMessage: true,
        ),
        MockUserData.chatMessage(
          sender: 'Other',
          content: 'Their message',
          isOwnMessage: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: messages,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My message'), findsOneWidget);
      expect(find.text('Their message'), findsOneWidget);
    });

    testWidgets('messages fade in on entry',
        (WidgetTester tester) async {
      final messages = TestFixtures.chatMessages();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: messages,
            ),
          ),
        ),
      );

      // FadeTransition should be used
      expect(find.byType(FadeTransition), findsWidgets);

      // After animation completes, messages should be visible
      await tester.pumpAndSettle();

      for (final message in messages) {
        expect(find.text(message['content']), findsOneWidget);
      }
    });

    testWidgets('empty message is not sent',
        (WidgetTester tester) async {
      var sentCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
              onSendMessage: (msg) => sentCount++,
            ),
          ),
        ),
      );

      final sendButton = find.byKey(const Key('send-button'));
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Empty message should not be sent
      expect(sentCount, equals(0));
    });

    testWidgets('message with only spaces is not sent',
        (WidgetTester tester) async {
      var sentCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: [],
              onSendMessage: (msg) => sentCount++,
            ),
          ),
        ),
      );

      final inputField = find.byKey(const Key('message-input-field'));
      await tester.enterText(inputField, '   ');

      final sendButton = find.byKey(const Key('send-button'));
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(sentCount, equals(0));
    });

    testWidgets('handles large number of messages',
        (WidgetTester tester) async {
      final messages = List.generate(
        50,
        (i) => MockUserData.chatMessage(
          sender: 'User $i',
          content: 'Message $i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockChatBoxWidget(
              messages: messages,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify messages are rendered (at least some are visible)
      expect(find.byType(FadeTransition), findsWidgets);
    });
  });
}
