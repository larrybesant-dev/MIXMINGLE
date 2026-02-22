// lib/screens/discovery_screen.dart

import 'package:flutter/material.dart';
import '../providers/room_discovery_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingRoomsProvider);
    final activeAsync = ref.watch(activeRoomsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Rooms'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Trending Rooms',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          trendingAsync.when(
            data: (rooms) => Column(
              children: rooms
                  .map((doc) => ListTile(
                        title: Text(doc.id,
                            style: const TextStyle(color: Colors.white70)),
                        leading: const Icon(Icons.trending_up,
                            color: Colors.deepPurpleAccent),
                      ))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),
          const Text('Active Rooms',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          activeAsync.when(
            data: (rooms) => Column(
              children: rooms
                  .map((doc) => ListTile(
                        title: Text(doc.id,
                            style: const TextStyle(color: Colors.white70)),
                        leading: const Icon(Icons.play_circle_fill,
                            color: Colors.green),
                      ))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
