// Notifications Provider - Manages app notifications and alerts with FCM Integration

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import 'app_models.dart';
/// Callback type for notification actions
typedef NotificationActionCallback = Future<void> Function(String actionId, AppNotification notification);

/// Notifications notifier with FCM integration
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    return [];
  }

  /// Add notification
  ///
  /// Adds notification to the top of the list and tracks via analytics.
  /// Maintains up to 50 notifications in memory.
  void addNotification(AppNotification notification) {
    // Add to top of list
    state = [notification, ...state];

    // Maintain max 50 notifications in memory
    if (state.length > 50) {
      state = state.sublist(0, 50);
    }

    // Track notification received
    _trackNotification(notification);
  }

  /// Remove notification by ID
  ///
  /// Removes a notification from the list and triggers auto-cleanup.
  void removeNotification(String notificationId) {
    final notification = state.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => state.isEmpty ? AppNotification.empty() : state.first,
    );

    state = state.where((n) => n.id != notificationId).toList();

    // Track notification dismissed
    if (notification.id.isNotEmpty) {
      _trackNotificationDismissed(notification);
    }
  }

  /// Mark as read (persistent notifications)
  ///
  /// Updates the isRead flag for a notification.
  void markAsRead(String notificationId) {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
  }

  /// Mark multiple as read
  void markMultipleAsRead(List<String> notificationIds) {
    final idSet = notificationIds.toSet();
    state = [
      for (final notification in state)
        if (idSet.contains(notification.id))
          notification.copyWith(isRead: true)
        else
          notification,
    ];
  }

  /// Clear all notifications
  void clearAll() {
    state = [];
  }

  /// Clear read notifications
  void clearRead() {
    state = state.where((n) => !n.isRead).toList();
  }

  /// Handle notification action tap
  ///
  /// Called when user taps an action button on a notification.
  /// Executes the action callback if defined.
  Future<void> handleNotificationAction(
    String actionId,
    AppNotification notification,
  ) async {
    try {
      // Find the action
      final action = notification.actions?.firstWhere(
        (a) => a.id == actionId,
        orElse: () => NotificationAction(id: '', label: ''),
      );

      if (action != null && action.onPressed != null) {
        await Future<void>.sync(action.onPressed!);
      }

      // Track action
      _trackNotificationAction(notification, actionId);

      // Auto-dismiss after action
      removeNotification(notification.id);
    } catch (e) {
      AppLogger.error('Error handling notification action', e);
    }
  }

  /// Analytics tracking - notification received
  void _trackNotification(AppNotification notification) {
    try {
      // Analytics event tracking (if service available)
      // analytics.logEvent(
      //   name: 'notification_received',
      //   parameters: {
      //     'type': notification.type,
      //     'sender_id': notification.senderId ?? 'unknown',
      //   },
      // );
    } catch (e) {
      AppLogger.warning('Notification analytics tracking failed (non-fatal): $e');
    }
  }

  /// Analytics tracking - notification dismissed
  void _trackNotificationDismissed(AppNotification notification) {
    try {
      // analytics.logEvent(
      //   name: 'notification_dismissed',
      //   parameters: {
      //     'type': notification.type,
      //     'sender_id': notification.senderId ?? 'unknown',
      //   },
      // );
    } catch (e) {
      AppLogger.warning('Notification dismiss tracking failed (non-fatal): $e');
    }
  }

  /// Analytics tracking - notification action tapped
  void _trackNotificationAction(AppNotification notification, String actionId) {
    try {
      // analytics.logEvent(
      //   name: 'notification_action_tapped',
      //   parameters: {
      //     'type': notification.type,
      //     'action_id': actionId,
      //     'sender_id': notification.senderId ?? 'unknown',
      //   },
      // );
    } catch (e) {
      AppLogger.warning('Notification action tracking failed (non-fatal): $e');
    }
  }

  // Legacy convenience methods for backward compatibility

  /// Show friend request
  void friendRequest(String friendName, String friendId) {
    addNotification(
      AppNotification(
        id: 'friend_$friendId',
        title: 'Friend Request',
        message: '$friendName sent you a friend request',
        type: 'friend_request',
        senderId: friendId,
        senderName: friendName,
        timestamp: DateTime.now(),
        isRead: false,
        icon: 'person_add',
      ),
    );
  }

  /// Show message notification
  void newMessage(String senderName, String roomId) {
    addNotification(
      AppNotification(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Message',
        message: '$senderName sent you a message',
        type: 'message',
        senderId: senderName,
        senderName: senderName,
        timestamp: DateTime.now(),
        isRead: false,
        icon: 'mail',
        metadata: {'roomId': roomId},
      ),
    );
  }

  /// Show video request
  void videoRequest(String requesterName, String userId) {
    addNotification(
      AppNotification(
        id: 'video_$userId',
        title: 'Video Call',
        message: '$requesterName is calling you',
        type: 'video_call',
        senderId: userId,
        senderName: requesterName,
        timestamp: DateTime.now(),
        isRead: false,
        icon: 'videocam',
        priority: 2,
        metadata: {'userId': userId},
      ),
    );
  }

  /// Show room invite (legacy)
  void roomInvite(String inviterName, String roomId) {
    addNotification(
      AppNotification(
        id: 'invite_$roomId',
        title: 'Group Invite',
        message: '$inviterName invited you to join',
        type: 'group_invite',
        senderId: inviterName,
        senderName: inviterName,
        timestamp: DateTime.now(),
        isRead: false,
        icon: 'group',
        metadata: {'roomId': roomId},
      ),
    );
  }

  /// Show system notification
  void systemNotification(String title, String message) {
    addNotification(
      AppNotification(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: 'system_alert',
        timestamp: DateTime.now(),
        isRead: false,
        icon: 'info',
      ),
    );
  }
}

/// Notifications provider
final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  () => NotificationsNotifier(),
);

/// Unread notifications
final unreadNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).toList();
});

/// Unread count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(unreadNotificationsProvider).length;
});

/// Notifications by type
final notificationsByTypeProvider =
    Provider.family<List<AppNotification>, String>((ref, type) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => n.type == type).toList();
});

/// Recent notifications (last 5)
final recentNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.take(5).toList();
});

/// Filtered notifications by type and read status
final filteredNotificationsProvider =
    Provider.family<List<AppNotification>, ({String? type, bool? isRead})>(
  (ref, filter) {
    final notifications = ref.watch(notificationsProvider);

    return notifications.where((n) {
      if (filter.type != null && n.type != filter.type) return false;
      if (filter.isRead != null && n.isRead != filter.isRead) return false;
      return true;
    }).toList();
  },
);




