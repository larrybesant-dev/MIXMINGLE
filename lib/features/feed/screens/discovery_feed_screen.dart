import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/feed_controller.dart';
import '../models/post_model.dart';
import '../providers/following_feed_provider.dart';
import '../widgets/post_card.dart';
import 'package:go_router/go_router.dart';
import '../widgets/trending_user_card.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/feed_loading_shimmer.dart';
import '../../stories/widgets/stories_row.dart';
import '../../ads/ad_manager.dart';
import '../../../features/profile/profile_controller.dart';

// ── Neon Pulse colour aliases ─────────────────────────────────────────────────
const _npSurface        = Color(0xFF0D0A0C);
const _npSurfaceHigh    = Color(0xFF241820);
const _npSurfaceHighest = Color(0xFF2A1C23);
const _npPrimary        = Color(0xFFD4A853);
const _npPrimaryDim     = Color(0xFF8C6020);
const _npSecondary      = Color(0xFFC45E7A);
const _npError          = Color(0xFFFF6E84);
const _npOnSurface      = Color(0xFFF2EBE0);
const _npOnVariant      = Color(0xFFB09080);
const _npGhost          = Color(0x1A73757D);

class DiscoveryFeedScreen extends ConsumerWidget {
  const DiscoveryFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _npSurface,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: _npSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: _MixVyLogo(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: _npOnVariant),
                  onPressed: () => context.go('/search'),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _npGhost),
                    ),
                  ),
                  child: TabBar(
                    labelColor: _npPrimary,
                    unselectedLabelColor: _npOnVariant,
                    indicatorColor: _npPrimary,
                    indicatorWeight: 2,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Discover'),
                      Tab(text: 'Following'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              DiscoveryFeedContent(),
              _FollowingFeedTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo wordmark ─────────────────────────────────────────────────────────────
class _MixVyLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('MIX', style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: _npOnSurface, fontStyle: FontStyle.italic, letterSpacing: -1)),
        Text('Vy', style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: _npPrimary, fontStyle: FontStyle.italic, letterSpacing: -1)),
      ],
    );
  }
}

// ── Discovery feed content ────────────────────────────────────────────────────
class DiscoveryFeedContent extends ConsumerStatefulWidget {
  const DiscoveryFeedContent({super.key});

  @override
  ConsumerState<DiscoveryFeedContent> createState() =>
      _DiscoveryFeedContentState();
}

class _DiscoveryFeedContentState extends ConsumerState<DiscoveryFeedContent> {
  static const List<({String label, String? value})> _categories = [
    (label: 'All Rooms', value: null),
    (label: '🎵 Music', value: 'music'),
    (label: '🎮 Gaming', value: 'gaming'),
    (label: '❤️ Dating', value: 'dating'),
    (label: '💬 Chill', value: 'talk'),
    (label: '💻 Tech', value: 'tech'),
    (label: '🎨 Art', value: 'art'),
    (label: '💃 Dance', value: 'dance'),
  ];

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);

    if (feedState.isLoading) {
      return const FeedLoadingShimmer();
    }

    if (!feedState.isLoading &&
        feedState.error == null &&
        feedState.liveRooms.isEmpty &&
        feedState.trendingUsers.isEmpty) {
      Future.microtask(
          () => ref.read(feedControllerProvider.notifier).loadFeed());
    }

    if (feedState.error != null) {
      return _buildErrorState(feedState.error!);
    }

    final filteredRooms = _selectedCategory == null
        ? feedState.liveRooms
        : feedState.liveRooms
            .where(
                (r) => r.category?.toLowerCase() == _selectedCategory)
            .toList();

    return RefreshIndicator(
      color: _npPrimary,
      backgroundColor: _npSurfaceHigh,
      onRefresh: () => ref.read(feedControllerProvider.notifier).loadFeed(),
      child: CustomScrollView(
        slivers: [
          // Stories row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: const StoriesRow(),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: _buildCategoryChips(),
          ),

          if (filteredRooms.isNotEmpty) ...[
            // "Trending Now" header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_npPrimary, _npPrimaryDim],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Trending Now',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: _npOnSurface)),
                  ],
                ),
              ),
            ),
            // Bento trending grid (hero + stacked)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBentoGrid(filteredRooms),
              ),
            ),

            // "Explore Live Rooms" header
            if (filteredRooms.length > 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3, height: 18,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_npSecondary, _npPrimary],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Explore Live Rooms',
                              style: GoogleFonts.inter(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: _npOnSurface)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _npSurfaceHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _npGhost),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: _npError)),
                            const SizedBox(width: 4),
                            Text('LIVE', style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: _npError, letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Grid of room cards
            if (filteredRooms.length > 3)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final room = filteredRooms[i + 3];
                      return _RoomGridCard(
                        room: room,
                        onTap: () => context.go('/room/${room.id}'),
                      );
                    },
                    childCount: filteredRooms.length > 3
                        ? filteredRooms.length - 3
                        : 0,
                  ),
                ),
              ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const FeedEmptyState(
                        message: 'No live rooms in this category right now.'),
                    const SizedBox(height: 12),
                    _gradientButton(
                      label: 'Try Speed Dating',
                      onTap: () => context.go('/speed-dating'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Promo banner (free tier only)
          SliverToBoxAdapter(
            child: Builder(builder: (ctx) {
              final profileMembership = ref.watch(
                  profileControllerProvider.select(
                      (s) => s.membershipLevel ?? 'Free'));
              if (!AdManager.shouldShowAds(profileMembership)) {
                return const SizedBox.shrink();
              }
              return _buildPromoBanner(ctx);
            }),
          ),

          // Trending users
          if (feedState.trendingUsers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_npPrimary, _npSecondary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Trending Creators',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: _npOnSurface)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: feedState.trendingUsers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final user = feedState.trendingUsers[index];
                    return TrendingUserCard(
                      user: user,
                      onTap: () => context.go('/profile/${user.id}'),
                    );
                  },
                ),
              ),
            ),
          ],

          // Upcoming rooms
          if (feedState.upcomingRooms.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 18,
                      decoration: BoxDecoration(
                        color: _npSurfaceHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Upcoming Rooms',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: _npOnSurface)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final room = feedState.upcomingRooms[i];
                  final scheduledAt = room.scheduledAt?.toDate();
                  return _UpcomingRoomTile(room: room, scheduledAt: scheduledAt);
                },
                childCount: feedState.upcomingRooms.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [_npPrimary, _npPrimaryDim],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : _npSurfaceHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? Colors.transparent : _npGhost,
                ),
              ),
              child: Text(
                cat.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _npSurface : _npOnVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBentoGrid(List rooms) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    final hero = rooms[0];
    final secondary = rooms.length > 1 ? rooms.sublist(1, rooms.length.clamp(1, 3)) : [];
    final context = this.context;

    return SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card (2/3 width)
          Expanded(
            flex: 2,
            child: _BentoHeroCard(
              room: hero,
              onTap: () => context.go('/room/${hero.id}'),
            ),
          ),
          const SizedBox(width: 8),
          // Secondary cards (1/3 width, stacked)
          Expanded(
            child: Column(
              children: [
                if (secondary.isNotEmpty)
                  Expanded(
                    child: _BentoSmallCard(
                      room: secondary[0],
                      onTap: () => context.go('/room/${secondary[0].id}'),
                    ),
                  ),
                if (secondary.length > 1) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: _BentoSmallCard(
                      room: secondary[1],
                      onTap: () => context.go('/room/${secondary[1].id}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: _npError),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: _npOnVariant, fontSize: 14)),
            const SizedBox(height: 20),
            _gradientButton(
              label: 'Retry',
              onTap: () => ref.read(feedControllerProvider.notifier).loadFeed(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _npSurfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _npGhost),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_npPrimary, _npPrimaryDim]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt_rounded, color: _npSurface, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Premium',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14, color: _npOnSurface)),
                  Text('Remove ads & unlock exclusive rooms.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _npOnVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ctx.go('/payments'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_npPrimary, _npPrimaryDim]),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Upgrade',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: _npSurface)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_npPrimary, _npPrimaryDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: _npPrimaryDim.withAlpha(60), blurRadius: 16)
          ],
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: _npSurface)),
      ),
    );
  }
}

// ── Bento hero card ───────────────────────────────────────────────────────────
class _BentoHeroCard extends StatelessWidget {
  const _BentoHeroCard({required this.room, required this.onTap});
  final dynamic room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient placeholder (replace with actual image if available)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1C1240),
                    const Color(0xFF0D0A0C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Gradient overlay
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xCC0D0A0C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // LIVE badge (top-left)
            Positioned(
              top: 12, left: 12,
              child: _LiveBadge(),
            ),
            // Viewer count (bottom-right corner)
            Positioned(
              bottom: 52, right: 12,
              child: _viewerPill(room.viewerCount ?? 0),
            ),
            // Room name + host (bottom)
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.name ?? 'Live Room',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _npOnSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(radius: 10, backgroundColor: _npPrimaryDim),
                      const SizedBox(width: 6),
                      Text(
                        room.hostName ?? 'Host',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _npOnVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bento small card ──────────────────────────────────────────────────────────
class _BentoSmallCard extends StatelessWidget {
  const _BentoSmallCard({required this.room, required this.onTap});
  final dynamic room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1B1216), const Color(0xFF0D0A0C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xCC0D0A0C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(top: 8, left: 8, child: _LiveBadge(small: true)),
            Positioned(
              bottom: 8, left: 8, right: 8,
              child: Text(
                room.name ?? 'Live Room',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: _npOnSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room grid card ────────────────────────────────────────────────────────────
class _RoomGridCard extends StatelessWidget {
  const _RoomGridCard({required this.room, required this.onTap});
  final dynamic room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1C1C2E), _npSurfaceHigh],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(top: 10, left: 10, child: _LiveBadge(small: true)),
            Positioned(
              bottom: 10, left: 10,
              child: _viewerPill(room.viewerCount ?? 0),
            ),
            Positioned(
              bottom: 36, left: 10, right: 10,
              child: Text(
                room.name ?? 'Live Room',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _npOnSurface),
              ),
            ),
            Positioned(
              bottom: 10, right: 10,
              child: CircleAvatar(
                  radius: 12, backgroundColor: _npPrimaryDim),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming room tile ────────────────────────────────────────────────────────
class _UpcomingRoomTile extends StatelessWidget {
  const _UpcomingRoomTile({required this.room, this.scheduledAt});
  final dynamic room;
  final DateTime? scheduledAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _npSurfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _npGhost),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _npPrimary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('📅', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name ?? 'Upcoming Room',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: _npOnSurface)),
                const SizedBox(height: 2),
                scheduledAt == null
                    ? Text('Scheduled',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _npOnVariant))
                    : _RoomCountdown(scheduledAt: scheduledAt!),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _npGhost),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Remind',
                style: GoogleFonts.inter(
                    fontSize: 12, color: _npOnVariant)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({this.small = false});
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: _npError.withAlpha(230),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
              color: _npError.withAlpha(80),
              blurRadius: small ? 6 : 10,
              spreadRadius: 1),
        ],
      ),
      child: Text(
        '● LIVE',
        style: GoogleFonts.inter(
            fontSize: small ? 9 : 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5),
      ),
    );
  }
}

Widget _viewerPill(int count) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x80161A21),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye_outlined,
                size: 12, color: _npOnVariant),
            const SizedBox(width: 4),
            Text(
              count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
              style: GoogleFonts.inter(fontSize: 11, color: _npOnSurface),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Following feed tab ────────────────────────────────────────────────────────
class _FollowingFeedTab extends ConsumerWidget {
  const _FollowingFeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
          child: Text('Sign in to see your following feed.',
              style: GoogleFonts.inter(color: _npOnVariant)));
    }

    final feedAsync = ref.watch(followingFeedProvider(uid));

    return feedAsync.when(
      loading: () => const FeedLoadingShimmer(),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: GoogleFonts.inter(color: _npError))),
      data: (maps) {
        if (maps.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const FeedEmptyState(
                  message: 'No posts yet from people you follow.'),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_npPrimary, _npPrimaryDim]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_search,
                            size: 16, color: _npSurface),
                        const SizedBox(width: 8),
                        Text('Find people to follow',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: _npSurface)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final posts = maps.map((m) {
          final id = m['id'] as String? ?? '';
          return PostModel.fromDoc(id, m);
        }).toList();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: posts.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: _npGhost),
          itemBuilder: (context, i) =>
              PostCard(post: posts[i], currentUserId: uid),
        );
      },
    );
  }
}

// ── Room countdown ────────────────────────────────────────────────────────────
class _RoomCountdown extends StatefulWidget {
  const _RoomCountdown({required this.scheduledAt});
  final DateTime scheduledAt;

  @override
  State<_RoomCountdown> createState() => _RoomCountdownState();
}

class _RoomCountdownState extends State<_RoomCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.scheduledAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = widget.scheduledAt.difference(DateTime.now());
      setState(() => _remaining = remaining);
      if (remaining.isNegative) _timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return Text(
        'Going live now!',
        style: GoogleFonts.inter(color: _npSecondary, fontWeight: FontWeight.w600),
      );
    }
    final String label;
    if (_remaining.inSeconds < 600) {
      final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      label = 'Going live in ${m}m ${s}s';
    } else if (_remaining.inHours < 24) {
      label = 'In ${_remaining.inHours}h ${_remaining.inMinutes.remainder(60)}m';
    } else {
      label = 'In ${_remaining.inDays}d';
    }
    return Text(label,
        style: GoogleFonts.inter(fontSize: 12, color: _npOnVariant));
  }
}

