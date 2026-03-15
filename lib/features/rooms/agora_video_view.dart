import 'package:flutter/material.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraVideoView extends StatelessWidget {
  final bool local;
  final int? remoteUid;
  const AgoraVideoView({super.key, required this.local, this.remoteUid});

  @override
  Widget build(BuildContext context) {
    // Replace with actual Agora video widget
    return Container(
      width: 100,
      height: 150,
      color: local ? Colors.blue : Colors.green,
      child: Center(
        child: Text(local ? 'Local Video' : 'Remote Video'),
      ),
    );
  }
}
