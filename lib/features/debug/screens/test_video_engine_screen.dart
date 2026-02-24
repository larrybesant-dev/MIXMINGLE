import 'package:flutter/material.dart';
import '../../../services/video_engine_service.dart';
import '../../../shared/models/remote_user.dart';

class TestVideoEngineScreen extends StatefulWidget {
  const TestVideoEngineScreen({super.key});

  @override
  State<TestVideoEngineScreen> createState() => _TestVideoEngineScreenState();
}

class _TestVideoEngineScreenState extends State<TestVideoEngineScreen> {
  final VideoEngineService _videoEngine = VideoEngineService();
  final TextEditingController _channelController = TextEditingController(text: 'testRoom');
  bool _joined = false;
  bool _audioMuted = false;
  bool _videoMuted = false;
  List<RemoteUser> _remoteUsers = [];

  @override
  void initState() {
    super.initState();
    _videoEngine.remoteUsersStream.listen((users) {
      setState(() => _remoteUsers = users);
    });
  }

  Future<void> _initEngine() async {
    try {
      await _videoEngine.init('YOUR_AGORA_APP_ID_HERE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video Engine Initialized')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _joinChannel() async {
    await _videoEngine.joinChannel(
      channel: _channelController.text,
      uid: DateTime.now().millisecondsSinceEpoch % 10000,
      token: '',
    );
    setState(() => _joined = true);
  }

  Future<void> _leaveChannel() async {
    await _videoEngine.leaveChannel();
    setState(() {
      _joined = false;
      _remoteUsers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Engine Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _channelController, decoration: const InputDecoration(labelText: 'Channel')),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: _initEngine, child: const Text('Init Engine')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _joined ? _leaveChannel : _joinChannel,
                  child: Text(_joined ? 'Leave Channel' : 'Join Channel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    _audioMuted = !_audioMuted;
                    await _videoEngine.setAudioMuted(_audioMuted);
                    setState(() {});
                  },
                  child: Text(_audioMuted ? 'Unmute Audio' : 'Mute Audio'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    _videoMuted = !_videoMuted;
                    await _videoEngine.setVideoMuted(_videoMuted);
                    setState(() {});
                  },
                  child: Text(_videoMuted ? 'Unmute Video' : 'Mute Video'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _remoteUsers.map((u) => ListTile(
                  title: Text('Remote UID: ${u.uid}'),
                  subtitle: Text('Video: ${u.videoEnabled} | Audio: ${u.audioEnabled}'),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
