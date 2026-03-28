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

class DiscoveryFeedContent extends ConsumerWidget {
  const DiscoveryFeedContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return Center(
            child: Padding(
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
          );
        }
        if (feedState.liveRooms.isEmpty && feedState.trendingUsers.isEmpty) {
          return Center(
            child: Padding(
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
              if (feedState.liveRooms.isNotEmpty) ...[
                Text(
                  'Live Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: feedState.liveRooms.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final room = feedState.liveRooms[index];
                      return LiveRoomCard(
                        room: room,
                        onTap: () => context.go('/room/${room.id}'),
                      );
                    },
                  ),
                ),
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
            ],
          ),
        );
      },
    );
  }
}
