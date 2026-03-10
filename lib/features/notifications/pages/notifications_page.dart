import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tile_widget.dart';

class NotificationsPage extends ConsumerWidget {
  final String userId;
  const NotificationsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return NotificationTileWidget(notification: item);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
