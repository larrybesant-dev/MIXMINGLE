import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/room_providers.dart';
import '../../../shared/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../core/theme/neon_colors.dart';
import '../../room/screens/voice_room_page.dart';

/// ============================================================================
/// MIX & MINGLE HOME SCREEN - Electric Lounge Design
/// Neon-club aesthetic with featured logo and live rooms
/// ============================================================================

class HomePageElectric extends ConsumerStatefulWidget {
  const HomePageElectric({super.key});

  @override
  ConsumerState<HomePageElectric> createState() => _HomePageElectricState();
}

class _HomePageElectricState extends ConsumerState<HomePageElectric>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _logoGlowController;
  late Animation<double> _logoGlowAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _logoGlowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _logoGlowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logoGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header with logo
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 280,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          NeonColors.darkBg2.withValues(alpha: 0.8),
                          NeonColors.darkBg.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with glow animation
                        AnimatedBuilder(
                          animation: _logoGlowAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoGlowAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: NeonColors.neonOrange
                                          .withValues(
                                            alpha: 0.6 *
                                                _logoGlowAnimation.value,
                                          ),
                                      blurRadius:
                                          32 * _logoGlowAnimation.value,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: NeonColors.neonBlue.withValues(
                                        alpha: 0.4 *
                                            _logoGlowAnimation.value,
                                      ),
                                      blurRadius:
                                          20 * _logoGlowAnimation.value,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          NeonColors.neonOrange
                                              .withValues(alpha: 0.1),
                                          NeonColors.neonBlue
                                              .withValues(alpha: 0.1),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: NeonColors.neonOrange
                                            .withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                NeonColors.neonOrange,
                                                NeonColors.neonPurple,
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.music_note,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Brand name with neon effect
                        NeonText(
                          'MIX & MINGLE',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          textColor: Colors.white,
                          glowColor: NeonColors.neonOrange,
                          glowRadius: 12,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Global DJ Vibes',
                          style: TextStyle(
                            fontSize: 14,
                            color: NeonColors.textSecondary,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab navigation
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: NeonColors.neonOrange,
                    indicatorWeight: 3,
                    labelColor: NeonColors.neonOrange,
                    unselectedLabelColor: NeonColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    tabs: const [
                      Tab(text: 'LIVE ROOMS'),
                      Tab(text: 'FEATURED'),
                      Tab(text: 'TRENDING'),
                    ],
                  ),
                ),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Live Rooms Tab
                    _buildLiveRoomsTab(roomsAsync),

                    // Featured Tab
                    _buildFeaturedTab(),

                    // Trending Tab
                    _buildTrendingTab(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // TEMP DISABLED: Floating action buttons (malformed layout blocking hit-testing)
        // TODO: Replace with bottom navigation or single FAB
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        // floatingActionButton: [Multiple FABs not supported],
      ),
    );
  }

  Widget _buildLiveRoomsTab(AsyncValue<List> roomsAsync) {
    return roomsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: NeonColors.neonOrange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load rooms',
              style: TextStyle(
                color: NeonColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.music_note,
                  size: 48,
                  color: NeonColors.neonBlue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No active rooms right now',
                  style: TextStyle(
                    color: NeonColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/go-live'),
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Start a Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonColors.neonOrange,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NeonGlowCard(
                glowColor: NeonColors.neonBlue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          VoiceRoomPage(room: room),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NeonText(
                                room.name ?? 'Untitled Room',
                                fontSize: 18,
                                glowColor: NeonColors.neonOrange,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${room.hostName ?? 'Unknown'}',
                                style: const TextStyle(
                                  color: NeonColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        NeonBadge(
                          label: '${room.listeners ?? 0} live',
                          backgroundColor: NeonColors.neonOrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NeonDivider(
                      startColor:
                          NeonColors.neonOrange.withValues(alpha: 0.3),
                      endColor: NeonColors.neonBlue.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NeonGlowCard(
          glowColor: NeonColors.neonOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeonText(
                'Featured Event',
                fontSize: 18,
                glowColor: NeonColors.neonOrange,
              ),
              const SizedBox(height: 12),
              Text(
                'Join our exclusive live event with top DJs around the globe',
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/events'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonColors.neonOrange,
                  ),
                  child: const Text('View All Events'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NeonGlowCard(
          glowColor: NeonColors.neonPurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeonText(
                'Trending Now',
                fontSize: 18,
                glowColor: NeonColors.neonBlue,
              ),
              const SizedBox(height: 12),
              const Text(
                'Check out the hottest rooms and connections happening right now',
                style: TextStyle(
                  color: NeonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/browse-rooms'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonColors.neonBlue,
                  ),
                  child: const Text('Explore Trending'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom delegate for pinned tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: NeonColors.darkBg2,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
