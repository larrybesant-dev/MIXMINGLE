import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/room_providers.dart';
import '../../../shared/models/room.dart';

class RaisedHandsPanel extends ConsumerWidget {
  final Room room;
  final String currentUserId;
  final void Function(String userId) onApprove;
  final void Function(String userId) onDecline;

  const RaisedHandsPanel({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onApprove,
    required this.onDecline,
  });

  bool _canModerate(Room r) =>
      r.hostId == currentUserId || r.moderators.contains(currentUserId) || r.admins.contains(currentUserId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handsAsync = ref.watch(raisedHandsProvider(room.id));
    final roomAsync = ref.watch(roomStreamProvider(room.id));

    return roomAsync.when(
      data: (r) {
        final canModerate = r != null ? _canModerate(r) : _canModerate(room);
        return handsAsync.when(
          data: (hands) {
            if (hands.isEmpty) {
              return const SizedBox.shrink();
            }
            return _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raised Hands', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...hands.map((uid) => _handTile(uid, canModerate)),
                ],
              ),
            );
          },
          loading: () => _panel(
            child: const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
          ),
          error: (e, _) => _panel(
            child: Text('Error loading raised hands: $e', style: const TextStyle(color: Colors.white70)),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _handTile(String uid, bool canModerate) {
    return Card(
      color: const Color(0xFF2A2A3D),
      child: ListTile(
        dense: true,
        title: Text(uid, style: const TextStyle(color: Colors.white)),
        trailing: canModerate
            ? Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.greenAccent, size: 18),
                    onPressed: () => onApprove(uid),
                    tooltip: 'Approve (promote to speaker)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    onPressed: () => onDecline(uid),
                    tooltip: 'Decline',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}
