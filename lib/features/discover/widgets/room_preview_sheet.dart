// lib/features/discover/widgets/room_preview_sheet.dart
//
// RoomPreviewSheet — bottom-sheet room preview before joining.
//
// Shows: room info, vibe badge, viewer count, join velocity,
//        friends-in-room strip, tags, and a big "Join Now" button.
//
// Usage:
//   RoomPreviewSheet.show(context, room: room, onJoin: () => _joinRoom(room));
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart' as core_analytics;
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/room.dart';
import '../../../shared/models/friend_request.dart';
import '../providers/room_discovery_providers.dart';

// ── Vibe colours (mirrored from card) ────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────

class RoomPreviewSheet extends ConsumerWidget {
  final Room room;
  final VoidCallback onJoin;

  const RoomPreviewSheet({
    super.key,
    required this.room,
    required this.onJoin,
  });

  // ── Static convenience method ─────────────────────────────────────────────

  static Future<void> show(
    BuildContext context, {
    required Room room,
    required VoidCallback onJoin,
  }) {
    // Phase 5 analytics: discovery_room_preview_opened
    core_analytics.AnalyticsService.instance.logEvent(
      name: 'discovery_room_preview_opened',
      parameters: {'room_id': room.id, 'room_title': room.title},
    );
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoomPreviewSheet(room: room, onJoin: onJoin),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsHere = ref.watch(friendsInRoomProvider(room.id));
    final vibe = room.vibeTag;
    final vibeColor = _vc(vibe);

    return Container(
      decoration: BoxDecoration(
        color: DesignColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
              color: vibeColor.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: vibeColor.withValues(alpha: 0.15),
            blurRadius: 24,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Badges row ────────────────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _LiveBadge(),
                  _TypeBadge(type: room.roomType),
                  if (vibe != null)
                    _VibeBadge(vibe: vibe, color: vibeColor),
                  if (room.isPremiumRoom) _PremiumBadge(),
                  if (room.joinVelocity > 3) _HotBadge(),
                ],
              ),
              const SizedBox(height: 14),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                room.title,
                style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              // ── Description ───────────────────────────────────────────────
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  room.description,
                  style: const TextStyle(
                    color: DesignColors.textGray,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Stats row ─────────────────────────────────────────────────
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people_outlined,
                    label: '${room.viewerCount} listening',
                    color: DesignColors.textLightGray,
                  ),
                  if (room.joinVelocity > 0) ...[
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.local_fire_department,
                      label: '+${room.joinVelocity} joining',
                      color: const Color(0xFFFF6B35),
                    ),
                  ],
                  if (room.maxUsers > 0) ...[
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.person_outline,
                      label: '${room.participantIds.length}/${room.maxUsers}',
                      color: DesignColors.textGray,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ── Host row ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          vibeColor,
                          vibeColor.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (room.hostName ?? 'H').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hosted by',
                        style: TextStyle(
                          color: DesignColors.textGray,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        room.hostName ?? 'Unknown',
                        style: const TextStyle(
                          color: DesignColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Friends in room ───────────────────────────────────────────
              if (friendsHere.isNotEmpty) ...[
                const SizedBox(height: 14),
                _FriendsInRoomRow(friends: friendsHere),
              ],

              // ── Tags ──────────────────────────────────────────────────────
              if (room.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: room.tags.take(6).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignColors.divider),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: DesignColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // ── Join button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    // Phase 5 analytics: discovery_room_join_tapped
                    core_analytics.AnalyticsService.instance.logEvent(
                      name: 'discovery_room_join_tapped',
                      parameters: {'room_id': room.id, 'room_title': room.title},
                    );
                    Navigator.pop(context);
                    onJoin();
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: room.isLocked
                            ? [
                                DesignColors.tertiary.withValues(alpha: 0.7),
                                DesignColors.accent.withValues(alpha: 0.7),
                              ]
                            : [
                                const Color(0xFFFF4D8B),
                                DesignColors.tertiary,
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D8B)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          room.isLocked
                              ? Icons.lock_outlined
                              : _typeIcon(room.roomType),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          room.isLocked ? 'Request to Join' : 'Join Room',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Friends row ───────────────────────────────────────────────────────────────

class _FriendsInRoomRow extends StatelessWidget {
  final List<FriendEntry> friends;
  const _FriendsInRoomRow({required this.friends});

  @override
  Widget build(BuildContext context) {
    final visible = friends.take(5).toList();
    final overflow = friends.length - visible.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DesignColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Stacked avatars
          SizedBox(
            width: visible.length * 22.0 + 6,
            height: 28,
            child: Stack(
              children: visible.asMap().entries.map((e) {
                final p = e.value;
                final letter =
                    (p.displayName ?? p.uid)[0].toUpperCase();
                return Positioned(
                  left: e.key * 22.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: DesignColors.background, width: 2),
                    ),
                    child: ClipOval(
                      child: p.avatarUrl != null &&
                              p.avatarUrl!.isNotEmpty
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overflow > 0
                      ? '${friends.length} friends are in this room'
                      : friends.length == 1
                          ? '${visible.first.displayName?.split(' ').first ?? 'A friend'} is in here'
                          : '${friends.length} friends are in here',
                  style: const TextStyle(
                    color: DesignColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (friends.length == 1 &&
                    visible.first.displayName != null)
                  Text(
                    visible.first.displayName!,
                    style: const TextStyle(
                      color: DesignColors.textGray,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial(String letter) => Container(
        color: DesignColors.accent.withValues(alpha: 0.2),
        alignment: Alignment.center,
        child: Text(letter,
            style: const TextStyle(
                color: DesignColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

// ── Badge helpers (mirrored from room_discovery_card.dart) ────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
            Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ],
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  final RoomType type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) {
    final c = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 11, color: c),
          const SizedBox(width: 3),
          Text(_typeLabel(type),
              style: TextStyle(
                  color: c, fontSize: 10, fontWeight: FontWeight.w700)),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_vi(vibe), size: 11, color: color),
            const SizedBox(width: 3),
            Text(vibe,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [DesignColors.gold, Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 10, color: Colors.white),
            SizedBox(width: 3),
            Text('VIP',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _HotBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                size: 11, color: Color(0xFFFF6B35)),
            SizedBox(width: 3),
            Text('Trending',
                style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
