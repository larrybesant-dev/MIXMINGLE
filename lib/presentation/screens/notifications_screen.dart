import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../../widgets/mixvy_drawer.dart';
import '../../core/logger.dart';
import '../../features/feed/widgets/feed_empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _handleNotificationTap(
    BuildContext context,
    String userId,
    NotificationModel notification,
    dynamic service,
  ) async {
    if (!notification.isRead) {
      try {
        await service.markRead(userId, notification.id);
      } catch (error) {
        Logger.log('Failed to mark notification read on tap: $error');
      }
    }

    if (!context.mounted) return;

    final actorId = notification.actorId?.trim() ?? '';
    final roomId = notification.roomId?.trim() ?? '';

    switch (notification.type) {
      case 'live_room_invite':
        if (roomId.isNotEmpty) context.go('/room/$roomId');
      case 'follow':
      case 'friend_accept':
      case 'friend_favorite':
        if (actorId.isNotEmpty) context.go('/profile/$actorId');
      case 'friend_request':
        context.go('/friends');
      case 'speed_dating_match':
        context.go('/speed-dating');
      default:
        if (actorId.isNotEmpty) context.go('/profile/$actorId');
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_rounded;
      case 'friend_request':
        return Icons.people_rounded;
      case 'friend_accept':
        return Icons.handshake_rounded;
      case 'friend_favorite':
        return Icons.star_rounded;
      case 'live_room_invite':
        return Icons.meeting_room_rounded;
      case 'speed_dating_match':
        return Icons.favorite_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'like':
        return Icons.thumb_up_rounded;
      case 'comment':
        return Icons.comment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type, BuildContext context) {
    switch (type) {
      case 'follow':
        return Colors.blue;
      case 'friend_request':
      case 'friend_favorite':
        return Theme.of(context).colorScheme.secondary;
      case 'friend_accept':
        return Colors.green;
      case 'live_room_invite':
        return Colors.teal;
      case 'speed_dating_match':
        return Colors.pink;
      case 'gift':
        return Colors.orange;
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return Colors.indigo;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentNotificationUserIdProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final service = ref.read(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      drawer: const MixVyDrawer(),
      body: Column(
        children: [
          if (userId == null)
            const Expanded(
              child: Center(child: Text('Please log in to view notifications.')),
            )
          else ...[
          if (!notificationsEnabled)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(12),
              child: const Text('Push notifications are disabled in Settings.'),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Mark All Read'),
                  onPressed: () => service.markAllRead(userId),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Notification Settings'),
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Could not load notifications: $error')),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const FeedEmptyState(
                    emoji: '🔔',
                    heading: 'All caught up!',
                    message: 'You have no notifications yet.\nRoom invites, friend requests and gift alerts will appear here.',
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        onTap: () => _handleNotificationTap(context, userId, notification, service),
                        leading: CircleAvatar(
                          backgroundColor: notification.isRead
                              ? Colors.grey.shade200
                              : _colorForType(notification.type, context).withValues(alpha: 0.15),
                          child: Icon(
                            _iconForType(notification.type),
                            color: notification.isRead
                                ? Colors.grey
                                : _colorForType(notification.type, context),
                            size: 22,
                          ),
                        ),
                        title: Text(notification.type.replaceAll('_', ' ')),
                        subtitle: Text(notification.content),
                        trailing: IconButton(
                          icon: Icon(notification.isRead ? Icons.done_all : Icons.check),
                          onPressed: notification.isRead
                              ? null
                              : () async {
                                  try {
                                    await service.markRead(userId, notification.id);
                                  } catch (error) {
                                    Logger.log('Failed to mark notification read: $error');
                                  }
                                },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
        ],
      ),
    );
  }
}
