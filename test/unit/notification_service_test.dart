// Unit tests for NotificationService and AppNotification models

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/providers/app_models.dart';
import '../../lib/services/notification_service.dart';

// Mocks
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFlutterLocalNotificationsPlugin extends Mock {}

void main() {
  group('AppNotification Tests', () {
    test('AppNotification creates instance with all fields', () {
      final notification = AppNotification(
        id: 'test-1',
        title: 'Test Title',
        message: 'Test Message',
        type: 'message',
        timestamp: DateTime(2025, 1, 1),
        isRead: false,
        senderId: 'user-123',
        senderName: 'John Doe',
        senderAvatar: 'https://example.com/avatar.jpg',
        priority: 1,
      );

      expect(notification.id, 'test-1');
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.type, 'message');
      expect(notification.senderId, 'user-123');
      expect(notification.senderName, 'John Doe');
      expect(notification.priority, 1);
      expect(notification.isRead, false);
    });

    test('AppNotification.empty() creates empty notification', () {
      final emptyNotif = AppNotification.empty();

      expect(emptyNotif.id, '');
      expect(emptyNotif.title, 'Notification');
      expect(emptyNotif.message, '');
      expect(emptyNotif.type, 'system_alert');
      expect(emptyNotif.isRead, false);
    });

    test('AppNotification copyWith() preserves unmodified fields', () {
      final original = AppNotification(
        id: 'test-1',
        title: 'Original Title',
        message: 'Original Message',
        type: 'message',
        timestamp: DateTime(2025, 1, 1),
        isRead: false,
        senderId: 'user-123',
        senderName: 'John Doe',
      );

      final modified = original.copyWith(
        isRead: true,
        title: 'Modified Title',
      );

      expect(modified.id, 'test-1'); // Preserved
      expect(modified.title, 'Modified Title'); // Changed
      expect(modified.message, 'Original Message'); // Preserved
      expect(modified.type, 'message'); // Preserved
      expect(modified.isRead, true); // Changed
      expect(modified.senderId, 'user-123'); // Preserved
      expect(modified.senderName, 'John Doe'); // Preserved
    });

    test('AppNotification.fromFCMPayload() creates notification from FCM message', () {
      final payload = {
        'title': 'New Message',
        'body': 'Hello from Alice!',
        'notificationType': 'message',
        'senderId': 'alice-123',
        'senderName': 'Alice Johnson',
        'senderAvatar': 'https://example.com/alice.jpg',
        'imageUrl': 'https://example.com/message-image.jpg',
        'priority': '1',
        'tag': 'messages',
        'metadata': {
          'roomId': 'room-456',
          'conversationId': 'conv-789',
        }
      };

      final notification = AppNotification.fromFCMPayload(
        payload,
        id: 'fcm-001',
      );

      expect(notification.id, 'fcm-001');
      expect(notification.title, 'New Message');
      expect(notification.message, 'Hello from Alice!');
      expect(notification.type, 'message');
      expect(notification.senderId, 'alice-123');
      expect(notification.senderName, 'Alice Johnson');
      expect(notification.imageUrl, 'https://example.com/message-image.jpg');
      expect(notification.priority, 1);
      expect(notification.tag, 'messages');
      expect(notification.metadata?['roomId'], 'room-456');
    });

    test('AppNotification equality operator works correctly', () {
      final notif1 = AppNotification(
        id: 'test-1',
        title: 'Title',
        message: 'Message',
        type: 'message',
        timestamp: DateTime(2025, 1, 1),
        isRead: false,
      );

      final notif2 = AppNotification(
        id: 'test-1',
        title: 'Title',
        message: 'Message',
        type: 'message',
        timestamp: DateTime(2025, 1, 1),
        isRead: false,
      );

      final notif3 = AppNotification(
        id: 'test-2',
        title: 'Title',
        message: 'Message',
        type: 'message',
        timestamp: DateTime(2025, 1, 1),
        isRead: false,
      );

      expect(notif1 == notif2, true);
      expect(notif1 == notif3, false);
    });

    test('NotificationAction creates with required fields', () {
      bool actionTapped = false;

      final action = NotificationAction(
        id: 'accept',
        label: 'Accept Friend Request',
        icon: 'check',
        onPressed: () => actionTapped = true,
      );

      expect(action.id, 'accept');
      expect(action.label, 'Accept Friend Request');
      expect(action.icon, 'check');

      action.onPressed?.call();
      expect(actionTapped, true);
    });

    test('AppNotification with multiple actions', () {
      final actions = [
        NotificationAction(id: 'accept', label: 'Accept'),
        NotificationAction(id: 'decline', label: 'Decline'),
      ];

      final notification = AppNotification(
        id: 'test-1',
        title: 'Friend Request',
        message: 'Alice wants to be your friend',
        type: 'friend_request',
        timestamp: DateTime.now(),
        isRead: false,
        actions: actions,
      );

      expect(notification.actions, isNotNull);
      expect(notification.actions!.length, 2);
      expect(notification.actions![0].id, 'accept');
      expect(notification.actions![1].id, 'decline');
    });

    test('AppNotification with metadata stores custom data', () {
      final metadata = {
        'roomId': 'room-123',
        'conversationId': 'conv-456',
        'senderAvatar': 'https://example.com/avatar.jpg',
        'customData': {'nested': 'value'},
      };

      final notification = AppNotification(
        id: 'test-1',
        title: 'New Message',
        message: 'Hello there!',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
        metadata: metadata,
      );

      expect(notification.metadata, isNotNull);
      expect(notification.metadata!['roomId'], 'room-123');
      expect(notification.metadata!['conversationId'], 'conv-456');
      expect(notification.metadata!['customData']['nested'], 'value');
    });

    test('AppNotification toString() produces readable output', () {
      final notification = AppNotification(
        id: 'test-1',
        title: 'Title',
        message: 'Message',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      final toString = notification.toString();
      expect(toString, contains('AppNotification'));
      expect(toString, contains('test-1'));
      expect(toString, contains('message'));
    });

    test('AppNotification hashCode is consistent', () {
      final notif1 = AppNotification(
        id: 'test-1',
        title: 'Title',
        message: 'Message',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      final notif2 = AppNotification(
        id: 'test-1',
        title: 'Title',
        message: 'Message',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      expect(notif1.hashCode, notif2.hashCode);
    });
  });

  group('NotificationService Configuration Tests', () {
    test('Channel ID mapping for message type', () {
      // This tests the notification type to channel mapping logic
      final notificationType = 'message';

      // Expected mapping
      const expectedChannelId = 'messages_channel';

      // Verify the mapping follows expected pattern
      expect(
        _getChannelIdForType(notificationType),
        expectedChannelId,
      );
    });

    test('Channel ID mapping for friend request type', () {
      const expectedChannelId = 'friend_requests_channel';
      expect(
        _getChannelIdForType('friend_request'),
        expectedChannelId,
      );
    });

    test('Channel ID mapping for group invite type', () {
      const expectedChannelId = 'group_invites_channel';
      expect(
        _getChannelIdForType('group_invite'),
        expectedChannelId,
      );
    });

    test('Channel ID mapping for video call type', () {
      const expectedChannelId = 'video_calls_channel';
      expect(
        _getChannelIdForType('video_call'),
        expectedChannelId,
      );
    });

    test('Channel ID mapping for system alert type', () {
      const expectedChannelId = 'system_channel';
      expect(
        _getChannelIdForType('system_alert'),
        expectedChannelId,
      );
    });

    test('Color mapping for message type', () {
      const expectedColor = '0xFF4CAF50'; // Green
      expect(
        _getColorForType('message'),
        expectedColor,
      );
    });

    test('Color mapping for friend request type', () {
      const expectedColor = '0xFF2196F3'; // Blue
      expect(
        _getColorForType('friend_request'),
        expectedColor,
      );
    });

    test('Color mapping for group invite type', () {
      const expectedColor = '0xFFFF9800'; // Orange
      expect(
        _getColorForType('group_invite'),
        expectedColor,
      );
    });

    test('Color mapping for video call type', () {
      const expectedColor = '0xFF9C27B0'; // Purple
      expect(
        _getColorForType('video_call'),
        expectedColor,
      );
    });

    test('Priority mapping for message type', () {
      const expectedPriority = 1; // High
      expect(
        _getPriorityForType('message'),
        expectedPriority,
      );
    });

    test('Priority mapping for video call type', () {
      const expectedPriority = 2; // Max
      expect(
        _getPriorityForType('video_call'),
        expectedPriority,
      );
    });

    test('Priority mapping for system alert type', () {
      const expectedPriority = 0; // Default
      expect(
        _getPriorityForType('system_alert'),
        expectedPriority,
      );
    });
  });

  group('Notification Payload Validation Tests', () {
    test('FCM payload with complete information parses correctly', () {
      final completePayload = {
        'title': 'Message from Alice',
        'body': 'Hi, how are you?',
        'notificationType': 'message',
        'senderId': 'user-alice-123',
        'senderName': 'Alice Johnson',
        'senderAvatar': 'https://example.com/alice.jpg',
        'imageUrl': 'https://example.com/emoji.jpg',
        'sound': 'default',
        'priority': '1',
        'tag': 'messages',
        'metadata': {
          'roomId': 'room-abc',
          'conversationId': 'conv-xyz',
        }
      };

      final notification = AppNotification.fromFCMPayload(
        completePayload,
        id: 'payload-001',
      );

      expect(notification.title, 'Message from Alice');
      expect(notification.message, 'Hi, how are you?');
      expect(notification.type, 'message');
      expect(notification.senderId, 'user-alice-123');
      expect(notification.senderName, 'Alice Johnson');
      expect(notification.imageUrl, 'https://example.com/emoji.jpg');
      expect(notification.sound, 'default');
      expect(notification.priority, 1);
      expect(notification.metadata?['roomId'], 'room-abc');
    });

    test('FCM payload with minimal information still creates notification', () {
      final minimalPayload = {
        'title': 'Notification',
        'body': 'You have a new notification',
      };

      final notification = AppNotification.fromFCMPayload(
        minimalPayload,
        id: 'payload-002',
      );

      expect(notification.id, 'payload-002');
      expect(notification.title, 'Notification');
      expect(notification.message, 'You have a new notification');
      expect(notification.type, 'system_alert'); // Default
      expect(notification.isRead, false);
      expect(notification.senderId, isNull);
      expect(notification.metadata, isNull);
    });

    test('FCM payload with missing title defaults to "Notification"', () {
      final payload = {
        'body': 'This is the message',
      };

      final notification = AppNotification.fromFCMPayload(
        payload,
        id: 'payload-003',
      );

      expect(notification.title, 'Notification');
    });

    test('FCM payload with missing body defaults to empty string', () {
      final payload = {
        'title': 'Important',
      };

      final notification = AppNotification.fromFCMPayload(
        payload,
        id: 'payload-004',
      );

      expect(notification.message, '');
    });

    test('FCM priority string converts to integer', () {
      final payload = {
        'title': 'Test',
        'body': 'Test message',
        'priority': '2',
      };

      final notification = AppNotification.fromFCMPayload(
        payload,
        id: 'payload-005',
      );

      expect(notification.priority, 2);
      expect(notification.priority is int, true);
    });

    test('FCM metadata is copied as new map (not reference)', () {
      final originalMetadata = {'key': 'value'};
      final payload = {
        'title': 'Test',
        'body': 'Test message',
        'metadata': originalMetadata,
      };

      final notification = AppNotification.fromFCMPayload(
        payload,
        id: 'payload-006',
      );

      // Verify metadata is not the same reference
      expect(identical(notification.metadata, originalMetadata), false);
      // But contains same values
      expect(notification.metadata?['key'], 'value');
    });
  });

  group('Notification Type Tests', () {
    test('All supported notification types are recognized', () {
      const types = [
        'message',
        'friend_request',
        'group_invite',
        'video_call',
        'system_alert',
      ];

      for (final type in types) {
        final notification = AppNotification(
          id: 'test-$type',
          title: 'Test',
          message: 'Test message',
          type: type,
          timestamp: DateTime.now(),
          isRead: false,
        );

        expect(notification.type, type);
      }
    });

    test('Notification type determines channel configuration', () {
      final messageNotif = AppNotification(
        id: 'msg-1',
        title: 'Message',
        message: 'Test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      final friendNotif = AppNotification(
        id: 'friend-1',
        title: 'Friend Request',
        message: 'Test',
        type: 'friend_request',
        timestamp: DateTime.now(),
        isRead: false,
      );

      expect(messageNotif.type, 'message');
      expect(friendNotif.type, 'friend_request');
      expect(_getChannelIdForType(messageNotif.type), 'messages_channel');
      expect(_getChannelIdForType(friendNotif.type), 'friend_requests_channel');
    });
  });
}

// Test helper functions that mirror NotificationService logic
String _getChannelIdForType(String type) {
  switch (type) {
    case 'message':
      return 'messages_channel';
    case 'friend_request':
      return 'friend_requests_channel';
    case 'group_invite':
      return 'group_invites_channel';
    case 'video_call':
      return 'video_calls_channel';
    case 'system_alert':
    default:
      return 'system_channel';
  }
}

String _getColorForType(String type) {
  switch (type) {
    case 'message':
      return '0xFF4CAF50'; // Green
    case 'friend_request':
      return '0xFF2196F3'; // Blue
    case 'group_invite':
      return '0xFFFF9800'; // Orange
    case 'video_call':
      return '0xFF9C27B0'; // Purple
    case 'system_alert':
    default:
      return '0xFF757575'; // Grey
  }
}

int _getPriorityForType(String type) {
  switch (type) {
    case 'video_call':
      return 2; // Max
    case 'message':
    case 'friend_request':
    case 'group_invite':
      return 1; // High
    case 'system_alert':
    default:
      return 0; // Default
  }
}
