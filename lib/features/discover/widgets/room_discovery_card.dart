// lib/features/discover/widgets/room_discovery_card.dart
//
// Polished neon room card for the Room Discovery page.
// Two layouts:
//   RoomDiscoveryCard         — full-width list card
//   RoomDiscoveryCardCompact  — compact card for horizontal rail (heating up)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/room.dart';
import '../../../shared/models/friend_request.dart';
import '../../../shared/providers/friend_providers.dart';

// ── Vibe palette (mirrors home_page_electric.dart) ────────────────────────────

const _kVibeColors = <String, Color>{
  'Chill': Color(0xFF4A90FF),
  'Hype': Color(0xFFFF4D8B),
  'Deep Talk': Color(0xFF8B5CF6),
  'Late Night': Color(0xFF6366F1),
  'Study': Color(0xFF00E5CC),
  'Party': Color(0xFFFFAB00),
};
const _kVibeIcons = <String, IconData>{
  'Chill': Icons.waves_outlined,
  'Hype': Icons.bolt,
  'Deep Talk': Icons.forum_outlined,
  'Late Night': Icons.nightlight_outlined,
  'Study': Icons.menu_book_outlined,
  'Party': Icons.celebration_outlined,
};
Color _vc(String? v) => _kVibeColors[v] ?? DesignColors.accent;
IconData _vi(String? v) => _kVibeIcons[v] ?? Icons.graphic_eq;

// ── Type icon helper ──────────────────────────────────────────────────────────

IconData _typeIcon(RoomType t) => switch (t) {
      RoomType.video => Icons.videocam_outlined,
      RoomType.voice => Icons.mic_outlined,
      RoomType.text => Icons.chat_bubble_outline,
    };

Color _typeColor(RoomType t) => switch (t) {
      RoomType.video => const Color(0xFFFF4D8B),
      RoomType.voice => const Color(0xFF00E5CC),
      RoomType.text => DesignColors.accent,
    };

String _typeLabel(RoomType t) => switch (t) {
      RoomType.video => 'Video',
      RoomType.voice => 'Voice',
      RoomType.text => 'Chat',
    };

// ── Full-width card ───────────────────────────────────────────────────────────

class RoomDiscoveryCard extends ConsumerWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomDiscoveryCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vibe = room.vibeTag;
    final vibeColor = _vc(vibe);
    // Friends in this room
    final friends = ref.watch(myFriendsProvider).value ?? [];
    final participantSet = Set<String>.from(room.participantIds);
    final friendsHere = friends
        .where((f) => participantSet.contains(f.uid))
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: vibe != null
                ? vibeColor.withValues(alpha: 0.3)
                : DesignColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: vibeColor.withValues(alpha: 0.06),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: badges + viewer count ────────────────────────────
              Row(
                children: [
                  _LiveBadge(),
                  const SizedBox(width: 6),
                  _TypeBadge(type: room.roomType),
                  if (vibe != null) ...[
                    const SizedBox(width: 6),
                    _VibeBadge(vibe: vibe, color: vibeColor),
                  ],
                  if (room.isPremiumRoom) ...[
                    const SizedBox(width: 6),
                    _PremiumBadge(),
                  ],
                  const Spacer(),
                  // Viewer count
                  Row(
                    children: [
                      const Icon(Icons.people,
                          size: 14, color: DesignColors.textGray),
                      const SizedBox(width: 4),
                      Text(
                        '${room.viewerCount}',
                        style: const TextStyle(
                          color: DesignColors.textLightGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Lock icon
                  if (room.isLocked) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_outline,
                        size: 14, color: DesignColors.textGray),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // ── Title ──────────────────────────────────────────────────────
              Text(
                room.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  room.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignColors.textGray,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // ── Footer: host + category ────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          vibeColor,
                          vibeColor.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (room.hostName ?? 'H')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      room.hostName ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesignColors.textLightGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Category pill
                  _CategoryBadge(category: room.category),
                  // Heating up badge
                  if (room.joinVelocity > 3) ...[
                    const SizedBox(width: 6),
                    _HeatBadge(),
                  ],
                ],
              ),
              // Friends in room strip
              if (friendsHere.isNotEmpty) ...[
                const SizedBox(height: 8),
                _FriendsStrip(friends: friendsHere),
              ],
              // Tags row (if any)
              if (room.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: room.tags.take(4).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: DesignColors.divider, width: 0.5),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: DesignColors.textGray,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact card (heating-up rail) ────────────────────────────────────────────

class RoomDiscoveryCardCompact extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomDiscoveryCardCompact({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vibe = room.vibeTag;
    final vibeColor = _vc(vibe);
    final typeIcon = _typeIcon(room.roomType);
    final typeColor = _typeColor(room.roomType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              vibeColor.withValues(alpha: 0.18),
              DesignColors.surfaceLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: vibeColor.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: vibeColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: typeColor.withValues(alpha: 0.15),
                border: Border.all(color: typeColor.withValues(alpha: 0.4)),
              ),
              child:
                  Icon(typeIcon, size: 18, color: typeColor),
            ),
            const Spacer(),
            // Title
            Text(
              room.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DesignColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            // Viewer count + vibe icon row
            Row(
              children: [
                const Icon(Icons.people, size: 12, color: DesignColors.textGray),
                const SizedBox(width: 3),
                Text(
                  '${room.viewerCount}',
                  style: const TextStyle(
                    color: DesignColors.textGray,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (vibe != null)
                  Icon(_vi(vibe), size: 13, color: vibeColor),
              ],
            ),
            if (room.joinVelocity > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      size: 11, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 3),
                  Text(
                    '+${room.joinVelocity} joining',
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Badge sub-widgets ─────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 7, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final RoomType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            _typeLabel(type),
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _VibeBadge extends StatelessWidget {
  final String vibe;
  final Color color;
  const _VibeBadge({required this.vibe, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_vi(vibe), size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            vibe,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignColors.gold, Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 9, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DesignColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: DesignColors.gold.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: DesignColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeatBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 10, color: Color(0xFFFF6B35)),
          SizedBox(width: 2),
          Text(
            'Hot',
            style: TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 9,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
// ── Friends-in-room strip ─────────────────────────────────────────────────────

class _FriendsStrip extends StatelessWidget {
  final List<FriendEntry> friends;
  const _FriendsStrip({required this.friends});

  @override
  Widget build(BuildContext context) {
    final visible = friends.take(3).toList();
    final overflow = friends.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stacked mini-avatars
        SizedBox(
          width: visible.length * 16.0 + 4,
          height: 20,
          child: Stack(
            children: visible.asMap().entries.map((e) {
              final p = e.value;
              final letter = (p.displayName ?? p.uid)[0].toUpperCase();
              return Positioned(
                left: e.key * 16.0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: DesignColors.background, width: 1.5),
                  ),
                  child: ClipOval(
                    child: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                        ? Image.network(p.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _initial(letter))
                        : _initial(letter),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.people, size: 11, color: DesignColors.accent),
        const SizedBox(width: 3),
        Text(
          overflow > 0
              ? '${friends.length} friends here'
              : friends.length == 1
                  ? '${visible.first.displayName?.split(' ').first ?? 'Friend'} is here'
                  : '${friends.length} friends here',
          style: const TextStyle(
            color: DesignColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _initial(String letter) => Container(
        color: DesignColors.accent.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: Text(letter,
            style: const TextStyle(
                color: DesignColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      );
}
