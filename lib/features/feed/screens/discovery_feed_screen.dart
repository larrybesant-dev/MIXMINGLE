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
  const DiscoveryFeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Feed'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Builder(
        builder: (context) {
          if (feedState.isLoading) {
            return const FeedLoadingShimmer();
          }
          if (feedState.error != null) {
            return Center(
              child: Text(
                feedState.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (feedState.liveRooms.isEmpty && feedState.trendingUsers.isEmpty) {
            return const FeedEmptyState(message: 'No live rooms or trending users right now.');
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feedControllerProvider.notifier).loadFeed(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live Rooms Section
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
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final room = feedState.liveRooms[index];
                        return LiveRoomCard(room: room, onTap: () {
                          // Navigate to room detail
                          context.go('/room/${room.id}');
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Trending Users Section
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
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final user = feedState.trendingUsers[index];
                        return TrendingUserCard(user: user, onTap: () {
                          // Navigate to user profile
                          context.go('/profile/${user.id}');
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }
}
