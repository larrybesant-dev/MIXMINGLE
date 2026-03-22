import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/models/post_model.dart';
import '../../models/room_model.dart';
import 'package:mixvy/models/models.dart';
import 'package:go_router/go_router.dart';

final _bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);
    final selectedIndex = ref.watch(_bottomNavIndexProvider);
    final List<Widget> pages = [
      _HomeFeedBody(postsAsync: postsAsync, roomsAsync: roomsAsync, eventsAsync: eventsAsync),
      const _RoomsScreen(),
      const _EventsScreen(),
      const _ProfileScreen(),
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

class _RoomsScreen extends ConsumerWidget {
  const _RoomsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: roomsAsync.when(
          data: (rooms) => rooms.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.meeting_room, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No active rooms. Create one to get started!'),
                  ],
                )
              : ListView(
                  children: rooms.map((r) => _roomCard(r)).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => midnightErrorCard('Error: $e'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
        onPressed: () {
          // TODO: Implement room creation dialog
        },
      ),
    );
  }
}

class _EventsScreen extends ConsumerWidget {
  const _EventsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: eventsAsync.when(
          data: (events) => events.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No upcoming events. Check back soon!'),
                  ],
                )
              : ListView(
                  children: events.map((e) => _eventCard(e)).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => midnightErrorCard('Error: $e'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
        onPressed: () {
          // TODO: Implement event creation dialog
        },
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Profile details coming soon!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement sign out
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFeedBody extends StatelessWidget {
  final AsyncValue<List<PostModel>> postsAsync;
  final AsyncValue<List<RoomModel>> roomsAsync;
  final AsyncValue<List<dynamic>> eventsAsync;

  const _HomeFeedBody({
    required this.postsAsync,
    required this.roomsAsync,
    required this.eventsAsync,
  });

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
                ? Column(
                    children: const [
                      Icon(Icons.forum, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No posts yet. Start the conversation!'),
                    ],
                  )
                : Column(children: posts.map((p) => _postCard(p)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => midnightErrorCard('Error: $e'),
          ),
          const SizedBox(height: 24),
          const Text('Active Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          roomsAsync.when(
            data: (rooms) => rooms.isEmpty
                ? Column(
                    children: const [
                      Icon(Icons.meeting_room, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No active rooms. Create one to get started!'),
                    ],
                  )
                : Column(children: rooms.map((r) => _roomCard(r)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => midnightErrorCard('Error: $e'),
          ),
          const SizedBox(height: 24),
          const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          eventsAsync.when(
            data: (events) => events.isEmpty
                ? Column(
                    children: const [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No upcoming events. Check back soon!'),
                    ],
                  )
                : Column(children: events.map((e) => _eventCard(e)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => midnightErrorCard('Error: $e'),
          ),
        ],
      ),
    );
  }
}

Widget _postCard(PostModel p) => Card(
      child: ListTile(
        title: Text(p.text),
        subtitle: Text('by ${p.userId} • ${p.createdAt}'),
      ),
    );

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

Widget _roomCard(RoomModel r) => Card(
      child: ListTile(
        title: Text(r.name.isNotEmpty ? r.name : 'Untitled Room'),
        subtitle: Text('Host: ${r.hostId}'),
        trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
      ),
    );

Widget _eventCard(dynamic e) => Card(
      child: ListTile(
        title: e is EventModel
            ? Text(e.title.isNotEmpty == true ? e.title : 'Untitled Event')
            : Text(e.toString()),
        subtitle: e is EventModel ? Text('Host: ${e.hostId} • ${e.date}') : null,
      ),
    );
