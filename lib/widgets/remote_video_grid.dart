// lib/widgets/remote_video_grid.dart

import 'package:flutter/material.dart';
import '../models/participant_model.dart';
import 'remote_video_tile.dart';

class RemoteVideoGrid extends StatelessWidget {
  final List<ParticipantModel> participants;
  final String localUid;

  const RemoteVideoGrid({
    super.key,
    required this.participants,
    required this.localUid,
  });

  @override
  Widget build(BuildContext context) {
    final remoteParticipants = participants.where((p) => p.uid != localUid).toList();
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final tileCount = remoteParticipants.length;
    int crossAxisCount;
    if (isWide) {
      crossAxisCount = tileCount > 6 ? 6 : tileCount;
    } else if (isTablet) {
      crossAxisCount = tileCount > 3 ? 3 : tileCount;
    } else {
      crossAxisCount = tileCount > 2 ? 2 : tileCount;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: GridView.builder(
        key: ValueKey(tileCount),
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isWide ? 1.4 : isTablet ? 1.2 : 1.0,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
        ),
        itemCount: tileCount,
        itemBuilder: (context, idx) {
          final p = remoteParticipants[idx];
          return RemoteVideoTile(participant: p);
        },
      ),
    );
  }
}
