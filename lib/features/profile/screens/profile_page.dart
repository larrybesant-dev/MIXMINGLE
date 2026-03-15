import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mixmingle/shared/providers/profile_controller.dart';
import 'package:mixmingle/shared/providers/providers.dart';
import 'package:mixmingle/shared/models/user_profile.dart';
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/async_value_view_enhanced.dart';
import 'package:mixmingle/core/routing/app_routes.dart';
import 'package:mixmingle/core/design_system/design_constants.dart';
import 'package:mixmingle/core/intelligence/vibe_intelligence_service.dart';
<<<<<<< HEAD
import 'package:mixmingle/shared/providers/friend_request_provider.dart';
import 'package:mixmingle/services/social/friend_service.dart';
=======
import 'package:mixmingle/core/analytics/analytics_service.dart';
>>>>>>> origin/develop

import '../widgets/profile_mode_selector.dart';
import '../widgets/profile_music_widget.dart';
import '../widgets/layer_attraction.dart';
import '../widgets/layer_live_presence.dart';
import '../widgets/layer_social_proof.dart';
import '../widgets/layer_creator.dart';
import '../widgets/layer_safety.dart';
import '../widgets/media_gallery_widget.dart';
import '../widgets/profile_completeness_bar.dart';
import '../widgets/mutual_followers_row.dart';

// ─── Neon palette shortcuts ───────────────────────────────────────────────────
const _kPink = Color(0xFFFF4D8B); // live / dating
const _kCyan = Color(0xFF00E5CC); // recently active / event host
const _kBlue = Color(0xFF4A90FF); // accent / social
const _kAmber = Color(0xFFFFAB00); // creator / VIP
const _kPurple = Color(0xFF8B5CF6); // vibes / badges

// ════════════════════════════════════════════════════════════════════
// ProfilePage — 5-Layer Identity + Attraction + Authority + Monetization + Control
// Supports 4 modes: Social | Dating | Creator | EventHost
// 18+ adult content gated behind is18PlusVerified + isAdultContentEnabled
// Firestore collections:
//   publicProfile/{uid}         — all public layers
//   privateUser/{uid}           — safety/control settings
//   creatorData/{uid}           — earnings, subscribers (owner-only reads)
//   subscriptions/{uid}/subs/   — subscriber records
//   activityStats/{uid}         — rooms joined, events attended, rating
//   moderationFlags/{uid}       — reports, content reviews
// ════════════════════════════════════════════════════════════════════
class ProfilePage extends ConsumerStatefulWidget {
  /// If null → own profile. If provided → viewing someone else's profile.
  final String? targetUserId;

  const ProfilePage({super.key, this.targetUserId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  /// Local mode state — starts from what the profile says, owner can toggle.
  ProfileMode? _selectedMode;

  /// Guards one-time local tag refresh per page lifecycle.
  bool _tagsRefreshed = false;

<<<<<<< HEAD
  late TabController _profileTabController;
  int _profileTabIndex = 0;
=======
  /// Chip entrance animation
  late final AnimationController _chipAnim;

  @override
  void initState() {
    super.initState();
    _chipAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    AnalyticsService.instance.logScreenView(
      screenName: widget.targetUserId == null ? 'screen_profile_own' : 'screen_profile',
    );
  }

  @override
  void dispose() {
    _chipAnim.dispose();
    super.dispose();
  }
>>>>>>> origin/develop

  bool get _isOwner =>
      widget.targetUserId == null ||
      widget.targetUserId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _profileTabController = TabController(length: 4, vsync: this);
    _profileTabController.addListener(() {
      if (mounted) setState(() => _profileTabIndex = _profileTabController.index);
    });
  }

  @override
  void dispose() {
    _profileTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When viewing another user's profile, watch their data via family provider.
    final profileAsync = !_isOwner
        ? ref.watch(userProfileProvider(widget.targetUserId!))
        : ref.watch(currentUserProfileProvider);

    // Seed computed tags once per page load without waiting for nightly CF.
    ref.listen(currentUserProfileProvider, (_, next) {
      final p = next.asData?.value;
      if (p != null && !_tagsRefreshed && _isOwner) {
        _tagsRefreshed = true;
        _refreshBehaviorTags(p);
      }
    });

    return ClubBackground(
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AsyncValueViewEnhanced<UserProfile?>(
            value: profileAsync,
            maxRetries: 3,
            screenName: 'ProfilePage',
            providerName: 'currentUserProfileProvider',
            onRetry: () => ref.invalidate(currentUserProfileProvider),
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('Profile not found',
                      style: TextStyle(color: DesignColors.white)),
                );
              }
              _selectedMode ??= profile.profileMode;
              return _buildContent(profile);
            },
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  LOCAL BEHAVIOR TAG REFRESH
  // ══════════════════════════════════════════════════════════
  Future<void> _refreshBehaviorTags(UserProfile p) async {
    try {
      final freshTags =
          ref.read(vibeIntelligenceServiceProvider).computeBehaviorTags(p);
      if (freshTags.toSet() != p.computedTags.toSet()) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(p.id)
            .update({'computedTags': freshTags});
      }
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  //  SOCIAL ACTIONS (non-owner)
  // ══════════════════════════════════════════════════════════

  /// Handles the Follow/Add Friend button in LayerAttraction.
  Future<void> _handleFriendAction(UserProfile p) async {
    final svc = ref.read(friendServiceProvider);
    final statusAsync = ref.read(friendStatusProvider(p.id));
    final status = statusAsync.asData?.value ?? FriendRequestStatus.none;
    try {
      switch (status) {
        case FriendRequestStatus.none:
          await svc.sendFriendRequest(p.id);
          _toast('Friend request sent');
        case FriendRequestStatus.sent:
          await svc.cancelFriendRequest(p.id);
          _toast('Request cancelled');
        case FriendRequestStatus.received:
          await svc.acceptFriendRequest(p.id);
          _toast('${p.displayName ?? 'User'} added as friend!');
        case FriendRequestStatus.friends:
          await svc.removeFriend(p.id);
          _toast('Friend removed');
      }
    } catch (e) {
      _toast('Action failed: $e');
    }
  }

  /// Navigates to DM conversation with target user.
  void _handleMessage(UserProfile p) {
    // Navigate to chats list; in a full impl this would create/find a DM thread
    Navigator.pushNamed(context, AppRoutes.chats);
  }

  /// Builds the Block + Report + (Decline if received) extra row.
  Widget _buildSocialActionsExtra(UserProfile p) {
    final status = ref
        .watch(friendStatusProvider(p.id))
        .asData
        ?.value ?? FriendRequestStatus.none;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (status == FriendRequestStatus.received) ...[
            _socialChip(
              label: 'Accept Request',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF00C853),
              onTap: () async {
                await ref.read(friendServiceProvider).acceptFriendRequest(p.id);
                _toast('Friend added!');
              },
            ),
            _socialChip(
              label: 'Decline',
              icon: Icons.cancel_outlined,
              color: Colors.grey,
              onTap: () async {
                await ref.read(friendServiceProvider).rejectFriendRequest(p.id);
                _toast('Request declined');
              },
            ),
          ],
          _socialChip(
            label: 'Block',
            icon: Icons.block_outlined,
            color: const Color(0xFFFF6B35),
            onTap: () => _confirmBlock(p),
          ),
          _socialChip(
            label: 'Report',
            icon: Icons.flag_outlined,
            color: const Color(0xFFFF4D8B),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.reportUser,
              arguments: {'userId': p.id, 'displayName': p.displayName},
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _confirmBlock(UserProfile p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Block ${p.displayName ?? 'this user'}? They will no longer be able to see your profile or contact you.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(friendServiceProvider).blockUser(p.id);
      if (mounted) Navigator.pop(context);
      _toast('User blocked');
    }
  }

  // ══════════════════════════════════════════════════════════
  //  MAIN SCROLL VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildContent(UserProfile p) {
    final mode = _selectedMode ?? p.profileMode;
    final isBlockedByMe = !_isOwner
        ? (ref.watch(isBlockedByMeProvider(p.id)).asData?.value ?? false)
        : false;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(p),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Blocked banner ────────────────────────────────────
              if (isBlockedByMe) ...[
                const SizedBox(height: 8),
                _buildBlockedBanner(p),
              ],
              // ── Hero: name + flag + presence ──────────────────────
              _buildHeroNameSection(p),
              const SizedBox(height: 16),
              // ── Vibe Tags ─────────────────────────────────────────
              if (p.vibeTag != null ||
                  (p.interests != null && p.interests!.isNotEmpty))
                _buildVibeTagsSection(p),
              if (p.vibeTag != null ||
                  (p.interests != null && p.interests!.isNotEmpty))
                const SizedBox(height: 12),
              // ── Music Genres ──────────────────────────────────────
              if (p.musicGenres != null && p.musicGenres!.isNotEmpty)
                _buildMusicGenresSection(p),
              if (p.musicGenres != null && p.musicGenres!.isNotEmpty)
                const SizedBox(height: 16),
              // ── Bio ───────────────────────────────────────────────
              if (p.bio != null && p.bio!.isNotEmpty) _buildBioSection(p),
              if (p.bio != null && p.bio!.isNotEmpty)
                const SizedBox(height: 16),
              // ── Photo Gallery ─────────────────────────────────────
              if (p.galleryPhotos != null && p.galleryPhotos!.isNotEmpty) ...[
                _buildGallerySection(p),
                const SizedBox(height: 16),
              ],
              // ── Music Preview ─────────────────────────────────────
              if (p.favoriteTrackTitle != null &&
                  p.favoriteTrackTitle!.isNotEmpty) ...[
                ProfileMusicBadge(profile: p),
                const SizedBox(height: 16),
              ],
              // ── Badges ────────────────────────────────────────────
              _buildBadgesSection(p),
              const SizedBox(height: 16),
              _buildEnergyScoreSection(p),
              const SizedBox(height: 16),
              _buildActivityStatsSection(p),
              const SizedBox(height: 20),
              // ── Profile Tabs ──────────────────────────────────────
              _buildProfileTabBar(mode),
              const SizedBox(height: 16),
              // ── Tab Content ───────────────────────────────────────
              IndexedStack(
                index: _profileTabIndex,
                children: [
                  // Tab 0 — About
                  Column(children: [
                    _neonDivider(_modeAccent(mode)),
                    const SizedBox(height: 16),
                    ProfileModeSelector(
                      selected: mode,
                      isOwner: _isOwner,
                      onChanged: (m) => setState(() => _selectedMode = m),
                    ),
                    const SizedBox(height: 20),
                    ..._buildOrderedLayers(p, mode),
                    if (_isOwner) ...[
                      const SizedBox(height: 24),
                      ProfileCompletenessBar(userId: p.id),
                      const SizedBox(height: 8),
                      _buildEditProfileButton(),
                      const SizedBox(height: 8),
                    ],
                    if (_isOwner) ..._buildOwnerFooter(p),
                  ]),
                  // Tab 1 — Friends
                  _buildFriendsTab(p),
                  // Tab 2 — Rooms
                  _buildRoomsTab(p),
                  // Tab 3 — Photos
                  _buildPhotosTab(p),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedBanner(UserProfile p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Color(0xFFFF6B35), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You have blocked this user.',
              style: TextStyle(color: Color(0xFFFF6B35), fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await ref.read(friendServiceProvider).unblockUser(p.id);
              _toast('${p.displayName ?? 'User'} unblocked');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)),
              ),
              child: const Text(
                'Unblock',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabBar(ProfileMode mode) {
    final accent = _modeAccent(mode);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: _profileTabController,
        labelColor: accent,
        unselectedLabelColor: Colors.white38,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Friends'),
          Tab(text: 'Rooms'),
          Tab(text: 'Photos'),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(UserProfile p) {
    final friendIds = ref.watch(friendIdsOfUserProvider(p.id));
    return friendIds.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF4A90FF))),
      ),
      error: (_, __) => const _TabEmptyState(
        icon: Icons.people_outline,
        message: 'Unable to load friends',
      ),
      data: (ids) {
        if (ids.isEmpty) {
          return _TabEmptyState(
            icon: Icons.people_outline,
            message: _isOwner ? 'No friends yet. Start connecting!' : 'No public friends.',
          );
        }
        return Column(
          children: ids
              .take(30)
              .map((uid) => _FriendTile(uid: uid))
              .toList(),
        );
      },
    );
  }

  Widget _buildRoomsTab(UserProfile p) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('hostId', isEqualTo: p.id)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5CC))),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _TabEmptyState(
            icon: Icons.mic_none_outlined,
            message: _isOwner ? 'You haven\'t hosted any rooms yet.' : 'No rooms hosted yet.',
          );
        }
        return Column(
          children: docs
              .map((doc) => _RoomTile(
                    roomId: doc.id,
                    data: doc.data() as Map<String, dynamic>,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildPhotosTab(UserProfile p) {
    final photos = p.galleryPhotos ?? [];
    if (photos.isEmpty) {
      return _TabEmptyState(
        icon: Icons.photo_library_outlined,
        message: _isOwner ? 'No photos yet. Add some to your gallery!' : 'No photos shared.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _showPhotoViewer(ctx, photos, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            photos[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1F2E),
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoViewer(BuildContext ctx, List<String> photos, int initial) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initial),
              itemCount: photos.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Image.network(photos[i], fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MODE-ORDERED LAYERS
  // ══════════════════════════════════════════════════════════
  List<Widget> _buildOrderedLayers(UserProfile p, ProfileMode mode) {
    final attraction = [
      LayerAttraction(
        p: p,
        isOwner: _isOwner,
        onFollow: _isOwner ? null : () => _handleFriendAction(p),
        onMessage: _isOwner ? null : () => _handleMessage(p),
      ),
      if (!_isOwner) ...[
        const SizedBox(height: 8),
        _buildSocialActionsExtra(p),
      ],
      const SizedBox(height: 24),
    ];

    final live = (p.roomsHostedCount > 0 ||
            p.presenceStatus == 'in_room' ||
            p.eventsHostingCount > 0)
        ? [
            LayerLivePresence(
              p: p,
              onJoinRoom: () {
                if (p.presenceStatus == 'in_room' && p.activeRoomId != null) {
                  Navigator.pushNamed(context, AppRoutes.room, arguments: p.activeRoomId);
                } else {
                  _toast('No active room');
                }
              },
              onViewEvents: () => Navigator.pushNamed(context, AppRoutes.events),
            ),
            const SizedBox(height: 24),
          ]
        : <Widget>[];

    final social = [
      LayerSocialProof(p: p, isOwner: _isOwner),
      const SizedBox(height: 24),
    ];

    final creator = p.isCreatorEnabled
        ? [
            LayerCreator(
              p: p,
              isOwner: _isOwner,
              onSubscribe: () => _toast('Subscribe'),
              onTip: () => _toast('Tip'),
              onJoinPaidRoom: () => _toast('Join Paid Room'),
              onViewVault: () => _toast('Vault'),
              onWithdraw: _isOwner ? () => _toast('Withdraw') : null,
            ),
            const SizedBox(height: 24),
          ]
        : <Widget>[];

    final dating = _hasDatingData(p)
        ? [_buildDatingLayer(p), const SizedBox(height: 24)]
        : <Widget>[];

    final supporting = _buildSupportingContent(p);

    switch (mode) {
      case ProfileMode.dating:
        return [
          ...attraction,
          ...dating,
          ...social,
          ...live,
          ...creator,
          ...supporting
        ];
      case ProfileMode.creator:
        return [...creator, ...attraction, ...live, ...social, ...supporting];
      case ProfileMode.eventHost:
        return [...live, ...social, ...attraction, ...creator, ...supporting];
      case ProfileMode.social:
        return [
          ...social,
          ...attraction,
          ...live,
          ...creator,
          ...dating,
          ...supporting
        ];
    }
  }

  // ── Dating Intent Layer ────────────────────────────────────
  bool _hasDatingData(UserProfile p) =>
      (p.lookingFor != null && p.lookingFor!.isNotEmpty) ||
      p.relationshipType != null ||
      (p.preferredGenders != null && p.preferredGenders!.isNotEmpty);

  Widget _buildDatingLayer(UserProfile p) {
    const color = Color(0xFFFF4D8B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.favorite_border, 'Looking For', color),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(children: [
            if (p.lookingFor != null && p.lookingFor!.isNotEmpty)
              _datingRow('Intent', p.lookingFor!.join(' • '), color),
            if (p.relationshipType != null)
              _datingRow('Relationship', p.relationshipType!, color),
            if (p.preferredGenders != null && p.preferredGenders!.isNotEmpty)
              _datingRow(
                  'Interested in', p.preferredGenders!.join(', '), color),
            if (p.minAgePreference != null && p.maxAgePreference != null)
              _datingRow('Age range',
                  '${p.minAgePreference} – ${p.maxAgePreference}', color),
          ]),
        ),
      ],
    );
  }

  Widget _datingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF8892A4), fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Supporting Content ─────────────────────────────────────
  List<Widget> _buildSupportingContent(UserProfile p) {
    final widgets = <Widget>[];
    final hasPhotos = p.galleryPhotos != null && p.galleryPhotos!.isNotEmpty;
    final hasVideos = p.galleryVideos != null && p.galleryVideos!.isNotEmpty;
    if (hasPhotos || hasVideos || _isOwner) {
      widgets.addAll([
<<<<<<< HEAD
        Row(
          children: [
            Expanded(
              child: _sectionHeader(
                  Icons.photo_library_outlined, 'Gallery', DesignColors.accent),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.profileMedia,
                arguments: {'userId': p.id, 'isOwner': _isOwner},
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                    color: DesignColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
=======
        _sectionHeader(
            Icons.photo_library_outlined, 'Gallery', DesignColors.accent),
>>>>>>> origin/develop
        const SizedBox(height: 10),
        MediaGallery(
          photos: p.galleryPhotos ?? [],
          videos: p.galleryVideos ?? [],
          isOwner: _isOwner,
          onAddPhoto: _isOwner
              ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.profileMedia,
                    arguments: {'userId': p.id, 'isOwner': true},
                  )
              : null,
          onAddVideo: _isOwner
              ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.profileMedia,
                    arguments: {'userId': p.id, 'isOwner': true},
                  )
              : null,
        ),
        const SizedBox(height: 20),
      ]);
    }
    if (p.lifestylePrompts != null &&
        p.lifestylePrompts!.values.any((v) => v)) {
      widgets.addAll([
        _sectionHeader(
            Icons.favorite_border, 'Lifestyle', DesignColors.secondary),
        const SizedBox(height: 10),
        _buildLifestyleRow(p.lifestylePrompts!),
        const SizedBox(height: 20),
      ]);
    }
    if (p.musicTastes != null && p.musicTastes!.isNotEmpty) {
      widgets.addAll([
        _sectionHeader(
            Icons.music_note_outlined, 'Music', DesignColors.tertiary),
        const SizedBox(height: 10),
        _buildChipWrap(p.musicTastes!, DesignColors.tertiary),
        const SizedBox(height: 20),
      ]);
    }
    if (p.socialLinks != null && p.socialLinks!.isNotEmpty) {
      widgets.addAll([
        _sectionHeader(Icons.link_outlined, 'Socials', DesignColors.tertiary),
        const SizedBox(height: 10),
        _buildSocialRow(p.socialLinks!),
        const SizedBox(height: 20),
      ]);
    }
    return widgets;
  }

  // ── Owner Footer: Safety + Settings ───────────────────────
  List<Widget> _buildOwnerFooter(UserProfile p) {
    return [
      LayerSafety(
        p: p,
        isOwner: true,
<<<<<<< HEAD
        onEditDmRestriction: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
        onToggleHideDistance: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
        onToggleHideFollowers: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
        onToggleRestrictInvites: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
        onBlockList: () => Navigator.pushNamed(context, AppRoutes.blockedUsers),
        onSetup2FA: () => Navigator.pushNamed(context, AppRoutes.accountSettings),
        onContentModeration: () => Navigator.pushNamed(context, AppRoutes.accountSettings),
=======
        onEditDmRestriction: () =>
            Navigator.pushNamed(context, '/settings/privacy'),
        onToggleHideDistance: () =>
            Navigator.pushNamed(context, '/settings/privacy'),
        onToggleHideFollowers: () =>
            Navigator.pushNamed(context, '/settings/privacy'),
        onToggleRestrictInvites: () =>
            Navigator.pushNamed(context, '/settings/privacy'),
        onBlockList: () => Navigator.pushNamed(context, '/settings/blocked'),
        onSetup2FA: () => Navigator.pushNamed(context, '/settings/security'),
        onContentModeration: () =>
            Navigator.pushNamed(context, '/creator/moderation'),
>>>>>>> origin/develop
      ),
      const SizedBox(height: 24),
      _sectionHeader(Icons.settings_outlined, 'Account', DesignColors.textGray),
      const SizedBox(height: 10),
<<<<<<< HEAD
      _navTile(Icons.privacy_tip_outlined, 'Privacy Settings', () => Navigator.pushNamed(context, AppRoutes.privacySettings)),
      _navTile(Icons.notifications_outlined, 'Notifications', () => Navigator.pushNamed(context, AppRoutes.notificationSettings)),
      _navTile(Icons.block_outlined, 'Blocked Users', () => Navigator.pushNamed(context, AppRoutes.blockedUsers)),
      _navTile(Icons.settings_outlined, 'Account Settings', () => Navigator.pushNamed(context, AppRoutes.settings)),
      if (p.isCreatorEnabled)
        _navTile(Icons.monetization_on_outlined, 'Creator Settings', () => Navigator.pushNamed(context, AppRoutes.accountSettings)),
      _navTile(Icons.admin_panel_settings_outlined, 'Admin Dashboard', () => Navigator.pushNamed(context, AppRoutes.adminDashboard)),
=======
      _navTile(Icons.person_add_outlined, 'Friend Requests',
          () => Navigator.pushNamed(context, '/friend-requests')),
      _navTile(Icons.favorite_outlined, 'Speed Dating Matches',
          () => Navigator.pushNamed(context, '/speed-dating/matches')),
      _navTile(Icons.privacy_tip_outlined, 'Privacy Settings',
          () => Navigator.pushNamed(context, '/settings/privacy')),
      _navTile(Icons.notifications_outlined, 'Notifications',
          () => Navigator.pushNamed(context, '/notifications')),
      _navTile(Icons.settings_outlined, 'Account Settings',
          () => Navigator.pushNamed(context, '/settings')),
      if (p.isCreatorEnabled)
        _navTile(Icons.monetization_on_outlined, 'Creator Settings',
            () => Navigator.pushNamed(context, '/creator/settings')),
>>>>>>> origin/develop
      const SizedBox(height: 20),
      _buildLogoutButton(),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: _showDeleteAccountDialog,
          child: const Text('Delete Account',
              style: TextStyle(
                  color: DesignColors.error,
                  decoration: TextDecoration.underline)),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ══════════════════════════════════════════════════════════
  //  SLIVER APP BAR — Banner + Centered Avatar (TikTok-style)
  // ══════════════════════════════════════════════════════════
  Widget _buildSliverAppBar(UserProfile p) {
    final avatarGlow = _avatarGlowColor(p);
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: DesignColors.background,
      leading: !_isOwner
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: DesignColors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: [
<<<<<<< HEAD
        if (_isOwner)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _neonIconButton(
              Icons.settings_outlined,
              DesignColors.accent,
              () => Navigator.pushNamed(context, AppRoutes.settings),
=======
        if (_isOwner) ...
          [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _neonIconButton(
                Icons.ios_share_outlined,
                _kCyan,
                _shareProfile,
              ),
>>>>>>> origin/develop
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _neonIconButton(
                Icons.settings_outlined,
                DesignColors.accent,
                () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
          ]
        else ...
          [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _neonIconButton(
                Icons.ios_share_outlined,
                _kCyan,
                _shareProfile,
              ),
            ),
          ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            // ── Banner image or gradient ────────────────────────────
            p.coverPhotoUrl != null
                ? Image.network(p.coverPhotoUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0D1117),
                          Color(0xFF1A1F2E),
                          Color(0xFF0D1117)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(children: [
                      Center(
                          child: Icon(Icons.music_note,
                              color:
                                  DesignColors.accent.withValues(alpha: 0.08),
                              size: 140)),
                    ]),
                  ),
            // ── Gradient fade to background ─────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    DesignColors.background.withValues(alpha: 0.6),
                    DesignColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // ── Avatar — centered, bottom of banner ─────────────────
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer neon glow ring
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            avatarGlow,
                            avatarGlow.withValues(alpha: 0.3)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: avatarGlow.withValues(alpha: 0.55),
                              blurRadius: 24,
                              spreadRadius: 3),
                          BoxShadow(
                              color: avatarGlow.withValues(alpha: 0.25),
                              blurRadius: 48,
                              spreadRadius: 6),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: DesignColors.surfaceDefault,
                          backgroundImage: p.photoUrl != null
                              ? NetworkImage(p.photoUrl!)
                              : null,
                          child: p.photoUrl == null
                              ? const Icon(Icons.person,
                                  size: 52, color: DesignColors.textGray)
                              : null,
                        ),
                      ),
                    ),
                    // ── Edit avatar button (owner only) ──────────────
                    if (_isOwner)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.editProfile),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DesignColors.surfaceLight,
                              border: Border.all(color: avatarGlow, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: avatarGlow.withValues(alpha: 0.4),
                                    blurRadius: 8)
                              ],
                            ),
                            child: const Icon(Icons.edit,
                                size: 15, color: DesignColors.white),
                          ),
                        ),
                      ),
                    // ── Live indicator ───────────────────────────────
                    if (p.presenceStatus == 'in_room')
                      Positioned(
                        top: 4,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kPink,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: _kPink.withValues(alpha: 0.6),
                                  blurRadius: 6)
                            ],
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glow color based on presence status — Live=pink, Active=cyan, else blue
  Color _avatarGlowColor(UserProfile p) {
    if (p.presenceStatus == 'in_room') return _kPink;
    if (p.presenceStatus == 'online') return _kCyan;
    return _kBlue;
  }

  // ══════════════════════════════════════════════════════════
  //  HERO NAME SECTION  — Name + Flag + Joined + Presence
  // ══════════════════════════════════════════════════════════
  Widget _buildHeroNameSection(UserProfile p) {
    final name = p.displayName ?? p.nickname ?? 'Anonymous';
    final age = p.age;
    final flag = p.countryCode != null ? _countryFlag(p.countryCode!) : null;
    final days = DateTime.now().difference(p.createdAt).inDays;
    final joined = days == 0
        ? 'Joined today'
        : days == 1
            ? 'Joined yesterday'
            : 'Joined $days days ago';

    return Column(
      children: [
        // Name + flag row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                age != null ? '$name, $age' : name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: DesignColors.white,
                  height: 1.15,
                  shadows: DesignColors.primaryGlow,
                ),
              ),
            ),
            if (flag != null) ...[
              const SizedBox(width: 8),
              Text(flag, style: const TextStyle(fontSize: 22)),
            ],
            if (p.isPhotoVerified == true || p.isIdVerified == true) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlue,
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Joined + presence
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(joined,
                style: const TextStyle(
                    color: DesignColors.textGray, fontSize: 12)),
            if (p.presenceStatus != null && p.presenceStatus != 'offline') ...[
              const SizedBox(width: 10),
              _presencePill(p.presenceStatus!),
            ],
          ],
        ),
        // Follower stats row
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statBadge(_formatCount(p.followersCount), 'Followers'),
            const SizedBox(width: 12),
            Container(width: 1, height: 28, color: DesignColors.divider),
            const SizedBox(width: 12),
            _statBadge(_formatCount(p.followingCount), 'Following'),
            if (p.roomsHostedCount > 0) ...[
              const SizedBox(width: 12),
              Container(width: 1, height: 28, color: DesignColors.divider),
              const SizedBox(width: 12),
              _statBadge('${p.roomsHostedCount}', 'Rooms'),
            ],
          ],
        ),
        // Mutual followers row (only when viewing someone else's profile)
        if (!_isOwner && widget.targetUserId != null)
          MutualFollowersRow(
            currentUserId:
                FirebaseAuth.instance.currentUser?.uid ?? '',
            profileUserId: widget.targetUserId!,
          ),
      ],
    );
  }

  Widget _presencePill(String status) {
    final Color color;
    final String label;
    final IconData icon;
    switch (status) {
      case 'in_room':
        color = _kPink;
        label = 'In a room';
        icon = Icons.graphic_eq;
        break;
      case 'online':
        color = _kCyan;
        label = 'Active now';
        icon = Icons.circle;
        break;
      default:
        color = DesignColors.textGray;
        label = 'Recently active';
        icon = Icons.access_time_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: const TextStyle(
              color: DesignColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: DesignColors.textGray, fontSize: 11)),
    ]);
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String _countryFlag(String countryCode) {
    return countryCode
        .toUpperCase()
        .split('')
        .map((c) => String.fromCharCode(c.codeUnitAt(0) + 127397))
        .join();
  }

  // ══════════════════════════════════════════════════════════
  //  VIBE TAGS SECTION
  // ══════════════════════════════════════════════════════════
  Widget _buildVibeTagsSection(UserProfile p) {
    // Combine vibeTag (single) + interests into chips
    final tags = <String>[];
    if (p.vibeTag != null) tags.add(p.vibeTag!);
    if (p.interests != null) tags.addAll(p.interests!.take(5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionLabel(Icons.bolt_outlined, 'Vibes', _kPurple),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tags.length, (i) {
              final start = (i * 0.12).clamp(0.0, 0.7);
              final end = (start + 0.4).clamp(0.0, 1.0);
              final fade = CurvedAnimation(
                parent: _chipAnim,
                curve: Interval(start, end, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(fade),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _vibeChip(tags[i], _kPurple),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _vibeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6)
        ],
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MUSIC GENRES SECTION
  // ══════════════════════════════════════════════════════════
  Widget _buildMusicGenresSection(UserProfile p) {
    final genres = p.musicGenres!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionLabel(Icons.music_note_outlined, 'Music', _kCyan),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(genres.length, (i) {
              final start = (0.3 + i * 0.1).clamp(0.0, 0.8);
              final end = (start + 0.35).clamp(0.0, 1.0);
              final fade = CurvedAnimation(
                parent: _chipAnim,
                curve: Interval(start, end, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: fade,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _kCyan.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                            color: _kCyan.withValues(alpha: 0.12),
                            blurRadius: 4)
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.headphones, size: 12, color: _kCyan),
                      const SizedBox(width: 5),
                      Text(genres[i],
                          style: const TextStyle(
                              color: _kCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BIO SECTION
  // ══════════════════════════════════════════════════════════
  Widget _buildBioSection(UserProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Neon underline divider
        Row(children: [
          Container(height: 1, width: 32, color: _kBlue.withValues(alpha: 0.7)),
          Container(height: 1, width: 16, color: _kPink.withValues(alpha: 0.5)),
          Expanded(
              child: Container(
                  height: 1,
                  color: DesignColors.divider.withValues(alpha: 0.3))),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBlue.withValues(alpha: 0.18)),
          ),
          child: Text(
            p.bio!,
            style: const TextStyle(
              color: DesignColors.textLightGray,
              fontSize: 14,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PHOTO GALLERY SECTION
  // ══════════════════════════════════════════════════════════
  Widget _buildGallerySection(UserProfile p) {
    final photos = p.galleryPhotos!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionLabel(Icons.photo_library_outlined, 'Gallery', _kPink),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: photos.length.clamp(0, 6),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _viewGalleryPhoto(photos[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: DesignColors.surfaceLight,
                      child: const Icon(Icons.broken_image,
                          color: DesignColors.textGray, size: 24),
                    ),
                  ),
                  // Neon overlay shimmer on last tile if more photos
                  if (i == 5 && photos.length > 6)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '+${photos.length - 6}',
                          style: TextStyle(
                            color: _kPink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                  color: _kPink.withValues(alpha: 0.8),
                                  blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _viewGalleryPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BADGES & SOCIAL PROOF
  // ══════════════════════════════════════════════════════════
  Widget _buildBadgesSection(UserProfile p) {
    final badges = <_BadgeItem>[];

    if (p.isPremium || p.isVip) {
      badges.add(const _BadgeItem(Icons.workspace_premium, 'VIP', _kAmber));
    }
    if (p.isCreatorBadge || p.isCreatorEnabled) {
      badges.add(const _BadgeItem(Icons.movie_creation_outlined, 'Creator', _kPink));
    }
    if (p.isPhotoVerified == true || p.isIdVerified == true) {
      badges.add(const _BadgeItem(Icons.verified_outlined, 'Verified', _kBlue));
    }
    if (p.isBoosted) {
      badges.add(const _BadgeItem(Icons.rocket_launch_outlined, 'Boosted', _kCyan));
    }
    if (p.communityRating >= 4.5 && p.totalRoomsJoined >= 10) {
      badges.add(const _BadgeItem(Icons.star_outline, 'Top Host', _kAmber));
    }
    if (p.twoFactorEnabled) {
<<<<<<< HEAD
      badges.add(const _BadgeItem(Icons.security_outlined, '2FA Active', DesignColors.success));
    }
    // Stored badge IDs from Firestore
    for (final id in p.badgeIds ?? []) {
      switch (id) {
        case 'active_today':
          badges.add(const _BadgeItem(Icons.bolt, 'Active Today', _kCyan));
          break;
        case 'top_creator':
          badges.add(const _BadgeItem(Icons.emoji_events_outlined, 'Top Creator', _kAmber));
          break;
        case 'rising_star':
          badges.add(const _BadgeItem(Icons.star_half_outlined, 'Rising Star', _kPink));
          break;
        case 'verified':
          if (!badges.any((b) => b.label == 'Verified')) {
            badges.add(const _BadgeItem(Icons.verified_outlined, 'Verified', _kBlue));
          }
          break;
        default:
          badges.add(_BadgeItem(Icons.military_tech_outlined, id, _kPurple));
      }
=======
      badges.add(const _BadgeItem(
          Icons.security_outlined, '2FA Active', DesignColors.success));
>>>>>>> origin/develop
    }

    // Always show at least placeholder row so space is reserved
    if (badges.isEmpty && p.computedTags.isEmpty) {
      return _buildEmptyBadgesPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionLabel(Icons.military_tech_outlined, 'Badges', _kAmber),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...badges.map((b) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            b.color.withValues(alpha: 0.18),
                            b.color.withValues(alpha: 0.06)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: b.color.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                              color: b.color.withValues(alpha: 0.2),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(b.icon, size: 13, color: b.color),
                        const SizedBox(width: 5),
                        Text(b.label,
                            style: TextStyle(
                                color: b.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  )),
              // Computed behaviour tags (purple neon chips)
              ...p.computedTags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.45)),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ENERGY SCORE SECTION  (#6)
  // ══════════════════════════════════════════════════════════
  Widget _buildEnergyScoreSection(UserProfile p) {
    final score = p.energyScore;
    final ratio = score / 100.0;
    final tier = score < 30
        ? 'Warm Up'
        : score < 65
            ? 'Active'
            : 'High Energy';
    const barColor = Color(0xFF00E5CC);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _miniSectionLabel(Icons.bolt, 'Energy Score', barColor),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: barColor.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('$score',
                style: const TextStyle(
                    color: barColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const Text(' / 100',
                style: TextStyle(color: DesignColors.textGray, fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: barColor.withValues(alpha: 0.4)),
              ),
              child: Text(tier,
                  style: const TextStyle(
                      color: barColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: barColor.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildEmptyBadgesPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: DesignColors.divider.withValues(alpha: 0.3),
            style: BorderStyle.solid),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline,
            size: 13, color: DesignColors.textGray.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text('Badges unlock as you engage',
            style: TextStyle(
                color: DesignColors.textGray.withValues(alpha: 0.6),
                fontSize: 12)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ACTIVITY STATS SECTION
  // ══════════════════════════════════════════════════════════
  Widget _buildActivityStatsSection(UserProfile p) {
    final stats = <_StatItem>[];

    if (p.roomsHostedCount > 0) {
<<<<<<< HEAD
      stats.add(_StatItem('${p.roomsHostedCount}', 'Rooms Hosted', Icons.mic_none_outlined, _kBlue));
    }
    if (p.eventsAttended > 0) {
      stats.add(_StatItem('${p.eventsAttended}', 'Events', Icons.event_outlined, _kCyan));
    }
    if (p.communityRating > 0) {
      stats.add(_StatItem(p.communityRating.toStringAsFixed(1), 'Rating', Icons.star_outline, _kAmber));
    }
    if (p.mutualsCount > 0) {
      stats.add(_StatItem('${p.mutualsCount}', 'Mutuals', Icons.people_outline, _kPurple));
=======
      stats.add(_StatItem('${p.roomsHostedCount}', 'Rooms Hosted',
          Icons.mic_none_outlined, _kBlue));
    }
    if (p.eventsAttended > 0) {
      stats.add(_StatItem(
          '${p.eventsAttended}', 'Events', Icons.event_outlined, _kCyan));
    }
    if (p.communityRating > 0) {
      stats.add(_StatItem(p.communityRating.toStringAsFixed(1), 'Rating',
          Icons.star_outline, _kAmber));
    }
    if (p.mutualsCount > 0) {
      stats.add(_StatItem(
          '${p.mutualsCount}', 'Mutuals', Icons.people_outline, _kPurple));
>>>>>>> origin/develop
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionLabel(
            Icons.bar_chart_outlined, 'Activity', DesignColors.secondary),
        const SizedBox(height: 10),
        Row(
          children: stats
              .map((s) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: s.color.withValues(alpha: 0.25)),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(s.icon, size: 16, color: s.color),
                        const SizedBox(height: 4),
                        Text(s.value,
                            style: TextStyle(
                                color: s.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        Text(s.label,
                            style: const TextStyle(
                                color: DesignColors.textGray, fontSize: 10),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  EDIT PROFILE BUTTON  (owner only)
  // ══════════════════════════════════════════════════════════
  Widget _buildEditProfileButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90FF), Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _kBlue.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Edit Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _miniSectionLabel(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 6)
            ],
          )),
    ]);
  }

  Widget _neonDivider(Color color) {
    return Row(children: [
      Expanded(
          child: Container(height: 1, color: color.withValues(alpha: 0.3))),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)
          ],
        ),
      ),
      Expanded(
          child: Container(height: 1, color: color.withValues(alpha: 0.3))),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  //  SUPPORTING CONTENT SUB-WIDGETS  (Gallery, Lifestyle, Socials)
  // ══════════════════════════════════════════════════════════
<<<<<<< HEAD
=======
  Widget _buildGalleryGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _openPhotoViewer(photos, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(photos[i], fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _openPhotoViewer(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
                child: Image.network(photos[index], fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
>>>>>>> origin/develop

  static const Map<String, String> _lifestyleLabels = {
    'smoking': 'Smoking',
    'drinking': 'Drinking',
    'fitness': 'Fitness',
    'pets': 'Has Pets',
    'kids': 'Has Kids',
  };
  static const Map<String, IconData> _lifestyleIcons = {
    'smoking': Icons.smoke_free,
    'drinking': Icons.local_bar_outlined,
    'fitness': Icons.fitness_center_outlined,
    'pets': Icons.pets_outlined,
    'kids': Icons.child_care_outlined,
  };

  Widget _buildLifestyleRow(Map<String, bool> lifestyle) {
    final active = lifestyle.entries.where((e) => e.value).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: active.map((e) {
        final label = _lifestyleLabels[e.key] ?? e.key;
        final icon = _lifestyleIcons[e.key] ?? Icons.check_circle_outline;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: DesignColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: DesignColors.secondary.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: DesignColors.secondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: DesignColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildChipWrap(List<String> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(item,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  static const Map<String, String> _socialIcons = {
    'instagram': 'IG',
    'tiktok': 'TK',
    'snapchat': 'SC',
    'twitter': 'X',
  };
  static const Map<String, Color> _socialColors = {
    'instagram': Color(0xFFE1306C),
    'tiktok': Color(0xFF69C9D0),
    'snapchat': Color(0xFFFFFC00),
    'twitter': Color(0xFF1DA1F2),
  };

  Widget _buildSocialRow(Map<String, String> links) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: links.entries.map((e) {
        final color = _socialColors[e.key] ?? DesignColors.accent;
        final abbr = _socialIcons[e.key] ?? e.key.substring(0, 2).toUpperCase();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(abbr,
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Text(e.value,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Text(title,
          style: DesignTypography.subheading.copyWith(
            color: color,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 12)
            ],
          )),
      const SizedBox(width: 8),
      Expanded(
          child: Container(height: 1, color: color.withValues(alpha: 0.25))),
    ]);
  }

  Widget _navTile(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Icon(icon, size: 20, color: DesignColors.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: DesignTypography.body)),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: DesignColors.textGray),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _neonIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DesignColors.background.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.error.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showLogoutDialog,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text('Logout',
                  style: TextStyle(
                      color: DesignColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }

  Color _modeAccent(ProfileMode m) {
    switch (m) {
      case ProfileMode.social:
        return const Color(0xFF4A90FF);
      case ProfileMode.dating:
        return const Color(0xFFFF4D8B);
      case ProfileMode.creator:
        return const Color(0xFFFFAB00);
      case ProfileMode.eventHost:
        return const Color(0xFF00E5CC);
    }
  }

  void _shareProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _scaffoldKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Profile link copied! 🎶'),
      backgroundColor: Color(0xFF1E2D40),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _toast(String msg) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text('$msg — coming soon'),
      backgroundColor: const Color(0xFF1E2D40),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ══════════════════════════════════════════════════════════
  //  DIALOGS
  // ══════════════════════════════════════════════════════════
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Logout', style: TextStyle(color: DesignColors.white)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: DesignColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: DesignColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            child: const Text('Logout',
                style: TextStyle(color: DesignColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(color: DesignColors.white)),
        content: const Text(
            'This action cannot be undone. All data will be permanently deleted.',
            style: TextStyle(color: DesignColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: DesignColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (mounted) {
                  navigator.pop();
                  navigator.pushNamedAndRemoveUntil(
                      AppRoutes.login, (_) => false);
                }
              } catch (e) {
                if (mounted) {
                  _scaffoldKey.currentState?.showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')));
                  navigator.pop();
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: DesignColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Lightweight data models used by badge + stat sections ───────────────────
class _BadgeItem {
  final IconData icon;
  final String label;
  final Color color;
  const _BadgeItem(this.icon, this.label, this.color);
}

class _StatItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatItem(this.value, this.label, this.icon, this.color);
}

// ─── Profile tab helpers ──────────────────────────────────────────────────────

class _TabEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _TabEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.white12),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final String uid;
  const _FriendTile({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    return profileAsync.when(
      loading: () => const ListTile(
        leading: CircleAvatar(backgroundColor: Color(0xFF1A1F2E), radius: 22),
        title: SizedBox(height: 12, width: 80, child: ColoredBox(color: Color(0xFF1A1F2E))),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
            backgroundColor: const Color(0xFF1A1F2E),
            child: p.photoUrl == null
                ? Text(
                    (p.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          title: Text(
            p.displayName ?? 'Unknown',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: p.bio != null && p.bio!.isNotEmpty
              ? Text(
                  p.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                )
              : null,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.userProfile,
            arguments: uid,
          ),
        );
      },
    );
  }
}

class _RoomTile extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> data;
  const _RoomTile({required this.roomId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unnamed Room';
    final count = data['participantCount'] as int? ?? 0;
    final isLive = data['isLive'] as bool? ?? false;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF00E5CC).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00E5CC).withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.mic_none_outlined, color: Color(0xFF00E5CC), size: 20),
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$count participants',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: isLive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D8B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF4D8B).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(color: Color(0xFFFF4D8B), fontSize: 10, fontWeight: FontWeight.w800),
              ),
            )
          : null,
      onTap: () => Navigator.pushNamed(context, AppRoutes.room, arguments: roomId),
    );
  }
}
