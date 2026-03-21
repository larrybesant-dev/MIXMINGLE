

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/models/post_model.dart';
import '../feed/models/room_model.dart';
import '../../models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.pushNamed(context, '/chats'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
        onPressed: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            postsAsync.when(
              data: (posts) => posts.isEmpty
                  ? const Text('No posts yet.')
                  : Column(children: posts.map(_postCard).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            const Text('Active Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            roomsAsync.when(
              data: (rooms) => rooms.isEmpty
                  ? const Text('No active rooms.')
                  : Column(children: rooms.map(_roomCard).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            eventsAsync.when(
              data: (events) => events.isEmpty
                  ? const Text('No upcoming events.')
                  : Column(children: events.map(_eventCard).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postCard(PostModel p) {
    return Card(
      child: ListTile(
        title: Text(p.text),
        subtitle: Text('by ${p.userId} • ${p.createdAt}'),
      ),
    );
  }

  Widget _roomCard(RoomModel r) {
    return Card(
      child: ListTile(
        title: Text(r.title),
        subtitle: Text('Host: ${r.hostId}'),
        trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
      ),
    );
  }

  Widget _eventCard(EventModel e) {
    return Card(
      child: ListTile(
        title: Text(e.title),
        subtitle: Text('Host: ${e.hostId} • ${e.date}'),
      ),
    );
  }
}
