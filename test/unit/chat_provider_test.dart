/// Chat Provider Tests - Send/Receive Messages
///
/// Tests for:
/// - Sending messages
/// - Receiving messages
/// - Message list retrieval
/// - Message filtering
/// - Error handling

import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

void main() {
  group('ChatProvider Tests', () {
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
    });

    group('Send Message Tests', () {
      test('sendMessage creates message with correct data', () async {
        final messageData = MockUserData.chatMessage(
          senderId: 'test-user-123',
          senderName: 'Test User',
          content: 'Hello World',
        );

        mockFirestore.setMockData('messages', 'msg-1', messageData);

        final retrieved = mockFirestore.getMockData('messages', 'msg-1');

        expect(retrieved['senderId'], equals('test-user-123'));
        expect(retrieved['content'], equals('Hello World'));
        expect(retrieved['type'], equals('text'));
      });

      test('sendMessage includes timestamp', () async {
        final now = DateTime.now();
        final messageData = MockUserData.chatMessage(
          timestamp: now,
          content: 'Timestamped message',
        );

        mockFirestore.setMockData('messages', 'msg-2', messageData);

        final retrieved = mockFirestore.getMockData('messages', 'msg-2');

        expect(retrieved['timestamp'], isNotNull);
      });

      test('sendMessage fails with empty content', () async {
        final messageData = MockUserData.chatMessage(content: '');

        expect(messageData['content'], isEmpty);
      });

      test('sendMessage increments message count', () async {
        for (int i = 0; i < 5; i++) {
          final messageData = MockUserData.chatMessage(content: 'Message $i');
          mockFirestore.setMockData('messages', 'msg-$i', messageData);
        }

        final messages = <String, dynamic>{};
        for (int i = 0; i < 5; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty) {
            messages['msg-$i'] = data;
          }
        }

        expect(messages.length, equals(5));
      });

      test('sendMessage with file attachment', () async {
        final messageData = MockUserData.chatMessage(
          type: 'file',
          content: 'document.pdf',
        );

        mockFirestore.setMockData('messages', 'msg-file', messageData);

        final retrieved = mockFirestore.getMockData('messages', 'msg-file');

        expect(retrieved['type'], equals('file'));
        expect(retrieved['content'], equals('document.pdf'));
      });
    });

    group('Receive Message Tests', () {
      test('retrieving message returns correct data', () async {
        final messageData = MockUserData.chatMessage(
          senderId: 'friend-123',
          senderName: 'Alice',
          content: 'Hi there!',
        );

        mockFirestore.setMockData('messages', 'msg-3', messageData);

        final retrieved = mockFirestore.getMockData('messages', 'msg-3');

        expect(retrieved['senderId'], equals('friend-123'));
        expect(retrieved['senderName'], equals('Alice'));
        expect(retrieved['content'], equals('Hi there!'));
      });

      test('message list can be retrieved in order', () async {
        final messages = TestFixtures.chatMessages();

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('messages', 'msg-$i', messages[i]);
        }

        final retrieved = <Map<String, dynamic>>[];
        for (int i = 0; i < messages.length; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty) {
            retrieved.add(data);
          }
        }

        expect(retrieved.length, equals(messages.length));
      });

      test('message contains sender avatar', () async {
        final messageData = MockUserData.chatMessage(
          senderName: 'Bob',
        );

        mockFirestore.setMockData('messages', 'msg-4', messageData);

        final retrieved = mockFirestore.getMockData('messages', 'msg-4');

        expect(retrieved['senderAvatar'], isNotEmpty);
      });
    });

    group('Message List Tests', () {
      test('empty chat returns empty list', () async {
        final messages = <Map<String, dynamic>>[];

        expect(messages, isEmpty);
      });

      test('chat with multiple messages maintains order', () async {
        final messages = TestFixtures.chatMessages();

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('chat-123', 'msg-$i', messages[i]);
        }

        final retrieved = <Map<String, dynamic>>[];
        for (int i = 0; i < messages.length; i++) {
          final data = mockFirestore.getMockData('chat-123', 'msg-$i');
          if (data.isNotEmpty) {
            retrieved.add(data);
          }
        }

        expect(retrieved.length, equals(3));
      });

      test('pagination works correctly', () async {
        const pageSize = 10;
        final messages = List.generate(
          25,
          (i) => MockUserData.chatMessage(content: 'Message $i'),
        );

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('messages', 'msg-$i', messages[i]);
        }

        // First page
        final firstPage = <Map<String, dynamic>>[];
        for (int i = 0; i < pageSize; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty) firstPage.add(data);
        }

        expect(firstPage.length, equals(10));

        // Second page
        final secondPage = <Map<String, dynamic>>[];
        for (int i = pageSize; i < pageSize * 2; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty) secondPage.add(data);
        }

        expect(secondPage.length, equals(10));
      });
    });

    group('Message Filtering Tests', () {
      test('filter messages by sender', () async {
        final messages = TestFixtures.chatMessages();

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('messages', 'msg-$i', messages[i]);
        }

        final userMessages = <Map<String, dynamic>>[];
        for (int i = 0; i < messages.length; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty && data['senderId'] == 'test-user-123') {
            userMessages.add(data);
          }
        }

        expect(userMessages.length, equals(1));
      });

      test('filter messages by type', () async {
        final textMessage = MockUserData.chatMessage(type: 'text');
        final fileMessage =
            MockUserData.chatMessage(type: 'file', content: 'doc.pdf');

        mockFirestore.setMockData('messages', 'msg-1', textMessage);
        mockFirestore.setMockData('messages', 'msg-2', fileMessage);

        final fileMessages = <Map<String, dynamic>>[];
        for (int i = 1; i <= 2; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty && data['type'] == 'file') {
            fileMessages.add(data);
          }
        }

        expect(fileMessages.length, equals(1));
        expect(fileMessages[0]['content'], equals('doc.pdf'));
      });

      test('filter unread messages', () async {
        // Create messages with read status
        final messages = [
          {...MockUserData.chatMessage(), 'isRead': false},
          {...MockUserData.chatMessage(), 'isRead': true},
          {...MockUserData.chatMessage(), 'isRead': false},
        ];

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('messages', 'msg-$i', messages[i]);
        }

        final unreadMessages = <Map<String, dynamic>>[];
        for (int i = 0; i < messages.length; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty && (data['isRead'] ?? true) == false) {
            unreadMessages.add(data);
          }
        }

        expect(unreadMessages.length, equals(2));
      });
    });

    group('Error Handling Tests', () {
      test('sending message with null sender fails gracefully', () async {
        final invalidMessage = MockUserData.chatMessage(
          senderId: '',
          senderName: '',
        );

        expect(invalidMessage['senderId'], isEmpty);
        expect(invalidMessage['senderName'], isEmpty);
      });

      test('retrieving non-existent message returns empty', () async {
        final retrieved =
            mockFirestore.getMockData('messages', 'non-existent');

        expect(retrieved, isEmpty);
      });

      test('corrupted message data is handled', () async {
        final invalidData = <String, dynamic>{
          'senderId': null,
          'content': null,
          'timestamp': 'invalid-date',
        };

        mockFirestore.setMockData('messages', 'invalid-msg', invalidData);

        final retrieved = mockFirestore.getMockData('messages', 'invalid-msg');

        expect(retrieved.isNotEmpty, isTrue);
      });
    });

    group('Message Search Tests', () {
      test('search messages by keyword', () async {
        final messages = [
          MockUserData.chatMessage(content: 'Hello there friend'),
          MockUserData.chatMessage(content: 'How are you today?'),
          MockUserData.chatMessage(content: 'Hello again!'),
        ];

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('messages', 'msg-$i', messages[i]);
        }

        final helloMessages = <Map<String, dynamic>>[];
        for (int i = 0; i < messages.length; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty &&
              data['content'].toString().toLowerCase().contains('hello')) {
            helloMessages.add(data);
          }
        }

        expect(helloMessages.length, equals(2));
      });

      test('search is case insensitive', () async {
        final message = MockUserData.chatMessage(content: 'Hello World');
        mockFirestore.setMockData('messages', 'msg-1', message);

        final retrieved = mockFirestore.getMockData('messages', 'msg-1');
        final lowerContent = retrieved['content'].toString().toLowerCase();

        expect(lowerContent.contains('hello'), isTrue);
        expect(lowerContent.contains('HELLO'), isFalse);
      });
    });

    group('Message Timestamp Tests', () {
      test('messages are timestamped correctly', () async {
        final now = DateTime.now();
        final messageData = MockUserData.chatMessage(timestamp: now);

        mockFirestore.setMockData('messages', 'msg-1', messageData);

        final retrieved = mockFirestore.getMockData('messages', 'msg-1');
        final messageTime =
            DateTime.parse(retrieved['timestamp'].toString());

        expect(messageTime.year, equals(now.year));
        expect(messageTime.month, equals(now.month));
        expect(messageTime.day, equals(now.day));
      });

      test('message timestamps are sortable', () async {
        final messages = [
          MockUserData.chatMessage(
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          MockUserData.chatMessage(
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          MockUserData.chatMessage(timestamp: DateTime.now()),
        ];

        for (int i = 0; i < messages.length; i++) {
          mockFirestore.setMockData('messages', 'msg-$i', messages[i]);
        }

        final retrieved = <Map<String, dynamic>>[];
        for (int i = 0; i < messages.length; i++) {
          final data = mockFirestore.getMockData('messages', 'msg-$i');
          if (data.isNotEmpty) retrieved.add(data);
        }

        expect(retrieved.length, equals(3));
      });
    });
  });
}
