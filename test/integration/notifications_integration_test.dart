// Integration tests for FCM notification system

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/providers/app_models.dart';
import '../../lib/providers/notification_provider.dart';

void main() {
  group('Notification Provider Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Adding notification updates provider state', () {
      final notifier = container.read(notificationsProvider.notifier);
      final initialState = container.read(notificationsProvider);

      expect(initialState, isEmpty);

      final notification = AppNotification(
        id: 'test-1',
        title: 'Test Notification',
        message: 'This is a test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(notification);

      final newState = container.read(notificationsProvider);
      expect(newState, isNotEmpty);
      expect(newState.first.id, 'test-1');
    });

    test('Notification appears at top of list (LIFO order)', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notif1 = AppNotification(
        id: 'test-1',
        title: 'First',
        message: 'First notification',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      final notif2 = AppNotification(
        id: 'test-2',
        title: 'Second',
        message: 'Second notification',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(notif1);
      notifier.addNotification(notif2);

      final state = container.read(notificationsProvider);
      expect(state.length, 2);
      expect(state[0].id, 'test-2'); // Most recent first
      expect(state[1].id, 'test-1');
    });

    test('Removing notification updates provider state', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'test-1',
        title: 'Test',
        message: 'Test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(notification);
      expect(container.read(notificationsProvider).length, 1);

      notifier.removeNotification('test-1');
      expect(container.read(notificationsProvider), isEmpty);
    });

    test('Mark as read updates notification state', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'test-1',
        title: 'Test',
        message: 'Test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(notification);
      expect(container.read(notificationsProvider).first.isRead, false);

      notifier.markAsRead('test-1');
      expect(container.read(notificationsProvider).first.isRead, true);
    });

    test('Clear all removes all notifications', () {
      final notifier = container.read(notificationsProvider.notifier);

      notifier.addNotification(AppNotification(
        id: 'test-1',
        title: 'First',
        message: 'First',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      notifier.addNotification(AppNotification(
        id: 'test-2',
        title: 'Second',
        message: 'Second',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      expect(container.read(notificationsProvider).length, 2);

      notifier.clearAll();
      expect(container.read(notificationsProvider), isEmpty);
    });

    test('Unread notifications provider filters correctly', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notif1 = AppNotification(
        id: 'test-1',
        title: 'First',
        message: 'First',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      final notif2 = AppNotification(
        id: 'test-2',
        title: 'Second',
        message: 'Second',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: true,
      );

      notifier.addNotification(notif1);
      notifier.addNotification(notif2);

      final unreadNotifications = container.read(unreadNotificationsProvider);
      expect(unreadNotifications.length, 1);
      expect(unreadNotifications.first.id, 'test-2'); // Most recent unread
    });

    test('Unread count provider returns correct count', () {
      final notifier = container.read(notificationsProvider.notifier);

      notifier.addNotification(AppNotification(
        id: 'test-1',
        title: 'First',
        message: 'First',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      notifier.addNotification(AppNotification(
        id: 'test-2',
        title: 'Second',
        message: 'Second',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: true,
      ));

      notifier.addNotification(AppNotification(
        id: 'test-3',
        title: 'Third',
        message: 'Third',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      final count = container.read(unreadNotificationCountProvider);
      expect(count, 2);
    });

    test('Notifications by type filters correctly', () {
      final notifier = container.read(notificationsProvider.notifier);

      notifier.addNotification(AppNotification(
        id: 'msg-1',
        title: 'Message',
        message: 'Test message',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      notifier.addNotification(AppNotification(
        id: 'friend-1',
        title: 'Friend Request',
        message: 'Test friend request',
        type: 'friend_request',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      notifier.addNotification(AppNotification(
        id: 'msg-2',
        title: 'Another Message',
        message: 'Another test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      final messages = container.read(notificationsByTypeProvider('message'));
      final friendRequests = container.read(notificationsByTypeProvider('friend_request'));

      expect(messages.length, 2);
      expect(friendRequests.length, 1);
      expect(messages.every((n) => n.type == 'message'), true);
      expect(friendRequests.every((n) => n.type == 'friend_request'), true);
    });

    test('Recent notifications provider returns last 5', () {
      final notifier = container.read(notificationsProvider.notifier);

      // Add 10 notifications
      for (int i = 0; i < 10; i++) {
        notifier.addNotification(AppNotification(
          id: 'test-$i',
          title: 'Notification $i',
          message: 'Test message $i',
          type: 'message',
          timestamp: DateTime.now(),
          isRead: false,
        ));
      }

      final recent = container.read(recentNotificationsProvider);
      expect(recent.length, 5);
      // Should be most recent 5
      expect(recent[0].id, 'test-9');
      expect(recent[4].id, 'test-5');
    });

    test('Mark multiple as read updates all correctly', () {
      final notifier = container.read(notificationsProvider.notifier);

      for (int i = 0; i < 5; i++) {
        notifier.addNotification(AppNotification(
          id: 'test-$i',
          title: 'Test $i',
          message: 'Message $i',
          type: 'message',
          timestamp: DateTime.now(),
          isRead: false,
        ));
      }

      notifier.markMultipleAsRead(['test-0', 'test-1', 'test-2']);

      final state = container.read(notificationsProvider);
      expect(state.where((n) => n.isRead).length, 3);
      expect(state.where((n) => !n.isRead).length, 2);
    });

    test('Clear read removes only read notifications', () {
      final notifier = container.read(notificationsProvider.notifier);

      for (int i = 0; i < 5; i++) {
        final notification = AppNotification(
          id: 'test-$i',
          title: 'Test $i',
          message: 'Message $i',
          type: 'message',
          timestamp: DateTime.now(),
          isRead: false,
        );
        notifier.addNotification(notification);
      }

      notifier.markAsRead('test-0');
      notifier.markAsRead('test-1');
      notifier.clearRead();

      final state = container.read(notificationsProvider);
      expect(state.length, 3);
      expect(state.every((n) => !n.isRead), true);
    });

    test('Max 50 notifications maintained in memory', () {
      final notifier = container.read(notificationsProvider.notifier);

      // Add 60 notifications
      for (int i = 0; i < 60; i++) {
        notifier.addNotification(AppNotification(
          id: 'test-$i',
          title: 'Test $i',
          message: 'Message $i',
          type: 'message',
          timestamp: DateTime.now(),
          isRead: false,
        ));
      }

      final state = container.read(notificationsProvider);
      expect(state.length, 50);
      // Should keep most recent 50
      expect(state.first.id, 'test-59');
      expect(state.last.id, 'test-10');
    });
  });

  group('Notification Action Handling Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Handle notification action executes callback', () async {
      final notifier = container.read(notificationsProvider.notifier);

      bool actionExecuted = false;

      final action = NotificationAction(
        id: 'accept',
        label: 'Accept',
        onPressed: () {
          actionExecuted = true;
        },
      );

      final notification = AppNotification(
        id: 'test-1',
        title: 'Friend Request',
        message: 'Accept this friend request',
        type: 'friend_request',
        timestamp: DateTime.now(),
        isRead: false,
        actions: [action],
      );

      notifier.addNotification(notification);

      await notifier.handleNotificationAction('accept', notification);

      expect(actionExecuted, true);
    });

    test('Handle notification action dismisses notification', () async {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'test-1',
        title: 'Test',
        message: 'Test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
        actions: [
          NotificationAction(
            id: 'close',
            label: 'Close',
          ),
        ],
      );

      notifier.addNotification(notification);
      expect(container.read(notificationsProvider).length, 1);

      await notifier.handleNotificationAction('close', notification);
      expect(container.read(notificationsProvider).length, 0);
    });

    test('Notification with multiple actions', () async {
      final notifier = container.read(notificationsProvider.notifier);

      int acceptCount = 0;
      int declineCount = 0;

      final notification = AppNotification(
        id: 'test-1',
        title: 'Friend Request',
        message: 'Accept or decline?',
        type: 'friend_request',
        timestamp: DateTime.now(),
        isRead: false,
        actions: [
          NotificationAction(
            id: 'accept',
            label: 'Accept',
            onPressed: () => acceptCount++,
          ),
          NotificationAction(
            id: 'decline',
            label: 'Decline',
            onPressed: () => declineCount++,
          ),
        ],
      );

      notifier.addNotification(notification);

      await notifier.handleNotificationAction('accept', notification);
      expect(acceptCount, 1);
      expect(declineCount, 0);
    });
  });

  group('Notification Type-Specific Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Message notification includes message-specific data', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'msg-1',
        title: 'New Message',
        message: 'Hello from Alice!',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
        senderId: 'alice-123',
        senderName: 'Alice Johnson',
        senderAvatar: 'https://example.com/alice.jpg',
        imageUrl: 'https://example.com/message.jpg',
        metadata: {'roomId': 'room-456'},
        actions: [
          NotificationAction(id: 'reply', label: 'Reply'),
          NotificationAction(id: 'view', label: 'View'),
        ],
      );

      notifier.addNotification(notification);

      final state = container.read(notificationsProvider);
      expect(state.first.type, 'message');
      expect(state.first.senderName, 'Alice Johnson');
      expect(state.first.metadata?['roomId'], 'room-456');
      expect(state.first.actions?.length, 2);
    });

    test('Friend request notification includes friend data', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'friend-1',
        title: 'Friend Request',
        message: 'Bob wants to be your friend',
        type: 'friend_request',
        timestamp: DateTime.now(),
        isRead: false,
        senderId: 'bob-123',
        senderName: 'Bob Smith',
        senderAvatar: 'https://example.com/bob.jpg',
        actions: [
          NotificationAction(id: 'accept', label: 'Accept'),
          NotificationAction(id: 'decline', label: 'Decline'),
        ],
      );

      notifier.addNotification(notification);

      final state = container.read(notificationsProvider);
      expect(state.first.type, 'friend_request');
      expect(state.first.senderId, 'bob-123');
      expect(state.first.senderName, 'Bob Smith');
    });

    test('Group invite notification includes group data', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'group-1',
        title: 'Group Invite',
        message: 'Carol invited you to Gaming Squad',
        type: 'group_invite',
        timestamp: DateTime.now(),
        isRead: false,
        senderId: 'carol-123',
        senderName: 'Carol Davis',
        imageUrl: 'https://example.com/group.jpg',
        metadata: {'groupId': 'group-789'},
        actions: [
          NotificationAction(id: 'accept', label: 'Accept'),
          NotificationAction(id: 'decline', label: 'Decline'),
        ],
      );

      notifier.addNotification(notification);

      final state = container.read(notificationsProvider);
      expect(state.first.type, 'group_invite');
      expect(state.first.metadata?['groupId'], 'group-789');
    });

    test('Video call notification includes call data', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'call-1',
        title: 'Incoming Call',
        message: 'David is calling',
        type: 'video_call',
        timestamp: DateTime.now(),
        isRead: false,
        senderId: 'david-123',
        senderName: 'David Wilson',
        senderAvatar: 'https://example.com/david.jpg',
        priority: 2,
        metadata: {'roomId': 'call-room-123'},
        actions: [
          NotificationAction(id: 'accept', label: 'Accept'),
          NotificationAction(id: 'decline', label: 'Decline'),
        ],
      );

      notifier.addNotification(notification);

      final state = container.read(notificationsProvider);
      expect(state.first.type, 'video_call');
      expect(state.first.priority, 2);
      expect(state.first.metadata?['roomId'], 'call-room-123');
    });

    test('System alert notification', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'system-1',
        title: 'Maintenance Alert',
        message: 'System maintenance scheduled for tonight',
        type: 'system_alert',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(notification);

      final state = container.read(notificationsProvider);
      expect(state.first.type, 'system_alert');
      expect(state.first.senderId, isNull);
    });
  });

  group('Notification Persistence Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Mark notification as read persists across state updates', () {
      final notifier = container.read(notificationsProvider.notifier);

      final notification = AppNotification(
        id: 'test-1',
        title: 'Test',
        message: 'Test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(notification);
      notifier.markAsRead('test-1');

      // Add another notification
      notifier.addNotification(AppNotification(
        id: 'test-2',
        title: 'Test 2',
        message: 'Test 2',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      final state = container.read(notificationsProvider);
      final firstNotif = state.firstWhere((n) => n.id == 'test-1');
      expect(firstNotif.isRead, true);
    });

    test('Notification metadata persists correctly', () {
      final notifier = container.read(notificationsProvider.notifier);

      final metadata = {
        'roomId': 'room-123',
        'conversationId': 'conv-456',
        'priority': 'high',
      };

      final notification = AppNotification(
        id: 'test-1',
        title: 'Test',
        message: 'Test',
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
        metadata: metadata,
      );

      notifier.addNotification(notification);

      final state = container.read(notificationsProvider);
      expect(state.first.metadata, metadata);
      expect(state.first.metadata?['roomId'], 'room-123');
    });
  });
}
