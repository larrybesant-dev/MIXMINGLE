// lib/widgets/agora_video_preview.dart
import 'package:flutter/material.dart';

class AgoraVideoPreview extends StatelessWidget {
  final String channelName;
  final int uid;

  const AgoraVideoPreview({
    super.key,
    required this.channelName,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 64),
            const SizedBox(height: 8),
            Text(
              'Room: $channelName',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
