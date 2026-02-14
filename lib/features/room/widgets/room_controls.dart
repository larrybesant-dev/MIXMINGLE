import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/room_providers.dart';
import '../../../shared/models/room.dart';

class RoomControls extends ConsumerWidget {
  final Room room;
  final String currentUserId;
  final VoidCallback onEndRoom;
  final Function(bool) onLockRoom;
  final VoidCallback onRaiseHand;
  final bool isListener;
  final bool hasRaisedHand;

  const RoomControls({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onEndRoom,
    required this.onLockRoom,
    required this.onRaiseHand,
    required this.isListener,
    required this.hasRaisedHand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(room.id));
    return roomAsync.when(
      data: (r) {
        final current = r ?? room;
        final isHost = current.hostId == currentUserId;
        final isMod = current.moderators.contains(currentUserId) || current.admins.contains(currentUserId);

        return Row(
          children: [
            // Sprint 2: Lock room toggle (host only)
            if (isHost)
              Tooltip(
                message: current.isRoomLocked ? 'Unlock room' : 'Lock room',
                child: IconButton(
                  onPressed: () => onLockRoom(!current.isRoomLocked),
                  icon: Icon(
                    current.isRoomLocked ? Icons.lock : Icons.lock_open,
                    color: current.isRoomLocked ? Colors.amber : Colors.white70,
                  ),
                  tooltip: '🔒 Lock',
                ),
              ),
            if (isHost)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: onEndRoom,
                icon: const Icon(Icons.stop_circle),
                label: const Text('End Room'),
              ),
            if (isListener && !hasRaisedHand)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                  onPressed: onRaiseHand,
                  icon: const Icon(Icons.pan_tool_alt_outlined),
                  label: const Text('Raise Hand'),
                ),
              ),
            if ((isHost || isMod) && !isListener)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  label: const Text('Speaker Mode', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
