import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: $roomId')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('rooms').doc(roomId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Room not found.'));
          }
          final room = RoomModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Host: ${room.hostId}'),
                if (room.description != null) ...[
                  const SizedBox(height: 8),
                  Text(room.description!),
                ],
                const SizedBox(height: 16),
                Text('Members: ${room.members.length}'),
                const SizedBox(height: 16),
                Text('Created: ${room.createdAt.toLocal()}'),
                const SizedBox(height: 16),
                Text(room.isLive ? 'Status: Live' : 'Status: Offline', style: TextStyle(color: room.isLive ? Colors.green : Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
