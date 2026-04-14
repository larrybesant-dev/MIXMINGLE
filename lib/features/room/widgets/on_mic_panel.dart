import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/participant_providers.dart';
import 'room_user_tile.dart';

/// Panel shown above the chat that displays everyone currently on the mic
/// (roles: host, cohost, stage). Shows a small placeholder when empty.
///
/// Renders a [RoomUserTile] per participant in a horizontally-scrollable row,
/// with the host appearing first and larger, followed by co-hosts and stage
/// speakers. Each tile shows the role badge, mic state, and (for stage users)
/// a live countdown badge when a mic-time limit is active.
class OnMicPanel extends ConsumerWidget {
  const OnMicPanel({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.displayNameById,
  });

  final String roomId;
  final String currentUserId;

  /// Display-name lookup keyed by userId (same map used by UserListPanel).
  final Map<String, String> displayNameById;

  static const _kSurface = Color(0xFF0B0B0B);
  static const _kSurfaceHigh = Color(0xFF1C1617);
  static const _kGold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onMicAsync = ref.watch(onMicParticipantsProvider(roomId));

    return onMicAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (participants) {
        // Sort: host first, then cohost, then stage.
        final sorted = [...participants]
          ..sort((a, b) => _roleOrder(a.role).compareTo(_roleOrder(b.role)));

        return Container(
          decoration: const BoxDecoration(
            color: _kSurface,
            border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Container(
                height: 28,
                color: _kSurfaceHigh,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const _PulsingMicIcon(),
                    const SizedBox(width: 6),
                    Text(
                      'On Mic  •  ${sorted.length}',
                      style: const TextStyle(
                        color: _kGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Text(
                    'Nobody on mic yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final p = sorted[index];
                      final name = displayNameById[p.userId] ?? p.userId;
                      final isMe = p.userId == currentUserId;
                      return RoomUserTile(
                        displayName: name,
                        role: p.role,
                        isMicOn: p.micOn,
                        isMuted: p.isMuted,
                        isMe: isMe,
                        micExpiresAt: p.micExpiresAt,
                        layout: RoomUserTileLayout.grid,
                        compact: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static int _roleOrder(String role) {
    switch (role) {
      case 'host':
      case 'owner':
        return 0;
      case 'cohost':
        return 1;
      default:
        return 2;
    }
  }
}

/// Pulsing mic icon to draw attention to the "On Mic" header.
class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Icon(Icons.mic, color: Color(0xFFC45E7A), size: 14),
    );
  }
}
