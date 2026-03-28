import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_provider.dart';
import '../../widgets/mixvy_drawer.dart';
import '../../core/logger.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

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
                  return const Center(child: Text('No notifications yet.'));
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: notification.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
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
