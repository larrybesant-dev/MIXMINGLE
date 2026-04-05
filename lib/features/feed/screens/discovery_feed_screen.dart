import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/feed_controller.dart';
import '../models/post_model.dart';
import '../providers/following_feed_provider.dart';
import '../widgets/post_card.dart';
import 'package:go_router/go_router.dart';
import '../widgets/live_room_card.dart';
import '../widgets/trending_user_card.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/feed_loading_shimmer.dart';
import '../../stories/widgets/stories_row.dart';
import '../../ads/ad_manager.dart';
import '../../../features/profile/profile_controller.dart';

class DiscoveryFeedScreen extends ConsumerWidget {
  const DiscoveryFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discovery Feed'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Discover'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DiscoveryFeedContent(),
            _FollowingFeedTab(),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class DiscoveryFeedContent extends ConsumerStatefulWidget {
  const DiscoveryFeedContent({super.key});

  @override
  ConsumerState<DiscoveryFeedContent> createState() =>
      _DiscoveryFeedContentState();
}

class _DiscoveryFeedContentState extends ConsumerState<DiscoveryFeedContent> {
  static const List<({String label, String? value})> _categories = [
    (label: 'All', value: null),
    (label: '🎵 Music', value: 'music'),
    (label: '💬 Talk', value: 'talk'),
    (label: '🎮 Gaming', value: 'gaming'),
    (label: '💃 Dance', value: 'dance'),
    (label: '❤️ Dating', value: 'dating'),
    (label: '📚 Study', value: 'study'),
    (label: '🎨 Art', value: 'art'),
  ];

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);

    return Builder(
      builder: (context) {
        if (feedState.isLoading) {
          return const FeedLoadingShimmer();
        }
        if (!feedState.isLoading &&
            feedState.error == null &&
            feedState.liveRooms.isEmpty &&
            feedState.trendingUsers.isEmpty) {
          Future.microtask(() => ref.read(feedControllerProvider.notifier).loadFeed());
        }
        if (feedState.error != null) {
          return RefreshIndicator(
            onRefresh: () => ref.read(feedControllerProvider.notifier).loadFeed(),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 38, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 10),
                      Text(
                        feedState.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => ref.read(feedControllerProvider.notifier).loadFeed(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (feedState.liveRooms.isEmpty && feedState.trendingUsers.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(feedControllerProvider.notifier).loadFeed(),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FeedEmptyState(message: 'No live rooms or trending users right now.'),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => context.go('/speed-dating'),
                        icon: const Icon(Icons.local_fire_department_rounded),
                        label: const Text('Try Speed Dating'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(feedControllerProvider.notifier).loadFeed(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stories row — always visible at top
              const StoriesRow(),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.explore),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Swipe through live rooms and trending users to find your next connection.'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/friends'),
                        child: const Text('Friends'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category filter chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, idx) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat.value;
                    return FilterChip(
                      label: Text(cat.label),
                      selected: selected,
                      onSelected: (_) => setState(
                        () => _selectedCategory = cat.value,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (feedState.liveRooms.isNotEmpty) ...[
                Text(
                  'Live Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                Builder(builder: (ctx) {
                  final filteredRooms = _selectedCategory == null
                      ? feedState.liveRooms
                      : feedState.liveRooms
                          .where((r) =>
                              r.category?.toLowerCase() ==
                              _selectedCategory)
                          .toList();
                  if (filteredRooms.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No live rooms in this category right now.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  return SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredRooms.length,
                      separatorBuilder: (_, idx2) => const SizedBox(width: 16),
                      itemBuilder: (ctx2, index) {
                        final room = filteredRooms[index];
                        return LiveRoomCard(
                          room: room,
                          recommendationTier: feedState.roomTiers[room.id],
                          recommendationReason: feedState.roomReasons[room.id],
                          onTap: () => context.go('/room/${room.id}'),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
              // ── Promo banner — shown only for free-tier users ──────────
              Builder(builder: (ctx) {
                final profileMembership = ref
                    .watch(profileControllerProvider
                        .select((s) => s.membershipLevel ?? 'Free'));
                if (!AdManager.shouldShowAds(profileMembership)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: Theme.of(ctx).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_outlined, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upgrade to MixVy Premium',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Remove ads and unlock exclusive features.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => ctx.go('/payments'),
                            child: const Text('Upgrade'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (feedState.trendingUsers.isNotEmpty) ...[
                Text(
                  'Trending Users',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: feedState.trendingUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final user = feedState.trendingUsers[index];
                      return TrendingUserCard(
                        user: user,
                        onTap: () => context.go('/profile/${user.id}'),
                      );
                    },
                  ),
                ),
              ],
              if (feedState.upcomingRooms.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      'Upcoming Rooms',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...feedState.upcomingRooms.map((room) {
                  final scheduledAt = room.scheduledAt?.toDate();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('📅', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      title: Text(room.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: scheduledAt == null
                          ? const Text('Scheduled')
                          : _RoomCountdown(scheduledAt: scheduledAt),
                      trailing: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Remind me'),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
  
}

class _FollowingFeedTab extends ConsumerWidget {
  const _FollowingFeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to see your following feed.'));
    }

    final feedAsync = ref.watch(followingFeedProvider(uid));

    return feedAsync.when(
      loading: () => const FeedLoadingShimmer(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (maps) {
        if (maps.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const FeedEmptyState(message: 'No posts yet from people you follow.'),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.person_search),
                  label: const Text('Find people to follow'),
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
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => PostCard(
            post: posts[i],
            currentUserId: uid,
          ),
        );
      },
    );
  }
}

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
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final String label;
    if (_remaining.inSeconds < 600) {
      // < 10 minutes: show live ticking countdown
      final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      label = 'Going live in ${m}m ${s}s';
    } else if (_remaining.inHours < 24) {
      label = 'In ${_remaining.inHours}h ${_remaining.inMinutes.remainder(60)}m';
    } else {
      label = 'In ${_remaining.inDays}d';
    }
    return Text(label);
  }
}
