// lib/screens/replay_list_screen.dart

import 'package:flutter/material.dart';
import '../services/recording_service.dart';

class ReplayListScreen extends StatelessWidget {
  const ReplayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingService = RecordingService();
    final sessions = recordingService.getSessions();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replays'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, idx) {
          final session = sessions[idx];
          return ListTile(
            title: Text('Room: ${session.roomId}'),
            subtitle: Text('Started: ${session.startedAt}'),
            trailing: session.endedAt != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.fiber_manual_record, color: Colors.red),
          );
        },
      ),
    );
  }
}
