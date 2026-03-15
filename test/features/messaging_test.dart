import 'package:flutter_test/flutter_test.dart';
import 'package:MIXVY/lib/features/messaging/message.dart';

void main() {
  group('Message', () {
    test('Message fields are correct', () {
      final message = Message(
        id: '1',
        senderId: '2',
        receiverId: '3',
        content: 'Hi',
        timestamp: DateTime.now(),
      );
      expect(message.content, 'Hi');
      expect(message.senderId, '2');
      expect(message.receiverId, '3');
    });
  });
}
