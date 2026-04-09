import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/controllers/feed_controller.dart';
import '../feed/widgets/post_card.dart';
import '../feed/widgets/live_room_card.dart';
import '../profile/profile_completion.dart';
import '../profile/profile_controller.dart';
import '../../presentation/providers/user_provider.dart';
import '../stories/widgets/stories_row.dart';
import 'daily_checkin_card.dart';
import 'leaderboard_strip.dart';
import '../../models/user.dart' as feed_user;
import '../../models/user_model.dart';
import '../../widgets/mixvy_drawer.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showNavigationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openRoom(String? roomId) {
    final normalizedRoomId = roomId?.trim() ?? '';
    if (normalizedRoomId.isEmpty) {
      _showNavigationError('This room is unavailable right now.');
      return;
    }
    context.go('/room/${Uri.encodeComponent(normalizedRoomId)}');
  }

  void _openProfile(String? userId) {
    final normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isEmpty) {
      _showNavigationError('This profile is unavailable right now.');
      return;
    }
    context.go('/profile/${Uri.encodeComponent(normalizedUserId)}');
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);
    final trendingUsersAsync = ref.watch(trendingUsersStreamProvider);
    final profileState = ref.watch(profileControllerProvider);
    final setupItems = ProfileCompletion.homeNudgeItems(profileState);
    final currentUser = ref.watch(userProvider);
    final newMembersAsync = ref.watch(newMembersStreamProvider);

    return Scaffold(
      backgroundColor: NeonPulse.surface,
      drawer: const MixVyDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: NeonPulse.surface,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 16,
            title: ShaderMask(
              shaderCallback: (rect) =>
                  NeonPulse.primaryGradient.createShader(rect),
              blendMode: BlendMode.srcIn,
              child: const Text(
                'MixVy',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
            centerTitle: false,
            actions: [
              _StatsBarWidget(
                onlineAsync: ref.watch(onlineUsersCountProvider),
                liveAsync: ref.watch(liveRoomsCountProvider),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: NeonPulse.onSurface),
                tooltip: 'Create',
                onPressed: () => _showCreateMenu(context),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: NeonPulse.onSurface),
                onPressed: () => context.go('/notifications'),
              ),
            ],
          ),
        ],
        body: RefreshIndicator(
          color: NeonPulse.primary,
          backgroundColor: NeonPulse.surfaceHigh,
          onRefresh: () =>
              ref.read(feedControllerProvider.notifier).loadFeed(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Stories
              const SliverToBoxAdapter(child: StoriesRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              // Daily check-in
              const SliverToBoxAdapter(child: DailyCheckinCard()),

              // Hall of Fame leaderboard
              const SliverToBoxAdapter(child: LeaderboardStrip()),

              // Profile nudge
              if (setupItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _ProfileNudge(
                        setupItems: setupItems, profileState: profileState),
                  ),
                ),

              // Live Now header
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Live Now',
                  dotColor: NeonPulse.error,
                  topPadding: 20,
                  trailing: TextButton(
                    onPressed: () => context.go('/rooms'),
                    child: const Text('See all',
                        style: TextStyle(
                            color: NeonPulse.primary, fontSize: 13)),
                  ),
                ),
              ),

              // Live rooms horizontal strip
              SliverToBoxAdapter(
                child: roomsAsync.when(
                  data: (rooms) => rooms.isEmpty
                      ? const _EmptyPill(label: 'No live rooms right now')
                      : SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: rooms.length.clamp(0, 12),
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) => LiveRoomCard(
                              room: rooms[i],
                              onTap: () => _openRoom(rooms[i].id),
                            ),
                          ),
                        ),
                  loading: () =>
                      const _HorizontalSkeleton(height: 200),
                  error: (e, _) => const _ErrorCard(message: 'Could not load live rooms'),
                ),
              ),

              // Top Creators
              if (trendingUsersAsync.value?.isNotEmpty == true ||
                  trendingUsersAsync.isLoading) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Top Creators',
                    dotColor: NeonPulse.secondary,
                    topPadding: 24,
                    trailing: TextButton(
                      onPressed: () => context.go('/discover'),
                      child: const Text('Discover',
                          style: TextStyle(
                              color: NeonPulse.primary, fontSize: 13)),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: trendingUsersAsync.when(
                    data: (users) => SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: users.length.clamp(0, 12),
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, i) => _CreatorChip(
                              user: users[i],
                              onTap: () => _openProfile(users[i].id),
                            ),
                          ),
                        ),
                    loading: () => const _HorizontalSkeleton(height: 88),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ],

              // New Members
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'New Members',
                    dotColor: NeonPulse.primary,
                  topPadding: 24,
                ),
              ),
              SliverToBoxAdapter(
                child: newMembersAsync.when(
                  data: (members) => members.isEmpty
                      ? const _EmptyPill(label: 'No new members yet')
                      : SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: members.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 16),
                            itemBuilder: (ctx, i) => _NewMemberChip(
                              user: members[i],
                              onTap: () => _openProfile(members[i].id),
                            ),
                          ),
                        ),
                  loading: () => const _HorizontalSkeleton(height: 88),
                  error: (_, _) =>
                      const _ErrorCard(message: 'Could not load new members'),
                ),
              ),

              // Recent Posts header
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent Posts',
                  dotColor: NeonPulse.primary,
                  topPadding: 24,
                ),
              ),

              // Posts feed
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EmptyPill(
                          label: 'No posts yet — follow someone!'),
                    );
                  }
                  final capped = posts.take(30).toList();
                  return SliverList.builder(
                    itemCount: capped.length,
                    itemBuilder: (ctx, i) => PostCard(
                      post: capped[i],
                      currentUserId: currentUser?.id ?? '',
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: NeonPulse.primary)),
                  ),
                ),
                error: (e, _) => const SliverToBoxAdapter(child: _ErrorCard(message: 'Could not load posts')),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats bar (online count + live rooms count) shown in the AppBar actions
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBarWidget extends StatelessWidget {
  final AsyncValue<int> onlineAsync;
  final AsyncValue<int> liveAsync;

  const _StatsBarWidget(
      {required this.onlineAsync, required this.liveAsync});

  @override
  Widget build(BuildContext context) {
    final online = onlineAsync.valueOrNull ?? 0;
    final live = liveAsync.valueOrNull ?? 0;
    return Row(
      children: [
        _StatPill(
          dot: NeonPulse.primary,
          label: online >= 500 ? '500+' : '$online',
          tooltip: 'online now',
        ),
        const SizedBox(width: 6),
        _StatPill(
          dot: NeonPulse.error,
          label: '$live',
          tooltip: 'live rooms',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final Color dot;
  final String label;
  final String tooltip;
  const _StatPill(
      {required this.dot, required this.label, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: NeonPulse.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NeonPulse.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: NeonPulse.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header with coloured left bar
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color dotColor;
  final double topPadding;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.dotColor,
    this.topPadding = 0,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: NeonPulse.onSurface,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Creator chip: avatar + username + gradient ring
// ─────────────────────────────────────────────────────────────────────────────

class _CreatorChip extends StatelessWidget {
  final feed_user.User user;
  final VoidCallback onTap;
  const _CreatorChip({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: NeonPulse.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: NeonPulse.surfaceHigh,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(user.avatarUrl)
                  : null,
              child: user.avatarUrl.isEmpty
                  ? Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: NeonPulse.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              user.username,
              style: const TextStyle(
                  fontSize: 10,
                  color: NeonPulse.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Member chip: avatar + username + "NEW" badge
// ─────────────────────────────────────────────────────────────────────────────

class _NewMemberChip extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _NewMemberChip({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeonPulse.primary.withValues(alpha: 0.25),
                  border: Border.all(
                      color: NeonPulse.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: NeonPulse.surfaceHigh,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: NeonPulse.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18),
                        )
                      : null,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: NeonPulse.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: NeonPulse.surface),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              user.username,
              style: const TextStyle(
                  fontSize: 10, color: NeonPulse.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile nudge banner
// ─────────────────────────────────────────────────────────────────────────────

/// Maps the first incomplete nudge item to the edit-profile tab index:
/// 0 = Basics (name / avatar), 1 = About (bio), 2 = Interests
int _nudgeTab(List<String> items) {
  if (items.isEmpty) return 0;
  final first = items.first;
  if (first == 'Write a short bio') return 1;
  if (first == 'Add interests') return 2;
  return 0;
}

class _ProfileNudge extends StatelessWidget {
  final List<String> setupItems;
  final dynamic profileState;
  const _ProfileNudge(
      {required this.setupItems, required this.profileState});

  @override
  Widget build(BuildContext context) {
    final pct =
      (ProfileCompletion.homeNudgeCompleteness(profileState) * 100).round();
    final isAlmostDone = pct >= 70;
    final Color accent =
        isAlmostDone ? NeonPulse.secondary : NeonPulse.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          final tab = _nudgeTab(setupItems);
          context.go('/edit-profile?tab=$tab');
        },
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: NeonPulse.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAlmostDone
                          ? 'Almost there!'
                          : 'Complete your profile',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent),
                    ),
                    Text(
                      '${setupItems.length} step${setupItems.length == 1 ? '' : 's'} left',
                      style: const TextStyle(
                          fontSize: 11,
                          color: NeonPulse.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: NeonPulse.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create menu with NeonPulse bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

void _showCreateMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: NeonPulse.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Wrap(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: NeonPulse.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined,
              color: NeonPulse.primary),
          title: const Text('New Post',
              style: TextStyle(color: NeonPulse.onSurface)),
          onTap: () {
            Navigator.pop(context);
            context.go('/create-post');
          },
        ),
        ListTile(
          leading: const Icon(Icons.auto_stories_outlined,
              color: NeonPulse.secondary),
          title: const Text('New Story',
              style: TextStyle(color: NeonPulse.onSurface)),
          onTap: () {
            Navigator.pop(context);
            context.go('/create-story');
          },
        ),
        ListTile(
          leading: const Icon(Icons.meeting_room_outlined,
              color: NeonPulse.primaryDim),
          title: const Text('Browse Rooms',
              style: TextStyle(color: NeonPulse.onSurface)),
          onTap: () {
            Navigator.pop(context);
            context.go('/rooms');
          },
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state pill
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPill extends StatelessWidget {
  final String label;
  const _EmptyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: NeonPulse.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(
                color: NeonPulse.onSurfaceVariant, fontSize: 13)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline error card
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: NeonPulse.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: NeonPulse.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                size: 16, color: NeonPulse.error),
            const SizedBox(width: 8),
            Text(message,
                style: const TextStyle(
                    fontSize: 12, color: NeonPulse.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal skeleton loader
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalSkeleton extends StatelessWidget {
  final double height;
  const _HorizontalSkeleton({this.height = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: height < 100 ? 60 : 140,
          height: height,
          decoration: BoxDecoration(
            color: NeonPulse.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
