import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Provider for notifications stream
final notificationsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList());
});

/// Provider for unread notification count
final unreadCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// In-app notification center
class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage> {
  final _firestore = FirebaseFirestore.instance;
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Filter toggle
          IconButton(
            icon: Icon(_showUnreadOnly
                ? Icons.mark_email_read
                : Icons.mark_email_unread),
            tooltip: _showUnreadOnly ? 'Show All' : 'Show Unread',
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
            },
          ),
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All Read',
            onPressed: _markAllAsRead,
          ),
          // Settings
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'clear':
                  await _clearAllNotifications();
                  break;
                case 'settings':
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/settings/notifications');
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Notification Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final filteredNotifications = _showUnreadOnly
              ? notifications.where((n) => n['isRead'] != true).toList()
              : notifications;

          if (filteredNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showUnreadOnly
                        ? 'No unread notifications'
                        : 'No notifications yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showUnreadOnly
                        ? 'All caught up!'
                        : 'You\'ll see notifications here when you get them',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
            },
            child: ListView.builder(
              itemCount: filteredNotifications.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return _buildNotificationCard(context, notification);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading notifications',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification) {
    final theme = Theme.of(context);
    final isRead = notification['isRead'] == true;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final type = notification['type'] as String?;
    final createdAt = (notification['createdAt'] as Timestamp?)?.toDate();
    final notificationId = notification['id'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 24,
                ),
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
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'read':
                      await _markAsRead(notificationId, !isRead);
                      break;
                    case 'delete':
                      await _deleteNotification(notificationId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(isRead
                            ? Icons.mark_email_unread
                            : Icons.mark_email_read),
                        const SizedBox(width: 8),
                        Text(isRead ? 'Mark Unread' : 'Mark Read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'event':
      case 'eventInvite':
        return Icons.event;
      case 'match':
        return Icons.favorite;
      case 'follow':
        return Icons.person_add;
      case 'like':
        return Icons.thumb_up;
      case 'eventReminder':
        return Icons.alarm;
      case 'systemAlert':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'event':
      case 'eventInvite':
        return Colors.purple;
      case 'match':
        return Colors.pink;
      case 'follow':
        return Colors.green;
      case 'like':
        return Colors.orange;
      case 'eventReminder':
        return Colors.amber;
      case 'systemAlert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final notificationId = notification['id'] as String;
    final type = notification['type'] as String?;
    final data = notification['data'] as Map<String, dynamic>?;

    // Mark as read
    await _markAsRead(notificationId, true);

    // Check if context is still mounted after async operation
    if (!mounted) return;

    // Navigate based on type
    switch (type) {
      case 'message':
        final conversationId = data?['conversationId'] as String?;
        if (conversationId != null && mounted) {
          Navigator.pushNamed(context, '/chat',
              arguments: {'conversationId': conversationId});
        }
        break;
      case 'event':
      case 'eventInvite':
        final eventId = data?['eventId'] as String?;
        if (eventId != null && mounted) {
          Navigator.pushNamed(context, '/events/details',
              arguments: {'eventId': eventId});
        }
        break;
      case 'match':
        if (mounted) {
          Navigator.pushNamed(context, '/matches');
        }
        break;
      case 'follow':
        final userId = data?['userId'] as String?;
        if (userId != null && mounted) {
          Navigator.pushNamed(context, '/profile/user',
              arguments: {'userId': userId});
        }
        break;
      default:
        break;
    }
  }

  Future<void> _markAsRead(String notificationId, bool isRead) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': isRead,
        'readAt': isRead ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final allDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in allDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
