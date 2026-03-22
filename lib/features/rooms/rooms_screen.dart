import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../features/feed/providers/feed_providers.dart';

import '../../presentation/screens/create_room_screen.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Rooms')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CreateRoomScreen()),
        ),
        tooltip: 'Create Live Room',
        child: const Icon(Icons.add),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          final liveRooms = rooms.where((r) => r.isLive == true).toList();
          if (liveRooms.isEmpty) {
            return const Center(child: Text('No live rooms available.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: liveRooms.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final room = liveRooms[i];
              return ListTile(
                leading: const Icon(Icons.meeting_room, color: Colors.blue),
                title: Text(room.name),
                subtitle: Text(room.description ?? ''),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveRoomScreen(roomId: room.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
