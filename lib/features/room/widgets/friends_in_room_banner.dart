// lib/features/room/widgets/friends_in_room_banner.dart
//
// FriendsInRoomBanner – compact strip in the room header showing
// which of the viewer's friends are also in this room.
//
// Usage:
//   FriendsInRoomBanner(friends: presenceList, totalCount: room.viewerCount)
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/neon_colors.dart';
import '../../../../features/room/services/user_presence_service.dart';

class FriendsInRoomBanner extends StatelessWidget {
  /// Friends currently in this room.
  final List<UserPresence> friends;

  /// Total viewer count (for contextual copy).
  final int totalCount;

  /// Max avatars shown before showing "+N more" label.
  final int maxAvatars;

  const FriendsInRoomBanner({
    super.key,
    required this.friends,
    this.totalCount = 0,
    this.maxAvatars = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();

    final visible = friends.take(maxAvatars).toList();
    final overflow = friends.length - visible.length;

    return AppMotion.slideFadeIn(
      beginOffset: const Offset(-16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E27).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: NeonColors.neonBlue.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stacked mini avatars
            SizedBox(
              width: visible.length * 18.0 + 4,
              height: 24,
              child: Stack(
                children: visible.asMap().entries.map((e) {
                  final idx = e.key;
                  final p   = e.value;
                  return Positioned(
                    left: idx * 18.0,
                    child: _MiniAvatar(presence: p),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 6),

            // Text
            Text(
              _label(overflow, friends.length),
              style: TextStyle(
                color: NeonColors.neonBlue.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(int overflow, int total) {
    if (total == 1) return '${friends.first.displayName.split(' ').first} is here';
    if (overflow > 0) return '$total friends here';
    final names = friends.take(2).map((p) => p.displayName.split(' ').first);
    return '${names.join(', ')} ${friends.length == 1 ? "is" : "are"} here';
  }
}

class _MiniAvatar extends StatelessWidget {
  final UserPresence presence;
  const _MiniAvatar({required this.presence});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0A0E27), width: 1.5),
      ),
      child: ClipOval(
        child: presence.avatarUrl.isNotEmpty
            ? Image.network(presence.avatarUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials())
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final letter = presence.displayName.isNotEmpty
        ? presence.displayName[0].toUpperCase()
        : '?';
    return Container(
      color: NeonColors.neonBlue.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Text(letter,
          style: const TextStyle(
            color: NeonColors.neonBlue,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}
