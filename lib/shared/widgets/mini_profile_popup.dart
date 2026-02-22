/// Mini Profile Popup Widget
///
/// Displays a compact profile card on mouse hover over participant tiles.
/// Shows user avatar, name, bio snippet, online status, and quick action buttons.
///
/// Usage:
/// ```dart
/// MiniProfilePopup(
///   userId: 'user123',
///   userName: 'John Doe',
///   avatarUrl: 'https://...',
///   isOnline: true,
///   onViewProfile: () => navigateToProfile(),
///   onSendFriendRequest: () => sendRequest(),
///   onTip: () => showTipDialog(),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_constants.dart';
import '../../shared/models/user_profile.dart';
import '../../providers/user_providers.dart';

class MiniProfilePopup extends ConsumerWidget {
  final String userId;
  final String userName;
  final String avatarUrl;
  final bool isOnline;
  final VoidCallback? onViewProfile;
  final VoidCallback? onSendFriendRequest;
  final VoidCallback? onTip;
  final VoidCallback? onDismiss;

  const MiniProfilePopup({
    super.key,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    this.isOnline = false,
    this.onViewProfile,
    this.onSendFriendRequest,
    this.onTip,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch additional user data
    final userProfileAsync = ref.watch(userProfileProvider(userId));
    final userPresenceAsync = ref.watch(userPresenceProvider(userId));

    // Get online status from presence or fallback to prop
    final actuallyOnline = userPresenceAsync.maybeWhen(
      data: (presence) => presence?.isOnline ?? isOnline,
      orElse: () => isOnline,
    );

    return MouseRegion(
      onExit: (_) => onDismiss?.call(),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignColors.surfaceLight,
                DesignColors.surfaceDefault,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignColors.accent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignColors.accent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar and online indicator
              _buildHeader(actuallyOnline),

              // User info section
              _buildUserInfo(userProfileAsync),

              // Quick stats
              _buildQuickStats(userProfileAsync),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool actuallyOnline) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: actuallyOnline ? DesignColors.success : Colors.grey,
                    width: 3,
                  ),
                  boxShadow: actuallyOnline
                      ? [
                          BoxShadow(
                            color: DesignColors.success.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: DesignColors.surfaceDefault,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 32, color: Colors.white70)
                      : null,
                ),
              ),
              // Online indicator dot
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: actuallyOnline ? DesignColors.success : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignColors.surfaceLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? DesignColors.success.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: isOnline ? DesignColors.success : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AsyncValue<UserProfile?> userProfileAsync) {
    return userProfileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final bio = profile?.bio ?? '';
        if (bio.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            bio,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(AsyncValue<UserProfile?> userProfileAsync) {
    return userProfileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final followers = profile?.followersCount ?? 0;
        final following = profile?.followingCount ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.people, '$followers', 'Followers'),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              _buildStatItem(Icons.person_add, '$following', 'Following'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DesignColors.accent),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          // View Profile button
          Expanded(
            child: _ActionButton(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: onViewProfile,
            ),
          ),
          const SizedBox(width: 8),
          // Add Friend button
          Expanded(
            child: _ActionButton(
              icon: Icons.person_add_outlined,
              label: 'Add',
              onTap: onSendFriendRequest,
            ),
          ),
          const SizedBox(width: 8),
          // Tip button
          Expanded(
            child: _ActionButton(
              icon: Icons.monetization_on_outlined,
              label: 'Tip',
              onTap: onTip,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual action button for mini-profile popup
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary
                ? DesignColors.accent
                : DesignColors.surfaceDefault.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary
                  ? DesignColors.accent
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a mini-profile popup overlay at the given position
void showMiniProfilePopup({
  required BuildContext context,
  required WidgetRef ref,
  required Offset position,
  required String userId,
  required String userName,
  required String avatarUrl,
  required bool isOnline,
  VoidCallback? onViewProfile,
  VoidCallback? onSendFriendRequest,
  VoidCallback? onTip,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  // Calculate position to keep popup on screen
  final screenSize = MediaQuery.of(context).size;
  final popupWidth = 280.0;
  final popupHeight = 300.0;

  double left = position.dx;
  double top = position.dy;

  // Adjust if popup would go off right edge
  if (left + popupWidth > screenSize.width - 20) {
    left = left - popupWidth - 20;
  }

  // Adjust if popup would go off bottom edge
  if (top + popupHeight > screenSize.height - 20) {
    top = screenSize.height - popupHeight - 20;
  }

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Dismiss area
        Positioned.fill(
          child: GestureDetector(
            onTap: () => overlayEntry.remove(),
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Popup
        Positioned(
          left: left,
          top: top,
          child: MiniProfilePopup(
            userId: userId,
            userName: userName,
            avatarUrl: avatarUrl,
            isOnline: isOnline,
            onViewProfile: () {
              overlayEntry.remove();
              onViewProfile?.call();
            },
            onSendFriendRequest: () {
              overlayEntry.remove();
              onSendFriendRequest?.call();
            },
            onTip: () {
              overlayEntry.remove();
              onTip?.call();
            },
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ],
    ),
  );

  overlay.insert(overlayEntry);
}
