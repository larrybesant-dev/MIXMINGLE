import 'package:flutter/material.dart';
import '../../shared/widgets/top_app_bar.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/screens/discovery_feed_screen.dart';
import '../feed/models/post_model.dart';
import '../profile/profile_screen.dart';
import '../../widgets/mixvy_drawer.dart';

import '../../models/room_model.dart';
import '../feed/models/event_model.dart';


  class DashboardScreen extends StatefulWidget {
    const DashboardScreen({super.key});

    @override
    State<DashboardScreen> createState() => _DashboardScreenState();
  }

  class _DashboardScreenState extends State<DashboardScreen> {
    int _currentIndex = 0;

    @override
    Widget build(BuildContext context) {
      const titles = ['MixVy', 'Discover', 'Profile'];

      return Scaffold(
        appBar: TopAppBar(title: titles[_currentIndex]),
        drawer: const MixVyDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Home Feed Tab
            Consumer(
              builder: (context, ref, _) {
                final postsAsync = ref.watch(postsStreamProvider);
                final roomsAsync = ref.watch(roomsStreamProvider);
                final eventsAsync = ref.watch(eventsStreamProvider);
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
              },
            ),
            const DiscoveryFeedContent(),
            const ProfileFormView(),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      );
    }

    // Card widget for posts
    Widget _postCard(PostModel p) => Card(
          child: ListTile(
            title: Text(p.text),
            subtitle: Text('Posted • ${p.createdAt}'),
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
                const SizedBox(width: 12),
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
            title: Text(r.name.isNotEmpty ? r.name : 'Room'),
            subtitle: const Text('Live room'),
            trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
          ),
        );

    // Card widget for events (dynamic fallback)
    Widget _eventCard(dynamic e) => Card(
          child: ListTile(
            title: e is EventModel
                ? Text(e.title.toString().trim().isNotEmpty ? e.title : 'Event')
                : Text(e.toString()),
            subtitle: e is EventModel ? Text('Event • ${e.date}') : null,
          ),
        );
  }
