import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/widgets/message_bubble.dart';
import 'package:mixvy/models/message_model.dart';

MessageModel _msg({String senderId = 'user-1'}) => MessageModel(
      id: 'msg-1',
      senderId: senderId,
      roomId: 'room-1',
      content: 'Hello world',
      sentAt: DateTime(2024, 1, 1, 12),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );

/// Finds a [RichText] whose plain text contains [substring].
Finder richTextContaining(String substring) => find.byWidgetPredicate(
      (w) =>
          w is RichText && w.text.toPlainText().contains(substring),
    );

void main() {
  group('MessageBubble VIP colours', () {
    testWidgets('level 0 renders without gold/silver/bronze tint',
        (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(
        message: _msg(),
        isMe: false,
        senderLabel: 'Alice',
        senderVipLevel: 0,
      )));
      // Sender label is embedded in a RichText TextSpan.
      expect(richTextContaining('Alice'), findsOneWidget);
    });

    testWidgets('level 1 renders bronze label chip', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(
        message: _msg(),
        isMe: false,
        senderLabel: 'BronzeUser',
        senderVipLevel: 1,
      )));
      expect(richTextContaining('BronzeUser'), findsOneWidget);
    });

    testWidgets('level 3 renders silver label', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(
        message: _msg(),
        isMe: false,
        senderLabel: 'SilverUser',
        senderVipLevel: 3,
      )));
      expect(richTextContaining('SilverUser'), findsOneWidget);
    });

    testWidgets('level 5 renders gold label', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(
        message: _msg(),
        isMe: false,
        senderLabel: 'GoldUser',
        senderVipLevel: 5,
      )));
      expect(richTextContaining('GoldUser'), findsOneWidget);
    });

    testWidgets('isMe bubble appears on the right side', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(
        message: _msg(senderId: 'me'),
        isMe: true,
        senderVipLevel: 0,
      )));
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('other-user bubble appears on the left side', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(
        message: _msg(),
        isMe: false,
        senderVipLevel: 0,
      )));
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });
  });
}
