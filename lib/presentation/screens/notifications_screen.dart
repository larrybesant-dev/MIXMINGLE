import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../../core/logger.dart';
import '../../features/feed/widgets/feed_empty_state.dart';
import '../../widgets/mixvy_drawer.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  // ── Navigation ────────────────────────────────────────────────────────────

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

  // ── Icon + Color helpers ──────────────────────────────────────────────────

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

  Color _colorForType(String type) {
    switch (type) {
      case 'follow':
        return const Color(0xFF4FC3F7);
      case 'friend_request':
        return NeonPulse.secondary;
      case 'friend_favorite':
        return const Color(0xFFFFD54F);
      case 'friend_accept':
        return const Color(0xFF81C784);
      case 'live_room_invite':
        return const Color(0xFF4DB6AC);
      case 'speed_dating_match':
        return const Color(0xFFFF6EB4);
      case 'gift':
        return const Color(0xFFFFB74D);
      case 'like':
        return NeonPulse.error;
      case 'comment':
        return const Color(0xFF9FA8DA);
      default:
        return NeonPulse.primary;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'follow':
        return 'New follower';
      case 'friend_request':
        return 'Friend request';
      case 'friend_accept':
        return 'Friend accepted';
      case 'friend_favorite':
        return 'Favorited you';
      case 'live_room_invite':
        return 'Room invite';
      case 'speed_dating_match':
        return 'Speed date match';
      case 'gift':
        return 'Gift received';
      case 'like':
        return 'New like';
      case 'comment':
        return 'New comment';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentNotificationUserIdProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final service = ref.read(notificationServiceProvider);

    return Scaffold(
      backgroundColor: NeonPulse.surface,
      drawer: const MixVyDrawer(),
      appBar: AppBar(
        backgroundColor: NeonPulse.surfaceHigh,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: NeonPulse.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.done_all_rounded,
                  color: NeonPulse.onSurfaceVariant),
              tooltip: 'Mark all as read',
              onPressed: () => service.markAllRead(userId),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: NeonPulse.onSurfaceVariant),
            tooltip: 'Notification settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: userId == null
          ? const Center(
              child: Text(
                'Please sign in to view notifications.',
                style: TextStyle(color: NeonPulse.onSurfaceVariant),
              ),
            )
          : Column(
              children: [
                if (!notificationsEnabled)
                  Container(
                    width: double.infinity,
                    color: NeonPulse.surfaceBright,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_off_outlined,
                            size: 16, color: NeonPulse.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Push notifications are disabled.',
                            style: TextStyle(
                                color: NeonPulse.onSurfaceVariant,
                                fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/settings'),
                          style: TextButton.styleFrom(
                              foregroundColor: NeonPulse.primary,
                              padding: EdgeInsets.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Enable',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: notificationsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: NeonPulse.primary),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Could not load notifications: $error',
                        style: const TextStyle(
                            color: NeonPulse.onSurfaceVariant),
                      ),
                    ),
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return const FeedEmptyState(
                          emoji: '🔔',
                          heading: 'All caught up!',
                          message:
                              'You have no notifications yet.\nRoom invites, friend requests and gift alerts will appear here.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: NeonPulse.outlineVariant,
                          indent: 72,
                        ),
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return _NotificationTile(
                            notification: n,
                            icon: _iconForType(n.type),
                            color: _colorForType(n.type),
                            label: _labelForType(n.type),
                            timeAgo: _relativeTime(n.createdAt),
                            onTap: () => _handleNotificationTap(
                                context, userId, n, service),
                            onMarkRead: n.isRead
                                ? null
                                : () async {
                                    try {
                                      await service.markRead(userId, n.id);
                                    } catch (e) {
                                      Logger.log(
                                          'Mark read failed: $e');
                                    }
                                  },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.label,
    required this.timeAgo,
    required this.onTap,
    this.onMarkRead,
  });

  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final String label;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? NeonPulse.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: unread
                                ? NeonPulse.onSurface
                                : NeonPulse.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: NeonPulse.onSurfaceVariant,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: NeonPulse.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: NeonPulse.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Friend request inline actions
                  if (notification.type == 'friend_request') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ActionChip(
                          label: 'View Request',
                          color: NeonPulse.primary,
                          onTap: onTap,
                        ),
                      ],
                    ),
                  ],
                  // Room invite inline action
                  if (notification.type == 'live_room_invite') ...[
                    const SizedBox(height: 10),
                    _ActionChip(
                      label: 'Join Room',
                      color: const Color(0xFF4DB6AC),
                      onTap: onTap,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

