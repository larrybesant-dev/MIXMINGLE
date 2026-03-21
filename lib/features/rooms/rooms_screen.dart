import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/feed/providers/feed_providers.dart';
// import '../../models/room_model.dart'; // Removed unused import
import '../../widgets/room_tile.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: roomsAsync.when(
        data: (rooms) => rooms.isEmpty
            ? const Center(child: Text('No rooms available.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final room = rooms[i];
                  return RoomTile(
                    roomName: room.name,
                    onTap: () {
                      // TODO: Navigate to room detail or join logic
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
