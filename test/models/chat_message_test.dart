import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/shared/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('fromMap populates fields', () {
      final map = {
        'id': 'msg123',
        'roomId': 'room1',
        'senderId': 'user123',
        'receiverId': 'user999',
        'content': 'Hello world',
        'imageUrl': 'https://example.com/image.jpg',
        'timestamp': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'isRead': true,
        'replyToId': 'parent1',
      };

      final message = ChatMessage.fromMap(map);

      expect(message.id, 'msg123');
      expect(message.roomId, 'room1');
      expect(message.senderId, 'user123');
      expect(message.receiverId, 'user999');
      expect(message.content, 'Hello world');
      expect(message.imageUrl, 'https://example.com/image.jpg');
      expect(message.isRead, isTrue);
      expect(message.replyToId, 'parent1');
      expect(message.timestamp, DateTime(2024, 1, 1));
    });

    test('toMap round-trips core fields', () {
      final message = ChatMessage(
        id: 'msg999',
        roomId: 'room42',
        senderId: 'sender1',
        senderName: 'Sender One',
        receiverId: null,
        content: 'Ping',
        imageUrl: null,
        timestamp: DateTime(2024, 2, 2, 3, 4, 5),
        isRead: false,
        replyToId: null,
      );

      final map = message.toMap();

      expect(map['id'], 'msg999');
      expect(map['roomId'], 'room42');
      expect(map['senderId'], 'sender1');
      expect(map['receiverId'], isNull);
      expect(map['content'], 'Ping');
      expect(map['imageUrl'], isNull);
      expect(map['isRead'], isFalse);
      expect(map['replyToId'], isNull);
      expect(map['timestamp'], isA<Timestamp>());
    });
  });
}
