// lib/features/home/widgets/active_friends_row.dart
//
// ActiveFriendsRow – horizontal scrollable row of friend avatars that
// are currently online or recently active, shown on the home screen.
//
// Data source: activeFriendsProvider (social_graph_providers.dart)
//   → follows users/{uid}/following subcollection + presence/{uid} Firestore
//
// Avatar ring states:
//   - online   : solid neon green ring
//   - away     : cyan ring with pulse
//   - offline  : not shown (filtered before reaching this widget)
//
// Usage (Consumer):
//   ActiveFriendsRow()  ← self-contained, no props required
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/neon_colors.dart';
import '../../../shared/models/user_presence.dart';
import '../../../shared/providers/friends_presence_provider.dart';
import '../../../shared/providers/social_graph_providers.dart';

/// Self-contained active friends row driven by [activeFriendsProvider].
class ActiveFriendsRow extends ConsumerWidget {
  /// Optional tap callback. Receives the userId of the tapped friend.
  final void Function(String userId)? onAvatarTap;

  const ActiveFriendsRow({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFriendsAsync = ref.watch(activeFriendsProvider);

    return activeFriendsAsync.when(
      data: (presences) {
        if (presences.isEmpty) return const SizedBox.shrink();
        return _buildRow(context, ref, presences);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, List<UserPresence> presences) {
    return AppMotion.slideFadeIn(
      beginOffset: const Offset(0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: NeonColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Active Now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${presences.length})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: presences.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (ctx, i) => _FriendAvatar(
                presence: presences[i],
                onTap: () => onAvatarTap?.call(presences[i].userId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Single friend avatar with animated ring (driven by UserPresence)
// ─────────────────────────────────────────────────────────────────
class _FriendAvatar extends ConsumerStatefulWidget {
  final UserPresence presence;
  final VoidCallback? onTap;

  const _FriendAvatar({required this.presence, this.onTap});

  @override
  ConsumerState<_FriendAvatar> createState() => _FriendAvatarState();
}

class _FriendAvatarState extends ConsumerState<_FriendAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    if (_shouldPulse) _ctrl.repeat(reverse: true);
  }

  bool get _shouldPulse => widget.presence.state == PresenceState.online ||
      widget.presence.state == PresenceState.away;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch friend profile for avatar / display name
    final friendDataAsync = ref.watch(friendDataProvider(widget.presence.userId));
    final displayName = friendDataAsync.value?['displayName'] as String? ?? '?';
    final avatarUrl = friendDataAsync.value?['avatarUrl'] as String?;

    final ringColor = _ringColor(widget.presence.state);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              final t = AppMotion.pulse.transform(_ctrl.value);
              final alpha = _shouldPulse ? 0.55 + t * 0.45 : 0.4;
              final blur = _shouldPulse ? 4.0 + t * 6.0 : 0.0;

              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ringColor.withValues(alpha: alpha),
                    width: 2.0,
                  ),
                  boxShadow: _shouldPulse
                      ? [
                          BoxShadow(
                            color: ringColor.withValues(alpha: t * 0.5),
                            blurRadius: blur,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(child: child),
              );
            },
            child: _buildAvatar(avatarUrl, displayName, ringColor),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              displayName.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String displayName, Color ringColor) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsAvatar(displayName, ringColor),
      );
    }
    return _initialsAvatar(displayName, ringColor);
  }

  Widget _initialsAvatar(String displayName, Color ringColor) {
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      color: ringColor.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: ringColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  Color _ringColor(PresenceState state) {
    switch (state) {
      case PresenceState.online:
        return NeonColors.successGreen;
      case PresenceState.away:
      case PresenceState.idle:
        return NeonColors.neonBlue;
      case PresenceState.offline:
        return Colors.grey.shade600;
    }
  }
}

