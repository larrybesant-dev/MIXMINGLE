import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/agora_service.dart';

class SpeedDatingScreen extends StatefulWidget {
  const SpeedDatingScreen({super.key});

  @override
  State<SpeedDatingScreen> createState() => _SpeedDatingScreenState();
}

class _SpeedDatingScreenState extends State<SpeedDatingScreen> {
  // Matchmaking and video call logic
  AgoraService? _agora;
  bool _inCall = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> joinRoom() async {
    final roomRef = FirebaseFirestore.instance.collection('speed_dating_rooms').doc('room1');
    await roomRef.set({'participants': FieldValue.increment(1)}, SetOptions(merge: true));
    _agora = AgoraService();
    _agora!.onRemoteUserJoined = () => setState(() {});
    _agora!.onRemoteUserLeft = () => setState(() {});
    await _agora!.initialize('YOUR_AGORA_APP_ID'); // TODO: Replace with secure App ID
    await _agora!.joinChannel('YOUR_TOKEN', 'room1', 0); // TODO: Replace with secure token
    setState(() {
      _inCall = true;
    });
  }

  Future<void> leaveRoom() async {
    await _agora?.leaveChannel();
    setState(() {
      _inCall = false;
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
                onPressed: joinRoom,
                child: Text('Join Room', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
              ),
            ),
          if (_inCall && _agora != null)
            Expanded(
              child: Stack(
                children: [
                  // Remote video(s)
                  if (_agora!.remoteUids.isNotEmpty)
                    ..._agora!.remoteUids.map((uid) => Positioned.fill(child: _agora!.getRemoteView(uid))).toList()
                  else
                    Center(child: Text('Waiting for partner...')),
                  // Local video (small preview)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    width: 120,
                    height: 160,
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(8)),
                      child: _agora!.getLocalView(),
                    ),
                  ),
                  // Call controls
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white),
                          onPressed: () async {
                            setState(() => _muted = !_muted);
                            await _agora!.mute(_muted);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.red),
                          onPressed: leaveRoom,
                        ),
                      ],
                    ),
                  ),
                ],
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
