// lib/features/notifications/widgets/notification_tile.dart
//
// A single notification row with:
//   • Sender avatar (or type icon fallback)
//   • Notification body text
//   • Relative timestamp
//   • Unread indicator dot
//   • Tap-to-navigate deep-link
//   • Swipe-to-dismiss to delete
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/providers/notification_providers.dart';
import '../../../core/design_system/design_constants.dart';

class NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.3),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        ref.read(deleteNotificationProvider(notification.id));
      },
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : DesignColors.accent.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar / icon ──────────────────────────────────────────
                _buildLeading(),

                const SizedBox(width: 12),

                // ── Body ───────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: notification.isRead
                              ? Colors.white60
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _relativeTime(notification.timestamp),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // ── Unread dot ─────────────────────────────────────────────
                if (!notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DesignColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: DesignColors.accent
                                  .withValues(alpha: 0.6),
                              blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Leading avatar or icon ─────────────────────────────────────────────────

  Widget _buildLeading() {
    final avatarUrl = notification.senderAvatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: DesignColors.accent20,
        child: _typeIconOverlay(),
      );
    }

    // Fallback: coloured icon
    return CircleAvatar(
      radius: 22,
      backgroundColor: _typeColor().withValues(alpha: 0.2),
      child: Icon(_typeIcon(), color: _typeColor(), size: 22),
    );
  }

  Widget? _typeIconOverlay() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _typeColor(),
          shape: BoxShape.circle,
        ),
        child: Icon(_typeIcon(), size: 10, color: Colors.white),
      ),
    );
  }

  IconData _typeIcon() {
    switch (notification.type) {
      case AppNotificationType.chatMessage:
        return Icons.chat_bubble_outline;
      case AppNotificationType.like:
        return Icons.favorite;
      case AppNotificationType.comment:
        return Icons.comment_outlined;
      case AppNotificationType.friendRequest:
        return Icons.person_add_alt_1;
      case AppNotificationType.friendAccepted:
        return Icons.people_alt;
      case AppNotificationType.roomInvite:
      case AppNotificationType.roomLive:
        return Icons.live_tv_outlined;
      case AppNotificationType.speedDatingMatch:
        return Icons.favorite_border;
      case AppNotificationType.tip:
        return Icons.monetization_on_outlined;
      case AppNotificationType.newFollower:
        return Icons.person_outline;
      case AppNotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _typeColor() {
    switch (notification.type) {
      case AppNotificationType.chatMessage:
        return DesignColors.accent;
      case AppNotificationType.like:
        return Colors.pinkAccent;
      case AppNotificationType.comment:
        return Colors.orangeAccent;
      case AppNotificationType.friendRequest:
      case AppNotificationType.friendAccepted:
        return Colors.greenAccent;
      case AppNotificationType.roomInvite:
      case AppNotificationType.roomLive:
        return Colors.purpleAccent;
      case AppNotificationType.speedDatingMatch:
        return const Color(0xFFFF4D8B);
      case AppNotificationType.tip:
        return Colors.amberAccent;
      case AppNotificationType.newFollower:
        return Colors.cyanAccent;
      case AppNotificationType.system:
        return Colors.white38;
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(markNotificationReadProvider(notification.id));
    }

    // Navigate
    final route = notification.route;
    if (route == null) return;

    // Map route string to Navigator calls
    if (route.startsWith('/chat')) {
      final uri = Uri.parse(route);
      final chatId = uri.queryParameters['chatId'];
      Navigator.pushNamed(context, '/chat',
          arguments: chatId != null ? {'chatId': chatId} : null);
    } else if (route.startsWith('/post/')) {
      final postId = route.split('/').last;
      Navigator.pushNamed(context, '/post/$postId');
    } else if (route.startsWith('/room/')) {
      final roomId = route.split('/').last;
      Navigator.pushNamed(context, '/room/$roomId');
    } else if (route.startsWith('/profile/')) {
      final uid = route.split('/').last;
      Navigator.pushNamed(context, '/profile/$uid');
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  // ── Relative time ──────────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
