// lib/widgets/room_action_bar.dart
import 'package:flutter/material.dart';

class RoomActionBar extends StatelessWidget {
  final bool isMuted;
  final bool isCameraOn;
  final bool isScreenSharing;
  final VoidCallback onMuteToggle;
  final VoidCallback onCameraToggle;
  final VoidCallback? onScreenShare;
  final VoidCallback onLeave;
  final VoidCallback onSwitchCamera;

  const RoomActionBar({
    super.key,
    required this.isMuted,
    required this.isCameraOn,
    this.isScreenSharing = false,
    required this.onMuteToggle,
    required this.onCameraToggle,
    this.onScreenShare,
    required this.onLeave,
    required this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(isMuted ? Icons.mic_off : Icons.mic,
                color: isMuted ? Colors.red : Colors.white),
            onPressed: onMuteToggle,
          ),
          IconButton(
            icon: Icon(isCameraOn ? Icons.videocam : Icons.videocam_off,
                color: isCameraOn ? Colors.green : Colors.white),
            onPressed: onCameraToggle,
          ),
          IconButton(
            icon: Icon(Icons.screen_share,
                color: isScreenSharing ? Colors.blueAccent : Colors.white),
            onPressed: onScreenShare,
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera, color: Colors.white),
            onPressed: onSwitchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: onLeave,
          ),
        ],
      ),
    );
  }
}