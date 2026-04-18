import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mixvy/core/layout/app_layout.dart';
import 'package:mixvy/core/theme.dart';
import 'package:mixvy/features/feed/providers/feed_providers.dart';
import 'package:mixvy/features/social/widgets/social_room_card.dart';
import 'package:mixvy/models/room_model.dart';
import 'package:mixvy/shared/widgets/app_page_scaffold.dart';

// ── Sort options ──────────────────────────────────────────────────────────────
enum _FloorSort { mostSpeakers, mostListeners, newestLive }

extension on _FloorSort {
  String get label {
    switch (this) {
      case _FloorSort.mostSpeakers:  return 'Most Active';
      case _FloorSort.mostListeners: return 'Most Listeners';
      case _FloorSort.newestLive:    return 'Newest Live';
    }
  }

  IconData get icon {
    switch (this) {
      case _FloorSort.mostSpeakers:  return Icons.mic_rounded;
      case _FloorSort.mostListeners: return Icons.people_alt_rounded;
      case _FloorSort.newestLive:    return Icons.new_releases_rounded;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class LiveFloorScreen extends ConsumerStatefulWidget {
  const LiveFloorScreen({super.key});

  @override
  ConsumerState<LiveFloorScreen> createState() => _LiveFloorScreenState();
}

class _LiveFloorScreenState extends ConsumerState<LiveFloorScreen> {
  _FloorSort _sort = _FloorSort.mostSpeakers;

  List<RoomModel> _sorted(List<RoomModel> rooms) {
    final list = List<RoomModel>.from(rooms);
    switch (_sort) {
      case _FloorSort.mostSpeakers:
        list.sort((a, b) => b.stageUserIds.length.compareTo(a.stageUserIds.length));
      case _FloorSort.mostListeners:
        list.sort((a, b) {
          final aMem = a.memberCount > 0 ? a.memberCount : a.stageUserIds.length + a.audienceUserIds.length;
          final bMem = b.memberCount > 0 ? b.memberCount : b.stageUserIds.length + b.audienceUserIds.length;
          return bMem.compareTo(aMem);
        });
      case _FloorSort.newestLive:
        list.sort((a, b) {
          final aTime = a.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    final hp = context.pageHorizontalPadding;

    return AppPageScaffold(
      backgroundColor: VelvetNoir.surface,
      safeArea: false,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: VelvetNoir.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: VelvetNoir.liveGlow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VelvetNoir.liveGlow.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'The Floor',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: VelvetNoir.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: VelvetNoir.primary),
                tooltip: 'Start a Room',
                onPressed: () => context.go('/create-room'),
              ),
            ],
          ),

          // Sort chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hp, 4, hp, 8),
              child: Row(
                children: _FloorSort.values.map((s) {
                  final selected = _sort == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _sort = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    VelvetNoir.primary,
                                    VelvetNoir.primaryDim,
                                  ],
                                )
                              : null,
                          color: selected ? null : VelvetNoir.surfaceHigh,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : VelvetNoir.outlineVariant
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon,
                                size: 13,
                                color: selected
                                    ? VelvetNoir.surface
                                    : VelvetNoir.onSurfaceVariant),
                            const SizedBox(width: 5),
                            Text(
                              s.label,
                              style: GoogleFonts.raleway(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: selected
                                    ? VelvetNoir.surface
                                    : VelvetNoir.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Room list
          roomsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: _FloorLoadingShimmer(),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(hp),
                child: Center(
                  child: Text(
                    'Could not load live rooms.',
                    style: GoogleFonts.raleway(color: VelvetNoir.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            data: (rooms) {
              final sorted = _sorted(rooms);
              if (sorted.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(hp),
                    child: _EmptyFloor(
                      onCreateRoom: () => context.go('/create-room'),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final room = sorted[i];
                    return _FloorRoomTile(
                      room: room,
                      rank: i + 1,
                      onTap: () => context.go('/room/${room.id}'),
                    );
                  },
                  childCount: sorted.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Room tile with rank + hot badge ──────────────────────────────────────────
class _FloorRoomTile extends StatelessWidget {
  const _FloorRoomTile({
    required this.room,
    required this.rank,
    required this.onTap,
  });

  final RoomModel room;
  final int rank;
  final VoidCallback onTap;

  bool get _isHot {
    final total = room.memberCount > 0
        ? room.memberCount
        : room.stageUserIds.length + room.audienceUserIds.length;
    return total >= 20 || room.stageUserIds.length >= 4;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SocialRoomCard(room: room, onTap: onTap),
        if (_isHot)
          Positioned(
            top: 12,
            right: 22,
            child: _HotBadge(),
          ),
        if (rank <= 3)
          Positioned(
            left: 24,
            bottom: 12,
            child: _RankBadge(rank: rank),
          ),
      ],
    );
  }
}

class _HotBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFE03450)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE03450).withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '🔥 HOT',
        style: GoogleFonts.raleway(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFFD4AF37), const Color(0xFF9A7B1A)], // gold
      [const Color(0xFFC0C0C0), const Color(0xFF888888)], // silver
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)], // bronze
    ];
    final c = colors[rank - 1];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: c),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$rank',
        style: GoogleFonts.raleway(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Empty / loading states ────────────────────────────────────────────────────
class _EmptyFloor extends StatelessWidget {
  const _EmptyFloor({required this.onCreateRoom});
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Text('🎙️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No live rooms right now',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: VelvetNoir.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to open the floor.',
              style: GoogleFonts.raleway(
                  fontSize: 14, color: VelvetNoir.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCreateRoom,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [VelvetNoir.primary, VelvetNoir.primaryDim],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Start a Room',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: VelvetNoir.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorLoadingShimmer extends StatelessWidget {
  const _FloorLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 86,
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
