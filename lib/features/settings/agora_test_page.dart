import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../providers/all_providers.dart';
import '../../core/constants.dart';

/// Test page for Agora video functionality
/// This page allows testing video calling without full room setup
class AgoraTestPage extends ConsumerStatefulWidget {
  const AgoraTestPage({super.key});

  @override
  ConsumerState<AgoraTestPage> createState() => _AgoraTestPageState();
}

class _AgoraTestPageState extends ConsumerState<AgoraTestPage> {
  final TextEditingController _channelController = TextEditingController();
  bool _isJoined = false;
  bool _isLoading = false;
  String _statusMessage = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _channelController.text = 'test_channel_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  Future<void> _testAgoraConnection() async {
    if (_channelController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a channel name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing Agora...';
    });

    try {
      final agoraService = ref.read(agoraVideoServiceProvider);

      // Initialize engine if needed
      if (!agoraService.isInitialized) {
        setState(() {
          _statusMessage = 'Initializing Agora engine...';
        });
        await agoraService.initialize();
      }

      // Test joining channel
      setState(() {
        _statusMessage = 'Joining channel...';
      });

      await agoraService.joinChannel(_channelController.text.trim());

      setState(() {
        _isJoined = true;
        _statusMessage = 'Successfully joined channel!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      debugPrint('Agora test error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveChannel() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Leaving channel...';
    });

    try {
      final agoraService = ref.read(agoraVideoServiceProvider);
      await agoraService.leaveChannel();
      agoraService.dispose();

      setState(() {
        _isJoined = false;
        _statusMessage = 'Left channel successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error leaving channel: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora Video Test'), backgroundColor: const Color(0xFF1E1E2F)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isJoined ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isJoined ? Colors.green : Colors.blue, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${_isJoined ? 'Connected' : 'Disconnected'}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _isJoined ? Colors.green : Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agora App ID: ${AppConstants.agoraAppId}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(_statusMessage, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Video preview (only show when connected)
            if (_isJoined) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: ref.read(agoraVideoServiceProvider).engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(agoraVideoServiceProvider).toggleMic();
                        if (mounted) {
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(content: Text('Failed to toggle mic: $e')));
                        }
                      }
                    },
                    icon: Icon(ref.watch(agoraVideoServiceProvider).isMicMuted ? Icons.mic_off : Icons.mic),
                    label: Text(ref.watch(agoraVideoServiceProvider).isMicMuted ? 'Unmute' : 'Mute'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(agoraVideoServiceProvider).toggleVideo();
                        if (mounted) {
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(content: Text('Failed to toggle camera: $e')));
                        }
                      }
                    },
                    icon: Icon(ref.watch(agoraVideoServiceProvider).isVideoMuted ? Icons.videocam_off : Icons.videocam),
                    label: Text(ref.watch(agoraVideoServiceProvider).isVideoMuted ? 'Camera On' : 'Camera Off'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Channel input
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(
                labelText: 'Test Channel Name',
                border: OutlineInputBorder(),
                helperText: 'Enter a unique channel name for testing',
              ),
              enabled: !_isJoined,
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (!_isJoined) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _testAgoraConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4C4C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test Agora Connection'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _leaveChannel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Leave Channel'),
              ),
            ],

            const SizedBox(height: 24),

            // Instructions
            const Text('Testing Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              '1. Make sure you have valid Agora credentials in constants.dart\n'
              '2. Deploy Firebase Functions with updated environment variables\n'
              '3. Enter a unique channel name\n'
              '4. Click "Test Agora Connection"\n'
              '5. Check the status messages for any errors\n'
              '6. If successful, you should be able to join the channel',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // Troubleshooting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.withValues(alpha: 0.3), width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Troubleshooting:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellow),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'â€¢ Check Firebase Functions logs: firebase functions:log\n'
                    'â€¢ Verify Agora credentials are correct\n'
                    'â€¢ Ensure Firebase Functions are deployed\n'
                    'â€¢ Check device permissions for camera/microphone',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
