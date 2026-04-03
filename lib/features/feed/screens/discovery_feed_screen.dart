import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/feed_controller.dart';
// import '../../../models/room_model.dart'; // Unused import
// import '../../../models/user.dart'; // Unused import
import 'package:go_router/go_router.dart';
import '../widgets/live_room_card.dart';
import '../widgets/trending_user_card.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/feed_loading_shimmer.dart';

class DiscoveryFeedScreen extends ConsumerWidget {
  const DiscoveryFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Feed'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: const DiscoveryFeedContent(),
      backgroundColor: Theme.of(context).colorScheme.surface,
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
