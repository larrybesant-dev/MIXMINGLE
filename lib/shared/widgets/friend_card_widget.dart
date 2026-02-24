/// Friend Card Widget - Design System Compliant
///
/// Displays a friend with:
/// - Avatar + online indicator
/// - Name and presence status
/// - Double-click to join room
/// - Right-click context menu
/// - Animations per DESIGN_BIBLE.md
///
/// Reference: DESIGN_BIBLE.md Sections A, B, C (Colors, Typography, Animations)
/// Pattern: Copy from lib/features/video_room/widgets/presence_card.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_constants.dart';
import '../../shared/providers/friends_presence_provider.dart';
import '../../core/platform/multi_window_room_manager.dart';

/// Friend card showing online status and room info
///
/// Features:
/// - ✅ Custom card (no Material Card)
/// - ✅ Online indicator pulse animation
/// - ✅ Hover glow effect
/// - ✅ Double-click to join friend's room
/// - ✅ Right-click context menu
/// - ✅ All colors from DesignColors
/// - ✅ All spacing from DesignSpacing
/// - ✅ All animations from DesignAnimations
class FriendCardWidget extends ConsumerStatefulWidget {
  /// Friend data with presence
  final FriendWithPresence friend;

  /// Callback when friend is double-clicked to join room
  final Function(FriendWithPresence)? onJoinRoom;

  /// Callback for context menu actions
  final Function(String action, FriendWithPresence)? onContextMenu;

  const FriendCardWidget({
    required this.friend,
    this.onJoinRoom,
    this.onContextMenu,
    super.key,
  });

  @override
  ConsumerState<FriendCardWidget> createState() => _FriendCardWidgetState();
}

class _FriendCardWidgetState extends ConsumerState<FriendCardWidget>
    with TickerProviderStateMixin {
  /// Hover scale animation
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  // ignore: unused_field - kept for potential shadow effects
  late Animation<double> _shadowAnimation;

  /// Online indicator pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isHovered = false;
  // ignore: unused_field - kept for press state handling
  final bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Hover animation
    _hoverController = AnimationController(
      vsync: this,
      duration: DesignAnimations.cardHoverDuration, // 150ms
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: DesignAnimations.easeOutCubic),
    );

    _shadowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: DesignAnimations.easeOutCubic),
    );

    // Pulse animation for online indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: DesignAnimations.speakingPulseDuration, // 200ms
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: DesignAnimations.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        onSecondaryTapDown: (details) => _showContextMenu(context, details),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
              border: Border(
                left: BorderSide(
                  color: _getStatusColor(),
                  width: 3,
                ),
                top: const BorderSide(color: DesignColors.accent, width: 1),
                right: const BorderSide(color: DesignColors.accent, width: 1),
                bottom: const BorderSide(color: DesignColors.accent, width: 1),
              ),
              color: DesignColors.accent,
              boxShadow: _isHovered
                  ? const [
                      DesignShadows.medium,
                    ]
                  : const [
                      DesignShadows.subtle,
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSpacing.lg,
                vertical: DesignSpacing.md,
              ),
              child: Row(
                children: [
                  /// Avatar with online indicator
                  _buildAvatarWithIndicator(),

                  /// Spacing
                  const SizedBox(width: DesignSpacing.lg),

                  /// Friend info
                  Expanded(
                    child: _buildFriendInfo(),
                  ),

                  /// Spacing
                  const SizedBox(width: DesignSpacing.md),

                  /// Status badge
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar with animated online indicator
  Widget _buildAvatarWithIndicator() {
    return Stack(
      children: [
        // Avatar
        CircleAvatar(
          radius: DesignSpacing.avatarMedium / 2,
          backgroundColor: DesignColors.accent,
          backgroundImage: widget.friend.avatarUrl != null
              ? NetworkImage(widget.friend.avatarUrl!)
              : null,
          child: widget.friend.avatarUrl == null
              ? const Icon(
                  Icons.person,
                  color: DesignColors.accent,
                )
              : null,
        ),

        // Online indicator (animated pulse)
        if (widget.friend.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: DesignColors.accent, // Green for online
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DesignColors.accent,
                    width: 2,
                  ),
                ),
              ),
            ),
          )
        else if (widget.friend.isInactive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: DesignColors.accent, // Yellow for idle
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignColors.accent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Friend name and status info
  Widget _buildFriendInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          widget.friend.displayName,
          style: DesignTypography.subheading,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Status / Room info
        const SizedBox(height: DesignSpacing.xs),
        Text(
          widget.friend.tooltipText,
          style: DesignTypography.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Status badge (online/idle/away)
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpacing.md,
        vertical: DesignSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(),
        borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
      ),
      child: Text(
        _getStatusText(),
        style: DesignTypography.label.copyWith(
          color: _getStatusColor(),
        ),
      ),
    );
  }

  /// Get status color based on presence
  Color _getStatusColor() {
    if (widget.friend.isOnline) return DesignColors.accent;
    if (widget.friend.isInactive) return DesignColors.accent;
    return DesignColors.accent;
  }

  /// Get status background color
  Color _getStatusBackgroundColor() {
    if (widget.friend.isOnline) return DesignColors.accent.withValues(alpha: 0.1);
    if (widget.friend.isInactive) return DesignColors.accent.withValues(alpha: 0.1);
    return DesignColors.accent;
  }

  /// Get status text
  String _getStatusText() {
    if (widget.friend.isOnline) return 'Online';
    if (widget.friend.isInactive) return 'Idle';
    return 'Offline';
  }

  /// Handle double-click to join friend's room
  void _handleDoubleTap() {
    if (widget.friend.isOnline && widget.friend.roomId != null) {
      // Open in new window if friend is in a room
      final opened = MultiWindowRoomManager.openRoomWindow(
        roomId: widget.friend.roomId!,
        roomName: widget.friend.roomName ?? 'Room',
        userId: '', // Would come from auth context
      );

      if (opened) {
        widget.onJoinRoom?.call(widget.friend);
      }
    }
  }

  /// Show right-click context menu
  void _showContextMenu(
    BuildContext context,
    TapDownDetails details,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'open_chat',
          child: const Text('💬 Open Chat', style: DesignTypography.body),
          onTap: () => widget.onContextMenu?.call('open_chat', widget.friend),
        ),
        if (widget.friend.isOnline && widget.friend.roomId != null)
          PopupMenuItem(
            value: 'join_room',
            child: const Text('🎤 Join Room', style: DesignTypography.body),
            onTap: () => _handleDoubleTap(),
          ),
        if (widget.friend.isOnline)
          PopupMenuItem(
            value: 'invite_to_room',
            child: const Text('📩 Invite to Room', style: DesignTypography.body),
            onTap: () => widget.onContextMenu?.call('invite_to_room', widget.friend),
          ),
        PopupMenuItem(
          value: 'view_profile',
          child: const Text('👤 View Profile', style: DesignTypography.body),
          onTap: () =>
              widget.onContextMenu?.call('view_profile', widget.friend),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          child: Text(
            '🗑️ Remove Friend',
            style: DesignTypography.body.copyWith(color: DesignColors.accent),
          ),
          onTap: () => widget.onContextMenu?.call('remove', widget.friend),
        ),
      ],
    );
  }
}



