

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/models/post_model.dart';
import '../../models/room_model.dart';
import 'package:mixvy/models/models.dart';

import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    // Track the selected index for navigation
    final selectedIndex = ref.watch(_bottomNavIndexProvider);

    // List of widgets for each tab
    final List<Widget> pages = [
      _HomeFeedBody(postsAsync: postsAsync, roomsAsync: roomsAsync, eventsAsync: eventsAsync),
      // Placeholder widgets for other tabs
      const Center(child: Text('Rooms')), // TODO: Replace with actual Rooms screen
      const Center(child: Text('Events')), // TODO: Replace with actual Events screen
      const Center(child: Text('Profile')), // TODO: Replace with actual Profile screen
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => ref.read(_bottomNavIndexProvider.notifier).state = 3,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.go('/chats'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
        onPressed: () {},
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int idx) => ref.read(_bottomNavIndexProvider.notifier).state = idx,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Rooms'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

}

// Provider to track the selected bottom nav index
final _bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Extracted body for Home tab
class _HomeFeedBody extends StatelessWidget {
  final AsyncValue<List<PostModel>> postsAsync;
  final AsyncValue<List<RoomModel>> roomsAsync;
  final AsyncValue<List<dynamic>> eventsAsync;

  const _HomeFeedBody({
    required this.postsAsync,
    required this.roomsAsync,
    required this.eventsAsync,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          postsAsync.when(
            data: (posts) => posts.isEmpty
                ? const Text('No posts yet.')
                : Column(children: posts.map((p) => _postCard(p)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => midnightErrorCard('Error: $e'),
          ),
          const SizedBox(height: 24),
          const Text('Active Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          roomsAsync.when(
            data: (rooms) => rooms.isEmpty
                ? const Text('No active rooms.')
                : Column(children: rooms.map((r) => _roomCard(r)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => midnightErrorCard('Error: $e'),
          ),
          const SizedBox(height: 24),
          const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          eventsAsync.when(
            data: (events) => events.isEmpty
                ? const Text('No upcoming events.')
                : Column(children: events.map((e) => _eventCard(e)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

// Card widget for posts
Widget _postCard(PostModel p) => Card(
      child: ListTile(
        title: Text(p.text),
        subtitle: Text('by ${p.userId} • ${p.createdAt}'),
      ),
    );

// Midnight Error Card pattern
Widget midnightErrorCard(String message) => Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.redAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

// Card widget for rooms
Widget _roomCard(RoomModel r) => Card(
      child: ListTile(
        title: Text(r.name ?? 'Room'),
        subtitle: Text('Host: ${r.hostId}'),
        trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
      ),
    );

// Card widget for events (dynamic fallback)
Widget _eventCard(dynamic e) => Card(
      child: ListTile(
        title: Text(e is EventModel ? (e.title ?? 'Event') : e.toString()),
        subtitle: e is EventModel ? Text('Host: ${e.hostId} • ${e.date}') : null,
      ),
    );
