import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/providers.dart';
import '../../shared/models/notification.dart' as model;
import '../../features/error/error_page.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/loading_widgets.dart';
import '../../core/routing/app_routes.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const ErrorPage(
            errorMessage: 'User not authenticated',
          );
        }

        final notificationsAsync = ref.watch(notificationsProvider(user.id));

        return ClubBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const GlowText(
                text: 'Notifications',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                glowColor: Color(0xFFFF4C4C),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        GlowText(
                          text: 'No notifications yet',
                          fontSize: 18,
                          color: Colors.white70,
                          glowColor: Color(0xFFFF4C4C),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You\'ll see updates about your rooms and followers here',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationTile(
                        context, ref, notification, user.id);
                  },
                );
              },
              loading: () =>
                  const FullScreenLoader(message: 'Loading notifications...'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GlowText(
                      text: 'Failed to load notifications',
                      fontSize: 18,
                      color: Color(0xFFFF4C4C),
                      glowColor: Color(0xFFFF4C4C),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Retry loading notifications',
                      button: true,
                      child: ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(notificationsProvider(user.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4C4C),
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const FullScreenLoader(message: 'Loading user...'),
      error: (error, stack) => const ErrorPage(
        errorMessage: 'Failed to load user',
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    model.Notification notification,
    String userId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF4C4C),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4C4C),
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notification.isRead) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .doc(notification.id)
                .update({'isRead': true}).catchError((_) {});
          }
          switch (notification.type) {
            case model.NotificationType.message:
              Navigator.pushNamed(context, AppRoutes.chats);
            case model.NotificationType.roomInvite:
              if (notification.roomId != null) {
                Navigator.pushNamed(context, AppRoutes.rooms);
              }
            case model.NotificationType.newFollower:
            case model.NotificationType.match:
            case model.NotificationType.like:
              if (notification.senderId != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.userProfile,
                  arguments: notification.senderId,
                );
              }
            default:
              break;
          }
        },
      ),
    );
  }

  IconData _getNotificationIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.roomInvite:
        return Icons.room;
      case model.NotificationType.newFollower:
        return Icons.person_add;
      case model.NotificationType.tip:
        return Icons.attach_money;
      case model.NotificationType.message:
        return Icons.message;
      case model.NotificationType.reaction:
        return Icons.favorite;
      case model.NotificationType.system:
        return Icons.info;
      case model.NotificationType.match:
        return Icons.favorite_border;
      case model.NotificationType.like:
        return Icons.thumb_up;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
