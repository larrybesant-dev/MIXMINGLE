import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_room_service.dart';

class AudioRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  const AudioRoomPage({required this.roomId, super.key});

  @override
  ConsumerState<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends ConsumerState<AudioRoomPage> {
  late AudioRoomService service;
  List<MicQueueEntry> micQueue = [];
  List<String> speakers = [];

  @override
  void initState() {
    super.initState();
    service = AudioRoomService(widget.roomId);
    _loadQueue();
    _loadSpeakers();
  }

  Future<void> _loadQueue() async {
    micQueue = await service.getMicQueue();
    setState(() {});
  }

  Future<void> _loadSpeakers() async {
    speakers = await service.getActiveSpeakers();
    setState(() {});
  }

  void _requestMic() async {
    final profile = ref.read(currentUserProfileProvider);
    await service.requestMic(profile.uid);
    await _loadQueue();
  }

  void _grantMic(String uid) async {
    await service.grantMic(uid);
    await _loadQueue();
    await _loadSpeakers();
  }

  void _revokeMic(String uid) async {
    await service.revokeMic(uid);
    await _loadQueue();
    await _loadSpeakers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Room')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _requestMic,
            child: const Text('Request Mic'),
          ),
          const SizedBox(height: 16),
          const Text('Mic Queue:'),
          ...micQueue.map((entry) => ListTile(
                title: Text(entry.userId),
                subtitle: Text(entry.granted ? 'Granted' : 'Waiting'),
                trailing: speakers.contains(entry.userId)
                    ? ElevatedButton(
                        onPressed: () => _revokeMic(entry.userId),
                        child: const Text('Revoke'),
                      )
                    : ElevatedButton(
                        onPressed: () => _grantMic(entry.userId),
                        child: const Text('Grant'),
                      ),
              )),
          const SizedBox(height: 16),
          const Text('Active Speakers:'),
          ...speakers.map((userId) => ListTile(title: Text(userId))),
        ],
      ),
    );
  }
}
