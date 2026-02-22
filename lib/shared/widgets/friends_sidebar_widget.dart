/// Friends Sidebar Widget - Enhanced with collapsible behavior, animations, and hover effects
///
/// Features:
/// - Smooth collapse/expand animation (300ms)
/// - Hover effects on friend items (scale 1.02x + elevation shadow)
/// - Selection highlight with themed border and background
/// - Online status indicator with pulsing animation
/// - Search and filter capabilities
/// - Responsive design with adaptive width
/// - Dark/light theme support via darkModeProvider
///
/// Usage:
/// ```dart
/// FriendsSidebarWidget(
///   onCollapse: () => print('Sidebar collapsed'),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_models.dart';
import '../../providers/friends_provider.dart';
import '../../providers/ui_provider.dart';
import '../constants/ui_constants.dart';
import 'collapsible_sidebar.dart';
import '../../core/design_system/design_constants.dart';

/// Main friends sidebar widget with collapsible functionality
class FriendsSidebarWidget extends ConsumerStatefulWidget {
  final VoidCallback onCollapse;

  const FriendsSidebarWidget({
    required this.onCollapse,
    super.key,
  });

  @override
  ConsumerState<FriendsSidebarWidget> createState() =>
      _FriendsSidebarWidgetState();
}

class _FriendsSidebarWidgetState extends ConsumerState<FriendsSidebarWidget> {
  late TextEditingController _searchController;
  bool _showOnlineOnly = false;
  bool _showFavoritesOnly = false;
  String? _selectedFriendId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    final friends = ref.watch(friendsProvider);
    final filteredFriends = ref.watch(filteredFriendsProvider);
    final unreadCount = ref.watch(totalUnreadMessagesProvider);

    // Apply additional filters
    final displayedFriends = filteredFriends.when(
      data: (filtered) {
        var result = filtered;
        if (_showOnlineOnly) {
          result = result.where((f) => f.isOnline).toList();
        }
        if (_showFavoritesOnly) {
          result = result.where((f) => f.isFavorite).toList();
        }
        return result;
      },
      loading: () => const <Friend>[],
      error: (_, __) => const <Friend>[],
    );

    return CollapsibleSidebar(
      title: 'Friends',
      icon: Icons.people,
      width: WidgetSizes.sidebarWidth,
      collapsedWidth: 70,
      onCollapsedChanged: widget.onCollapse,
      child: Column(
        children: [
          /// Header with title and badge
          _buildHeader(context, darkMode, friends, unreadCount),

          /// Search bar
          _buildSearchBar(context, darkMode),

          /// Filter buttons
          _buildFilterButtons(),

          /// Friends list
          Expanded(
            child: displayedFriends.isEmpty
                ? _buildEmptyState(context, darkMode)
                : _buildFriendsList(context, displayedFriends),
          ),
        ],
      ),
    );
  }

  /// Builds the header with title, friend count, and unread messages badge
  Widget _buildHeader(BuildContext context, bool darkMode, List<Friend> friends,
      int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: darkMode ? DesignColors.accent : DesignColors.accent,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people,
                size: WidgetSizes.mediumIconSize,
                color: DesignColors.textPrimary,
              ),
              const SizedBox(width: Spacing.md),
              Text(
                'Friends',
                style: AppTextStyles.h5.copyWith(
                  color: DesignColors.textPrimary,
                ),
              ),
              if (friends.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: Spacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DesignColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(BorderRadii.lg),
                    ),
                    child: Text(
                      friends.length.toString(),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DesignColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DesignColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '$unreadCount unread messages',
                    style: AppTextStyles.caption.copyWith(
                      color: DesignColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the search bar with animations
  Widget _buildSearchBar(BuildContext context, bool darkMode) {
    return Padding(
      padding: const EdgeInsets.all(DesignSpacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(friendSearchQueryProvider.notifier).setQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Search friends...',
          hintStyle: TextStyle(
            color: darkMode ? DesignColors.accent : DesignColors.accent,
          ),
          prefixIcon: const Icon(Icons.search, size: WidgetSizes.smallIconSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadii.lg),
            borderSide: BorderSide(
              color: darkMode ? DesignColors.accent : DesignColors.accent,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignSpacing.md,
            vertical: DesignSpacing.sm,
          ),
          filled: true,
          fillColor: darkMode ? DesignColors.accent : DesignColors.accent,
        ),
        style: AppTextStyles.body2.copyWith(
          color: darkMode ? DesignColors.accent : DesignColors.accent,
        ),
      ),
    );
  }

  /// Builds filter chips for online and favorites filtering
  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('Online'),
              selected: _showOnlineOnly,
              onSelected: (selected) {
                setState(() => _showOnlineOnly = selected);
              },
              backgroundColor: DesignColors.surfaceLight,
              selectedColor: DesignColors.accent.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: FilterChip(
              label: const Text('⭐'),
              selected: _showFavoritesOnly,
              onSelected: (selected) {
                setState(() => _showFavoritesOnly = selected);
              },
              backgroundColor: DesignColors.surfaceLight,
              selectedColor: DesignColors.accent.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty state message
  Widget _buildEmptyState(BuildContext context, bool darkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 48,
            color: DesignColors.textSecondary,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No friends found',
            style: AppTextStyles.body1.copyWith(
              color: DesignColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the friends list with animated items
  Widget _buildFriendsList(BuildContext context, List<Friend> friends) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        final isSelected = _selectedFriendId == friend.id;

        return _AnimatedFriendTile(
          friend: friend,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedFriendId = isSelected ? null : friend.id;
            });
          },
          onToggleFavorite: () {
            ref.read(friendsProvider.notifier).toggleFavorite(friend.id);
          },
          onOpenChat: () {
            setState(() => _selectedFriendId = friend.id);
            // Open chat in main area
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening chat with ${friend.name}'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(Spacing.md),
                duration: const Duration(milliseconds: 1500),
              ),
            );
          },
        );
      },
    );
  }
}

/// Animated friend tile with hover and selection effects
class _AnimatedFriendTile extends ConsumerStatefulWidget {
  final Friend friend;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenChat;

  const _AnimatedFriendTile({
    required this.friend,
    required this.isSelected,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onOpenChat,
  });

  @override
  ConsumerState<_AnimatedFriendTile> createState() =>
      _AnimatedFriendTileState();
}

class _AnimatedFriendTileState extends ConsumerState<_AnimatedFriendTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  // ignore: unused_field - kept for potential shadow effects
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AnimationDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: AppCurves.easeOut),
    );

    _shadowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: AppCurves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
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
              borderRadius: BorderRadius.circular(BorderRadii.md),
              border: Border.all(
                color: widget.isSelected
                    ? DesignColors.accent.withValues(alpha: 0.5)
                    : DesignColors.surfaceLight,
                width: widget.isSelected ? 2 : 1,
              ),
              color: widget.isSelected
                  ? DesignColors.accent.withValues(alpha: 0.1)
                  : (_isHovered ? DesignColors.surfaceLight : DesignColors.cardBackground),
              boxShadow: _isHovered || widget.isSelected
                  ? AppShadows.elevation2
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(BorderRadii.md),
                hoverColor: DesignColors.accent.withValues(alpha: 0.1),
                splashColor: DesignColors.accent.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.md,
                  ),
                  child: Row(
                    children: [
                      /// Avatar with online indicator
                      _buildAvatarWithOnlineIndicator(),

                      /// Friend info
                      Expanded(
                        child: _buildFriendInfo(darkMode),
                      ),

                      /// Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds avatar with animated online indicator
  Widget _buildAvatarWithOnlineIndicator() {
    return Stack(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.friend.avatarUrl),
          radius: 20,
        ),
        if (widget.friend.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: _PulsingOnlineIndicator(),
          ),
      ],
    );
  }

  /// Builds friend name and status info
  Widget _buildFriendInfo(bool darkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.friend.name,
            style: AppTextStyles.body1.copyWith(
              color: darkMode ? DesignColors.accent : DesignColors.accent,
              fontWeight:
                  widget.isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            widget.friend.isOnline
                ? 'Online'
                : 'Active ${_getTimeAgo(widget.friend.lastSeen)}',
            style: AppTextStyles.caption.copyWith(
              color: widget.friend.isOnline
                  ? DesignColors.accent
                  : DesignColors.accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds action buttons (favorite + unread badge)
  Widget _buildActionButtons() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: Spacing.xs,
      children: [
        if (widget.friend.unreadMessages > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: DesignColors.error,
              borderRadius: BorderRadius.circular(BorderRadii.lg),
            ),
            child: Text(
              widget.friend.unreadMessages.toString(),
              style: AppTextStyles.caption.copyWith(
                color: DesignColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: AnimationDurations.fast,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                widget.friend.isFavorite ? Icons.star : Icons.star_border,
                key: ValueKey(widget.friend.isFavorite),
                size: WidgetSizes.mediumIconSize,
                color: widget.friend.isFavorite
                    ? DesignColors.gold
                    : DesignColors.textSecondary,
              ),
            ),
            onPressed: widget.onToggleFavorite,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  /// Helper to format time differences
  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time).inMinutes;
    if (difference < 1) return 'now';
    if (difference < 60) return '${difference}m';
    final hours = difference ~/ 60;
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    return '${days}d';
  }
}

/// Pulsing online indicator animation
class _PulsingOnlineIndicator extends StatefulWidget {
  @override
  State<_PulsingOnlineIndicator> createState() =>
      _PulsingOnlineIndicatorState();
}

class _PulsingOnlineIndicatorState extends State<_PulsingOnlineIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 * _animation.value,
              height: 14 * _animation.value,
              decoration: BoxDecoration(
                color: DesignColors.success.withValues(alpha: 0.3 / _animation.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: DesignColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignColors.cardBackground,
                  width: 2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}




