import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mixvy/core/layout/app_layout.dart';
import 'package:mixvy/core/theme.dart';
import 'package:mixvy/features/feed/providers/feed_providers.dart';
import 'package:mixvy/features/social/providers/social_providers.dart';
import 'package:mixvy/features/social/widgets/social_room_card.dart';
import 'package:mixvy/models/room_model.dart';
import 'package:mixvy/shared/widgets/app_page_scaffold.dart';

class HomeLobbyScreen extends ConsumerWidget {
  const HomeLobbyScreen({super.key});

  int _activityScore(RoomModel room) {
    final total = room.memberCount > 0
        ? room.memberCount
        : room.stageUserIds.length + room.audienceUserIds.length;
    final speakers = room.stageUserIds.length;
    final created = room.createdAt?.toDate() ?? DateTime.now();
    final minutesAgo = DateTime.now().difference(created).inMinutes;
    final recencyBoost = (120 - minutesAgo).clamp(0, 120) ~/ 10;
    return total + (speakers * 3) + recencyBoost;
  }

  List<RoomModel> _trending(List<RoomModel> rooms) {
    final sorted = List<RoomModel>.from(rooms)
      ..sort((a, b) => _activityScore(b).compareTo(_activityScore(a)));
    return sorted;
  }

  List<RoomModel> _newest(List<RoomModel> rooms) {
    final sorted = List<RoomModel>.from(rooms)
      ..sort((a, b) {
        final ta = a.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hp = context.pageHorizontalPadding;

    final roomsAsync = ref.watch(roomsStreamProvider);
    final followingLiveAsync = ref.watch(followingLiveRoomsProvider(uid));
    final forYouAsync = ref.watch(forYouRoomsProvider(uid));

    return AppPageScaffold(
      backgroundColor: VelvetNoir.surface,
      safeArea: false,
      body: RefreshIndicator(
        color: VelvetNoir.primary,
        onRefresh: () async {
          ref.invalidate(roomsStreamProvider);
          ref.invalidate(followingLiveRoomsProvider(uid));
          ref.invalidate(forYouRoomsProvider(uid));
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              pinned: true,
              backgroundColor: VelvetNoir.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: VelvetNoir.onSurface,
                    ),
                  ),
                  Text(
                    'Live voices, fresh rooms, your circle',
                    style: GoogleFonts.raleway(
                      fontSize: 11,
                      color: VelvetNoir.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: VelvetNoir.onSurfaceVariant),
                  onPressed: () => context.go('/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: VelvetNoir.onSurfaceVariant),
                  onPressed: () => context.go('/notifications'),
                ),
              ],
            ),

            // Main sections composed from shared room stream
            roomsAsync.when(
              loading: () => const SliverToBoxAdapter(child: _HomeShimmer()),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(hp),
                  child: Center(
                    child: Text(
                      'Unable to load the social feed right now.',
                      style: GoogleFonts.raleway(
                        color: VelvetNoir.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              data: (rooms) {
                final liveNow = rooms.take(10).toList();
                final trending = _trending(rooms).take(6).toList();
                final newest = _newest(rooms).take(6).toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // A. Live Now
                    _SectionHeader(
                      padding: EdgeInsets.fromLTRB(hp, 14, hp, 10),
                      title: 'Live Now',
                      subtitle: 'Jump into the room that fits your mood',
                    ),
                    if (liveNow.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: const _EmptyRoomsCard(
                          title: 'No rooms are live yet',
                          subtitle: 'Check back soon or start one yourself.',
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: hp),
                          scrollDirection: Axis.horizontal,
                          itemCount: liveNow.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) => SocialRoomCardCompact(
                            key: ValueKey(liveNow[i].id),
                            room: liveNow[i],
                            onTap: () => ctx.go('/room/${liveNow[i].id}'),
                          ),
                        ),
                      ),

                    // B. Following Live
                    _SectionHeader(
                      padding: EdgeInsets.fromLTRB(hp, 22, hp, 10),
                      title: 'Following Live',
                      subtitle: 'People you already care about',
                    ),
                    followingLiveAsync.when(
                      loading: () => const _MiniLoadingStrip(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (followRooms) {
                        if (followRooms.isEmpty) {
                          final suggestions = rooms.take(3).toList();
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: hp),
                            child: Column(
                              children: [
                                const _EmptyRoomsCard(
                                  title: 'Nobody you follow is live yet',
                                  subtitle: 'Here are a few rooms worth checking out.',
                                ),
                                const SizedBox(height: 10),
                                ...suggestions.map(
                                  (room) => SocialRoomCard(
                                    key: ValueKey(room.id),
                                    room: room,
                                    onTap: () => context.go('/room/${room.id}'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: followRooms.map(
                            (room) => SocialRoomCard(
                              key: ValueKey(room.id),
                              room: room,
                              onTap: () => context.go('/room/${room.id}'),
                            ),
                          ).toList(),
                        );
                      },
                    ),

                    // C. Trending Rooms
                    _SectionHeader(
                      padding: EdgeInsets.fromLTRB(hp, 22, hp, 10),
                      title: 'Trending Rooms',
                      subtitle: 'Ranked by activity, speakers, and recency',
                    ),
                    ...trending.map(
                      (room) => _RankedRoomCard(
                        room: room,
                        score: _activityScore(room),
                        onTap: () => context.go('/room/${room.id}'),
                      ),
                    ),

                    // D. New Rooms
                    _SectionHeader(
                      padding: EdgeInsets.fromLTRB(hp, 22, hp, 10),
                      title: 'New Rooms',
                      subtitle: 'Fresh spaces that just opened',
                    ),
                    ...newest.map(
                      (room) => SocialRoomCard(
                        key: ValueKey('${room.id}-new'),
                        room: room,
                        onTap: () => context.go('/room/${room.id}'),
                      ),
                    ),

                    // E. For You
                    _SectionHeader(
                      padding: EdgeInsets.fromLTRB(hp, 22, hp, 10),
                      title: 'For You',
                      subtitle: 'Picked from your interests and social activity',
                    ),
                    forYouAsync.when(
                      loading: () => const _MiniLoadingStrip(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (suggestions) {
                        if (suggestions.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: hp),
                            child: const _EmptyRoomsCard(
                              title: 'Your recommendations are warming up',
                              subtitle: 'Join a few rooms and follow hosts to personalize this feed.',
                            ),
                          );
                        }
                        return Column(
                          children: suggestions.take(5).map(
                            (room) => SocialRoomCard(
                              key: ValueKey('${room.id}-foryou'),
                              room: room,
                              onTap: () => context.go('/room/${room.id}'),
                            ),
                          ).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.padding,
    required this.title,
    required this.subtitle,
  });

  final EdgeInsets padding;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VelvetNoir.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.raleway(
              fontSize: 12,
              color: VelvetNoir.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedRoomCard extends StatelessWidget {
  const _RankedRoomCard({
    required this.room,
    required this.score,
    required this.onTap,
  });

  final RoomModel room;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SocialRoomCard(room: room, onTap: onTap),
        Positioned(
          top: 12,
          right: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: VelvetNoir.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: VelvetNoir.secondaryBright.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'Score $score',
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: VelvetNoir.secondaryBright,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRoomsCard extends StatelessWidget {
  const _EmptyRoomsCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VelvetNoir.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: VelvetNoir.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 12,
              color: VelvetNoir.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLoadingStrip extends StatelessWidget {
  const _MiniLoadingStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
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

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(
              3,
              (i) => Container(
                width: 160,
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: VelvetNoir.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const MiniLoadingStripWrapper(),
      ],
    );
  }
}

class MiniLoadingStripWrapper extends StatelessWidget {
  const MiniLoadingStripWrapper({super.key});

  @override
  Widget build(BuildContext context) => const _MiniLoadingStrip();
}
