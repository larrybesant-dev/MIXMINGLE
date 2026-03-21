import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with real room list from provider
    final rooms = [
      {'name': 'Room 1', 'isLive': true},
      {'name': 'Room 2', 'isLive': false},
      {'name': 'Room 3', 'isLive': true},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final room = rooms[i];
          return ListTile(
            leading: Icon(room['isLive'] ? Icons.videocam : Icons.meeting_room),
            title: Text(room['name'] as String),
            subtitle: Text(room['isLive'] ? 'Live' : 'Offline'),
            trailing: ElevatedButton(
              onPressed: room['isLive'] ? () {} : null,
              child: const Text('Join'),
            ),
          );
        },
      ),
    );
  }
}
