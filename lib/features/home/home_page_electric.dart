/// Home Page Electric
/// Main landing page after onboarding completion
/// Shows: Live Rooms, Speed Dating, Discovery, Chats
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_constants.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/room.dart';
import '../../shared/widgets/club_background.dart';
import '../../shared/providers/all_providers.dart';
import '../../core/intelligence/vibe_intelligence_service.dart';
import '../events/screens/events_page.dart';
import '../onboarding/widgets/onboarding_welcome_overlay.dart';
import '../discover/room_discovery_page_complete.dart';
import '../discovery/discovery_page.dart';
import '../chat/screens/chat_list_page.dart';
import '../profile/screens/profile_page.dart';
import '../room/providers/room_providers.dart';
import '../../shared/providers/room_discovery_providers.dart';
import '../../shared/widgets/room_discovery_card.dart';
import '../rooms/pages/trending_rooms_page.dart';
import '../rooms/pages/recommended_rooms_page.dart';
import '../rooms/pages/new_rooms_page.dart';

/// Home Page with Electric theme - main post-onboarding landing
class HomePageElectric extends ConsumerStatefulWidget {
  const HomePageElectric({super.key});

  @override
  ConsumerState<HomePageElectric> createState() => _HomePageElectricState();
}

class _HomePageElectricState extends ConsumerState<HomePageElectric> {
  int _selectedIndex = 0;
  bool _dismissedSuggestion = false;
  bool _overlayTriggered = false;

  // Vibe palette — same keys as rooms list page for consistency
  static const _kVibeColors = <String, Color>{
    'Chill':      Color(0xFF4A90FF),
    'Hype':       Color(0xFFFF4D8B),
    'Deep Talk':  Color(0xFF8B5CF6),
    'Late Night': Color(0xFF6366F1),
    'Study':      Color(0xFF00E5CC),
    'Party':      Color(0xFFFFAB00),
  };
  static const _kVibeIcons = <String, IconData>{
    'Chill':      Icons.waves_outlined,
    'Hype':       Icons.bolt,
    'Deep Talk':  Icons.forum_outlined,
    'Late Night': Icons.nightlight_outlined,
    'Study':      Icons.menu_book_outlined,
    'Party':      Icons.celebration_outlined,
  };
  Color _vc(String? v) => _kVibeColors[v] ?? DesignColors.accent;
  IconData _vi(String? v) => _kVibeIcons[v] ?? Icons.graphic_eq;

  @override
  Widget build(BuildContext context) {
    // Show the welcome overlay exactly once for every new account that has
    // not yet completed onboarding (onboardingComplete == false in Firestore).
    ref.listen<AsyncValue<UserProfile?>>(currentUserProfileProvider, (_, next) {
      next.whenData((profile) {
        if (!_overlayTriggered &&
            profile != null &&
            !profile.onboardingComplete) {
          _overlayTriggered = true;
          // Post-frame so the widget tree is settled before adding the overlay.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(welcomeOverlayVisibleProvider.notifier).show();
            }
          });
        }
      });
    });

    final showOverlay = ref.watch(welcomeOverlayVisibleProvider);
    final profile = ref.watch(currentUserProfileProvider).asData?.value;

    return Stack(
      children: [
        ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(profile),
        body: _buildBody(),
        bottomNavigationBar: _buildNeonNavBar(),
      ),
    ),
    if (showOverlay) const OnboardingWelcomeOverlay(),
  ],
);
  }

  // ══════════════════════════════════════════════════════════
  //  NEON APP BAR
  // ══════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(UserProfile? profile) {
    return AppBar(
      backgroundColor: DesignColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(children: [
        // Logo dot pulse
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignColors.accent,
            boxShadow: [
              BoxShadow(color: DesignColors.accent.withValues(alpha: 0.7), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'MIXVY',
          style: TextStyle(
            color: DesignColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            shadows: DesignColors.primaryGlow,
          ),
        ),
        if (profile?.vibeTag != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _vc(profile!.vibeTag).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _vc(profile.vibeTag).withValues(alpha: 0.45)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_vi(profile.vibeTag), size: 10, color: _vc(profile.vibeTag)),
              const SizedBox(width: 4),
              Text(profile.vibeTag!,
                  style: TextStyle(color: _vc(profile.vibeTag),
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: DesignColors.textGray),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: profile?.photoUrl != null
                ? CircleAvatar(radius: 16,
                    backgroundImage: NetworkImage(profile!.photoUrl!))
                : CircleAvatar(radius: 16,
                    backgroundColor: DesignColors.accent.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 16, color: DesignColors.accent)),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  NEON BOTTOM NAV BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildNeonNavBar() {
    const items = [
      _NavItem(Icons.home_outlined, Icons.home, 'Home'),
      _NavItem(Icons.bolt_outlined, Icons.bolt, 'Speed'),
      _NavItem(Icons.video_call_outlined, Icons.video_call, 'Rooms'),
      _NavItem(Icons.event_outlined, Icons.event, 'Events'),
      _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats'),
      _NavItem(Icons.explore_outlined, Icons.explore, 'Discover'),
      _NavItem(Icons.person_outline, Icons.person, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: DesignColors.background,
        border: Border(top: BorderSide(color: DesignColors.accent.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(color: DesignColors.accent.withValues(alpha: 0.06), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = _selectedIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 48,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? DesignColors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selected
                            ? [BoxShadow(color: DesignColors.accent.withValues(alpha: 0.3),
                                blurRadius: 8)]
                            : null,
                      ),
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 22,
                        color: selected ? DesignColors.accent : DesignColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(item.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? DesignColors.accent : DesignColors.textGray,
                        )),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSpeedDatingTab();
      case 2:
        return _buildRoomsTab();
      case 3:
        return _buildEventsTab();
      case 4:
        return _buildChatsTab();
      case 5:
        return _buildDiscoveryTab();
      case 6:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  /// Home Tab — personalized vibe greeting + heating-up rooms
  Widget _buildHomeTab() {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final p = profileAsync.asData?.value;
    final roomsAsync = ref.watch(liveRoomsProvider);
    // #2 Composite heating-up score: joinVelocity x2 + viewerCount
    final liveRooms = ([...(roomsAsync.value ?? [])])
      ..sort((a, b) {
        final aScore = (a.joinVelocity * 2) + a.viewerCount;
        final bScore = (b.joinVelocity * 2) + b.viewerCount;
        return bScore.compareTo(aScore);
      });
    final heatingUp = List<Room>.from(liveRooms.take(6));

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : hour < 21
                ? 'Good evening'
                : 'Late night vibes';
    final name = p?.displayName?.split(' ').first ?? 'there';
    // #3 — smart vibe greeting: prefer topVibe (behaviour-driven) over static vibeTag
    final vibe = p?.topVibe ?? p?.vibeTag;
    final vibeLabel = (p != null && p.topVibe != null && p.topVibeCount > 1)
        ? '${p.topVibe} vibes — x${p.topVibeCount} rooms'
        : vibe != null ? '$vibe vibes today' : null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$greeting,',
                  style: TextStyle(
                      color: DesignColors.white.withValues(alpha: 0.6),
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text(name,
                  style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: DesignColors.primaryGlow)),
              if (vibe != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _vc(vibe).withValues(alpha: 0.2),
                      _vc(vibe).withValues(alpha: 0.05),
                    ]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _vc(vibe).withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_vi(vibe), size: 12, color: _vc(vibe)),
                    const SizedBox(width: 5),
                    Text(vibeLabel ?? '$vibe vibes today',
                        style: TextStyle(
                            color: _vc(vibe),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(children: [
              Expanded(child: _ctaCard(
                icon: Icons.add_circle_outline,
                label: 'Start a Room',
                sublabel: 'Go live now',
                color: const Color(0xFFFF4D8B),
                onTap: () => Navigator.pushNamed(context, '/create-room'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _ctaCard(
                icon: Icons.bolt,
                label: 'Speed Dating',
                sublabel: '5-min video dates',
                color: DesignColors.gold,
                onTap: () => setState(() => _selectedIndex = 1),
              )),
            ]),
          ),
        ),
        // #7 — Adaptive vibe suggestion banner
        if (!_dismissedSuggestion)
          SliverToBoxAdapter(child: _buildVibeSuggestionBanner(p)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔥 Heating Up',
                    style: TextStyle(
                        color: DesignColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  child: const Text('See All',
                      style: TextStyle(color: DesignColors.accent, fontSize: 13)),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildHeatingUpRail(heatingUp)),
        // ── Phase 10: Discovery Rails ──────────────────────────
        _buildRailHeader(
          '🔥 Trending Rooms',
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrendingRoomsPage()),
          ),
        ),
        SliverToBoxAdapter(child: _buildTrendingRail()),
        _buildRailHeader(
          '⭐ Recommended',
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecommendedRoomsPage()),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildRecommendedRail(p?.id ?? ''),
        ),
        _buildRailHeader(
          '✨ New Rooms',
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewRoomsPage()),
          ),
        ),
        SliverToBoxAdapter(child: _buildNewRoomsRail()),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildRailHeader(String title, {required VoidCallback onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 8, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: DesignColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See All',
                  style:
                      TextStyle(color: DesignColors.accent, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingRail() {
    final roomsAsync = ref.watch(trendingRoomsProvider);
    return _buildDiscoveryRail(roomsAsync);
  }

  Widget _buildRecommendedRail(String userId) {
    final roomsAsync = ref.watch(recommendedRoomsProvider(userId));
    return _buildDiscoveryRail(roomsAsync);
  }

  Widget _buildNewRoomsRail() {
    final roomsAsync = ref.watch(newRoomsProvider);
    return _buildDiscoveryRail(roomsAsync);
  }

  Widget _buildDiscoveryRail(
      AsyncValue<List<Room>> roomsAsync) {
    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Nothing here yet',
                style: TextStyle(
                    color: DesignColors.textGray, fontSize: 13)),
          );
        }
        return SizedBox(
          height: 210,
          child: ListView.builder(
            padding:
                const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            itemBuilder: (_, i) => RoomDiscoveryCard(
              room: rooms[i],
              onTap: () => Navigator.pushNamed(
                context,
                '/room',
                arguments: rooms[i].id,
              ),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
            child:
                CircularProgressIndicator(color: DesignColors.accent)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // #7 — Vibe suggestion banner
  Widget _buildVibeSuggestionBanner(UserProfile? p) {
    if (p == null) return const SizedBox.shrink();
    final suggestion = ref
        .read(vibeIntelligenceServiceProvider)
        .getVibeSuggestion(p);
    if (suggestion == null) return const SizedBox.shrink();
    const nudgeColor = Color(0xFFFFAB00);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: nudgeColor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: nudgeColor.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: nudgeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(suggestion,
                style: const TextStyle(
                    color: nudgeColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () => setState(() => _dismissedSuggestion = true),
            child: const Icon(Icons.close, size: 16, color: nudgeColor),
          ),
        ]),
      ),
    );
  }

  Widget _ctaCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: const TextStyle(color: DesignColors.textGray, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildHeatingUpRail(List<Room> rooms) {
    if (rooms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DesignColors.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DesignColors.accent.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            const Icon(Icons.mic_none_outlined, size: 40, color: DesignColors.accent),
            const SizedBox(height: 10),
            const Text('No live rooms yet — be the first!',
                style: TextStyle(color: DesignColors.textGray, fontSize: 14)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/create-room'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4A90FF), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Start a Room',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (_, i) {
          final room = rooms[i];
          final color = _vc(room.vibeTag);
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/room', arguments: room.id),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.2), DesignColors.background],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ),
                  const Spacer(),
                  Text(room.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DesignColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.remove_red_eye_outlined, size: 11, color: color),
                    const SizedBox(width: 3),
                    Text('${room.viewerCount}',
                        style: TextStyle(
                            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    const Icon(Icons.videocam_outlined,
                        size: 11, color: DesignColors.textGray),
                    const SizedBox(width: 3),
                    Text('${room.camCount}',
                        style: const TextStyle(
                            color: DesignColors.textGray, fontSize: 11)),
                  ]),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

    Widget _buildSpeedDatingTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignColors.gold.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                      color: DesignColors.gold.withValues(alpha: 0.3),
                      blurRadius: 30)
                ],
              ),
              child: const Icon(Icons.bolt, size: 52, color: DesignColors.gold),
            ),
            const SizedBox(height: 24),
            const Text(
              'SPEED DATING',
              style: TextStyle(
                  color: DesignColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  shadows: DesignColors.secondaryGlow),
            ),
            const SizedBox(height: 10),
            const Text(
              'Match. Connect. Vibe. — 5-minute video dates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignColors.textGray, fontSize: 14),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Speed Dating is coming soon! 🔥'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [DesignColors.gold, Color(0xFFFF6B35)]),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                        color: DesignColors.gold.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Text(
                  'START SPEED DATING',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    return const RoomDiscoveryPageComplete();
  }

  /// Events Tab
  Widget _buildEventsTab() {
    return const EventsPage();
  }

  /// Chats Tab
  Widget _buildChatsTab() {
    return const ChatListPage();
  }

  /// Profile Tab
  Widget _buildProfileTab() {
    return const ProfilePage();
  }

  /// Discovery Tab
  Widget _buildDiscoveryTab() {
    return const DiscoveryPage();
  }
}

// ══════════════════════════════════════════════════════════
//  DATA CLASSES
// ══════════════════════════════════════════════════════════

@immutable
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
