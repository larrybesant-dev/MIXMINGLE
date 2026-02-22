// Enhanced Notification Widget - Display app notifications with actions and animations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_models.dart';
import '../../core/design_system/design_constants.dart';
import '../../providers/notification_provider.dart';

class NotificationWidget extends ConsumerStatefulWidget {
  final AppNotification notification;
  final VoidCallback? onDismissed;
  final Duration dismissDuration;

  const NotificationWidget({
    required this.notification,
    this.onDismissed,
    this.dismissDuration = const Duration(seconds: 5),
    super.key,
  });

  @override
  ConsumerState<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends ConsumerState<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start animation
    _animationController.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.dismissDuration, () {
      if (mounted && !_isDismissed) {
        _dismissNotification();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissNotification() {
    if (_isDismissed) return;

    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isDismissed = true);
        widget.onDismissed?.call();
        ref.read(notificationsProvider.notifier).removeNotification(widget.notification.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
            color: DesignColors.accent,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: _getNotificationColor(widget.notification.type),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: DesignColors.accent.withValues(alpha: _isHovered ? 0.4 : 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(DesignSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon, title, and close button
                    Row(
                      children: [
                        // Notification icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DesignColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getNotificationIcon(widget.notification.type),
                            color: DesignColors.accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title and message
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notification.title,
                                style: const TextStyle(
                                  color: DesignColors.accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.notification.senderName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'From ${widget.notification.senderName}',
                                  style: const TextStyle(
                                    color: DesignColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: DesignColors.accent,
                          iconSize: 20,
                          onPressed: _dismissNotification,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    // Message body
                    const SizedBox(height: 12),
                    Text(
                      widget.notification.message,
                      style: TextStyle(
                        color: DesignColors.accent.withValues(alpha: 0.87),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Action buttons if available
                    if (widget.notification.actions != null &&
                        widget.notification.actions!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildActionButtons(context),
                    ],
                    // Progress bar for auto-dismiss
                    const SizedBox(height: 12),
                    _buildProgressBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actions = widget.notification.actions!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        return SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: () {
              action.onPressed?.call();
              _dismissNotification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignColors.accent.withValues(alpha: 0.25),
              foregroundColor: DesignColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action.icon != null) ...[
                  Icon(
                    _parseIconString(action.icon),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: 1.0 - (_animationController.value / 1.0),
        backgroundColor: DesignColors.accent.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation(
          DesignColors.accent.withValues(alpha: 0.6),
        ),
        minHeight: 3,
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'friend_request':
        return DesignColors.accent; // Blue
      case 'message':
        return DesignColors.success; // Green
      case 'video_call':
        return DesignColors.tertiary; // Purple
      case 'group_invite':
        return DesignColors.warning; // Orange
      case 'system_alert':
        return DesignColors.textGray; // Grey
      default:
        return DesignColors.accent; // Default Blue
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'message':
        return Icons.mail;
      case 'video_call':
        return Icons.videocam;
      case 'group_invite':
        return Icons.group;
      case 'system_alert':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  IconData _parseIconString(String? iconName) {
    if (iconName == null) return Icons.check;

    switch (iconName.toLowerCase()) {
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'reply':
        return Icons.reply;
      case 'share':
        return Icons.share;
      case 'call':
        return Icons.call;
      case 'accept':
        return Icons.check_circle;
      case 'decline':
        return Icons.cancel;
      default:
        return Icons.check;
    }
  }
}

/// Global notification container widget for displaying multiple notifications
class NotificationStack extends ConsumerWidget {
  final Alignment alignment;
  final EdgeInsets padding;

  const NotificationStack({
    this.alignment = Alignment.topRight,
    this.padding = const EdgeInsets.all(DesignSpacing.lg),
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignment == Alignment.topRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < notifications.length && i < 3; i++)
                NotificationWidget(
                  notification: notifications[i],
                  key: ValueKey(notifications[i].id),
                  dismissDuration: Duration(
                    seconds: 5 + (i * 1), // Stagger auto-dismiss times
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Global notification helper extensions
extension NotificationHelperX on WidgetRef {
  /// Show a new message notification
  void showMessageNotification({
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String message,
    required String roomId,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Message',
      message: message,
      type: 'message',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: {'roomId': roomId},
      icon: 'mail',
      priority: 1,
      actions: [
        NotificationAction(
          id: 'reply',
          label: 'Reply',
          icon: 'reply',
        ),
        NotificationAction(
          id: 'view',
          label: 'View',
          icon: 'check',
        ),
      ],
    );

    read(notificationsProvider.notifier).addNotification(notification);
  }

  /// Show a friend request notification
  void showFriendRequestNotification({
    required String senderId,
    required String senderName,
    required String senderAvatar,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Friend Request',
      message: '$senderName sent you a friend request',
      type: 'friend_request',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      timestamp: DateTime.now(),
      isRead: false,
      icon: 'person_add',
      priority: 1,
      actions: [
        NotificationAction(
          id: 'accept',
          label: 'Accept',
          icon: 'accept',
        ),
        NotificationAction(
          id: 'decline',
          label: 'Decline',
          icon: 'decline',
        ),
      ],
    );

    read(notificationsProvider.notifier).addNotification(notification);
  }

  /// Show a group invite notification
  void showGroupInviteNotification({
    required String groupId,
    required String groupName,
    required String groupImage,
    required String inviterId,
    required String inviterName,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Group Invite',
      message: '$inviterName invited you to $groupName',
      type: 'group_invite',
      senderId: inviterId,
      senderName: inviterName,
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: groupImage,
      icon: 'group',
      priority: 1,
      metadata: {'groupId': groupId},
      actions: [
        NotificationAction(
          id: 'accept',
          label: 'Accept',
          icon: 'accept',
        ),
        NotificationAction(
          id: 'decline',
          label: 'Decline',
          icon: 'decline',
        ),
      ],
    );

    read(notificationsProvider.notifier).addNotification(notification);
  }

  /// Show a system alert notification
  void showSystemAlert({
    required String title,
    required String message,
    String? imageUrl,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: 'system_alert',
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
      icon: 'info',
      priority: 0,
    );

    read(notificationsProvider.notifier).addNotification(notification);
  }

  /// Show an incoming video call notification
  void showIncomingCallNotification({
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String roomId,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Incoming Call',
      message: '$callerName is calling...',
      type: 'video_call',
      senderId: callerId,
      senderName: callerName,
      senderAvatar: callerAvatar,
      timestamp: DateTime.now(),
      isRead: false,
      icon: 'videocam',
      priority: 2,
      metadata: {'roomId': roomId},
      actions: [
        NotificationAction(
          id: 'accept',
          label: 'Accept',
          icon: 'call',
        ),
        NotificationAction(
          id: 'decline',
          label: 'Decline',
          icon: 'close',
        ),
      ],
    );

    read(notificationsProvider.notifier).addNotification(notification);
  }
}



