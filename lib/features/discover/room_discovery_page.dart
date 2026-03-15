// lib/features/discover/room_discovery_page.dart
//
// RoomDiscoveryPage — 4-section scrolling discovery experience.
//
// Sections:
//   🔥 Trending Now     — top rooms by viewerCount DESC
//   ✨ New Rooms         — most recently created rooms
//   👥 Friends in Rooms — rooms where current user's friends are active
//   ⭐ Recommended For You — score-ranked personalized rooms
//
// Phases 2-7 of the Room Discovery Implementation Sweep.
// Ads inserted every 6-8 cards (AdPlacement.discover).
// Full analytics, skeleton loaders, empty states, retry, neon polish.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/analytics/analytics_service.dart' as core_analytics;
import '../../core/design_system/design_constants.dart';
import '../../shared/models/room.dart';
import '../../shared/widgets/club_background.dart';
import '../../shared/widgets/offline_widgets.dart';
import '../../shared/widgets/ad_tile_widget.dart';
import '../../shared/models/ad_entry.dart';
import '../../app/app_routes.dart';
import 'providers/room_discovery_providers.dart';
import 'widgets/room_discovery_section.dart';
import 'widgets/room_preview_sheet.dart';
import '../room/room_access_wrapper.dart';
import '../../features/room/providers/room_providers.dart' show liveRoomsProvider;

class RoomDiscoveryPage extends ConsumerStatefulWidget {
  const RoomDiscoveryPage({super.key});

  @override
  ConsumerState<RoomDiscoveryPage> createState() => _RoomDiscoveryPageState();
}

class _RoomDiscoveryPageState extends ConsumerState<RoomDiscoveryPage> {
  final ScrollController _scrollController = ScrollController();

  /// Scroll-depth milestones already logged.
  final Set<int> _loggedDepths = {};

  @override
  void initState() {
    super.initState();
    // Phase 5 analytics: screen_room_discovery
    core_analytics.AnalyticsService.instance
        .logScreenView(screenName: 'screen_room_discovery');
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // ── Scroll depth analytics ─────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final percent =
        (_scrollController.offset / max * 100).clamp(0.0, 100.0).round();
    for (final milestone in [25, 50, 75, 100]) {
      if (percent >= milestone && !_loggedDepths.contains(milestone)) {
        _loggedDepths.add(milestone);
        // Phase 5 analytics: discovery_scroll_depth
        core_analytics.AnalyticsService.instance.logEvent(
          name: 'discovery_scroll_depth',
          parameters: {'percent': milestone},
        );
      }
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _joinRoom(Room room) {
    HapticFeedback.mediumImpact();
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomAccessWrapper(room: room, userId: uid),
      ),
    );
  }

  void _previewRoom(Room room) {
    // analytics fired inside RoomPreviewSheet.show → discovery_room_preview_opened
    RoomPreviewSheet.show(
      context,
      room: room,
      onJoin: () => _joinRoom(room),
    );
  }

  void _logSectionViewed(String sectionName) {
    // Phase 5 analytics: discovery_section_viewed
    core_analytics.AnalyticsService.instance.logEvent(
      name: 'discovery_section_viewed',
      parameters: {'section_name': sectionName},
    );
  }

  // Adults flag — could be wired to user profile (age > 18 or isNSFW flag).
  bool get _userIsAdult => false;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final combined = ref.watch(roomDiscoveryCombinedProvider);
    final liveAsync = ref.watch(liveRoomsProvider);
    final hasError = liveAsync.hasError;

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Sticky App Bar ─────────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: DesignColors.background,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    shadowColor:
                        DesignColors.accent.withValues(alpha: 0.1),
                    title: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [
                              Color(0xFFFF4D8B),
                              Color(0xFF8B5CF6)
                            ],
                          ).createShader(b),
                          blendMode: BlendMode.srcIn,
                          child: const Text(
                            'Discover Rooms',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: DesignColors.primaryGlow,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Go Live CTA
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.goLive),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF4D8B),
                                  Color(0xFF8B5CF6)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4D8B)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Go Live',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Body ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Top discovery banner ad
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 0),
                          child: AdBannerWidget(
                            placement: AdPlacement.discover,
                            userIsAdult: _userIsAdult,
                            height: 72,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Section 1: Trending Now ────────────────────────
                        _SectionWrapper(
                          sectionName: 'trending_now',
                          onVisible: _logSectionViewed,
                          child: RoomDiscoverySection(
                            title: '🔥 Trending Now',
                            titleGradient: const [
                              Color(0xFFFF4D8B),
                              Color(0xFFFF6B35),
                            ],
                            rooms: combined.trending,
                            isLoading: combined.isLoading,
                            errorMessage: hasError
                                ? 'Could not load trending rooms.'
                                : null,
                            onRetry: () => setState(() {}),
                            emptyMessage:
                                'No trending rooms right now',
                            emptyIcon:
                                Icons.local_fire_department_outlined,
                            onRoomTap: _previewRoom,
                            userIsAdult: _userIsAdult,
                            adEvery: 8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Inter-section ad banner
                        AdBannerWidget(
                          placement: AdPlacement.discover,
                          userIsAdult: _userIsAdult,
                          height: 72,
                        ),

                        const SizedBox(height: 20),

                        // ── Section 2: New Rooms ──────────────────────────
                        _SectionWrapper(
                          sectionName: 'new_rooms',
                          onVisible: _logSectionViewed,
                          child: RoomDiscoverySection(
                            title: '✨ New Rooms',
                            titleGradient: const [
                              Color(0xFF00E5CC),
                              Color(0xFF4A90FF),
                            ],
                            rooms: combined.newRooms,
                            isLoading: combined.isLoading,
                            errorMessage: hasError
                                ? 'Could not load new rooms.'
                                : null,
                            onRetry: () => setState(() {}),
                            emptyMessage: 'No new rooms yet',
                            emptyIcon: Icons.fiber_new_outlined,
                            onRoomTap: _previewRoom,
                            userIsAdult: _userIsAdult,
                            adEvery: 8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Inter-section ad banner
                        AdBannerWidget(
                          placement: AdPlacement.discover,
                          userIsAdult: _userIsAdult,
                          height: 72,
                        ),

                        const SizedBox(height: 20),

                        // ── Section 3: Friends in Rooms ───────────────────
                        _SectionWrapper(
                          sectionName: 'friends_in_rooms',
                          onVisible: _logSectionViewed,
                          child: RoomDiscoverySection(
                            title: '👥 Friends in Rooms',
                            titleGradient: const [
                              Color(0xFF4A90FF),
                              Color(0xFF8B5CF6),
                            ],
                            rooms: combined.friendsInRooms,
                            isLoading: combined.isLoading,
                            errorMessage: hasError
                                ? 'Could not load friends\' rooms.'
                                : null,
                            onRetry: () => setState(() {}),
                            emptyMessage:
                                'No friends in rooms right now',
                            emptyIcon:
                                Icons.people_outline_rounded,
                            onRoomTap: _previewRoom,
                            userIsAdult: _userIsAdult,
                            adEvery: 8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Inter-section ad banner
                        AdBannerWidget(
                          placement: AdPlacement.discover,
                          userIsAdult: _userIsAdult,
                          height: 72,
                        ),

                        const SizedBox(height: 20),

                        // ── Section 4: Recommended For You ────────────────
                        _SectionWrapper(
                          sectionName: 'recommended_for_you',
                          onVisible: _logSectionViewed,
                          child: RoomDiscoverySection(
                            title: '⭐ Recommended For You',
                            titleGradient: const [
                              Color(0xFFFFD700),
                              Color(0xFFFF6B35),
                            ],
                            rooms: combined.recommended,
                            isLoading: combined.isLoading,
                            errorMessage: hasError
                                ? 'Could not load recommendations.'
                                : null,
                            onRetry: () => setState(() {}),
                            emptyMessage:
                                'No recommendations yet',
                            emptyIcon: Icons.stars_outlined,
                            onRoomTap: _previewRoom,
                            userIsAdult: _userIsAdult,
                            adEvery: 6,
                          ),
                        ),

                        // Bottom padding
                        const SizedBox(height: 40),
                      ],
                    ),
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

// ── Section visibility wrapper ────────────────────────────────────────────────

/// Fires [onVisible] once after the section is first rendered.
class _SectionWrapper extends StatefulWidget {
  final String sectionName;
  final void Function(String) onVisible;
  final Widget child;

  const _SectionWrapper({
    required this.sectionName,
    required this.onVisible,
    required this.child,
  });

  @override
  State<_SectionWrapper> createState() => _SectionWrapperState();
}

class _SectionWrapperState extends State<_SectionWrapper> {
  bool _fired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fired) {
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onVisible(widget.sectionName);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

