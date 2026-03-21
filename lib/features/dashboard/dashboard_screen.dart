import 'package:flutter/material.dart';
import '../../shared/widgets/TopAppBar.dart';
import '../../shared/widgets/BottomNavBar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/models/post_model.dart';
import '../../models/room_model.dart';
import '../home/home_screen.dart' show midnightErrorCard, _postCard, _roomCard, _eventCard; // reuse cards


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBar(title: 'MixVy'),
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
          // Discover Tab
          Center(child: Text('Discover', style: TextStyle(fontSize: 24))),
          // Profile Tab
          Center(child: Text('Profile', style: TextStyle(fontSize: 24))),
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
}
