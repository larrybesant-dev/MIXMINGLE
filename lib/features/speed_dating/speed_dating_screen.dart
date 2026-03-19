import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/agora_service.dart';

class SpeedDatingScreen extends StatefulWidget {
  const SpeedDatingScreen({Key? key}) : super(key: key);

  @override
  State<SpeedDatingScreen> createState() => _SpeedDatingScreenState();
}

class _SpeedDatingScreenState extends State<SpeedDatingScreen> {
  // Matchmaking and video call logic
  AgoraService? _agora;
  bool _inCall = false;
  Future<void> joinRoom() async {
    final roomRef = FirebaseFirestore.instance.collection('speed_dating_rooms').doc('room1');
    await roomRef.set({'participants': FieldValue.increment(1)}, SetOptions(merge: true));
    _agora = AgoraService();
    await _agora!.initialize('YOUR_AGORA_APP_ID');
    await _agora!.joinChannel('YOUR_TOKEN', 'room1', 0);
    setState(() {
      _inCall = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Dating Room')),
      body: Column(
        children: [
          if (!_inCall)
            Semantics(
              label: 'Join Room button',
              button: true,
              child: ElevatedButton(
                child: Text('Join Room', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
                onPressed: joinRoom,
              ),
            ),
          if (_inCall)
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Video Call UI',
                  child: Text('Video Call UI Placeholder', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
                ),
                // Replace with Agora video widget if needed
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('speed_dating_rooms').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = (snapshot.data as QuerySnapshot).docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(docs[index]['roomName'] ?? 'Room'),
                    subtitle: Text('Participants: ${docs[index]['participants'] ?? 0}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
