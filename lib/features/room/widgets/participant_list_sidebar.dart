import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/room.dart';
import '../providers/room_subcollection_providers.dart';

class ParticipantListSidebar extends ConsumerWidget {
  final Room room;
  final String currentUserId;
  final void Function(String userId) onPromote;
  final void Function(String userId) onDemote;
  final void Function(String userId) onMakeModerator;
  final void Function(String userId) onRemoveModerator;
  final void Function(String userId) onKick;
  final void Function(String userId) onBan;
  final void Function(String userId) onMute;
  final void Function(String userId) onUnmute;
  final void Function(String userId) onDisableVideo;
  final void Function(String userId) onEnableVideo;

  const ParticipantListSidebar({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onPromote,
    required this.onDemote,
    required this.onMakeModerator,
    required this.onRemoveModerator,
    required this.onKick,
    required this.onBan,
    required this.onMute,
    required this.onUnmute,
    required this.onDisableVideo,
    required this.onEnableVideo,
  });

  bool _isHost(Room r, String uid) => r.hostId == uid;
  bool _isModerator(Room r, String uid) =>
      r.moderators.contains(uid) || r.admins.contains(uid);
  bool _isSpeaker(Room r, String uid) => r.speakers.contains(uid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both room data and participants subcollection
    final participantsAsync =
        ref.watch(roomParticipantsFirestoreProvider(room.id));

    return participantsAsync.when(
      data: (participants) {
        if (participants.isEmpty) {
          return _buildContainer(
            child: const Center(
              child: Text('No participants yet',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return _buildContainer(
          child: ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              final uid = participant.userId;
              final isHost = _isHost(room, uid);
              final isMod = _isModerator(room, uid);
              final isSpeaker = _isSpeaker(room, uid);
              final isCurrent = uid == currentUserId;

              // Sprint 2: Check control state
              final isRemoved = room.removedUsers.contains(uid);
              final isMutedByHost = room.mutedUsers.contains(uid);

              // Host spotlight: elevated card with crown
              if (isHost) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.18),
                        Colors.orange.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.55),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.15),
                          blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.workspace_premium,
                                color: Colors.white, size: 22),
                          ),
                          Positioned(
                            top: -8,
                            right: -4,
                            child: Text('👑',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant.displayName.isNotEmpty
                                  ? participant.displayName
                                  : uid,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCurrent ? 'Host · You' : 'Host',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      _buildMenu(context, room, uid, isCurrent, isHost,
                          isMod, isSpeaker) ?? const SizedBox.shrink(),
                    ],
                  ),
                );
              }

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: isRemoved
                      ? Colors.grey.shade900
                      : isMod
                          ? Colors.blueAccent
                          : isSpeaker
                              ? Colors.green
                              : Colors.grey.shade700,
                  child: Icon(
                    isMod
                        ? Icons.shield
                        : isSpeaker
                            ? Icons.mic
                            : Icons.headset,
                    color: isRemoved ? Colors.grey.shade600 : Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  participant.displayName.isNotEmpty
                      ? participant.displayName
                      : uid,
                  style: TextStyle(
                    color: isRemoved ? Colors.grey.shade400 : Colors.white,
                    fontSize: 14,
                    decoration: isRemoved ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    if (isRemoved) ...[
                      const Icon(Icons.block,
                          size: 12, color: Colors.redAccent),
                      const SizedBox(width: 4),
                    ],
                    if (isMutedByHost && !isRemoved) ...[
                      const Icon(Icons.mic_off,
                          size: 12, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                    ],
                    if (participant.isOnCam && !isRemoved) ...[
                      const Icon(Icons.videocam,
                          size: 12, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                    ],
                    if (!participant.isMuted &&
                        !isMutedByHost &&
                        !isRemoved) ...[
                      const Icon(Icons.mic, size: 12, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        isRemoved
                            ? 'Removed'
                            : isMod
                                ? 'Moderator'
                                : isSpeaker
                                    ? 'Speaker'
                                    : 'Listener',
                        style: TextStyle(
                          color:
                              isRemoved ? Colors.grey.shade600 : Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: _buildMenu(
                    context, room, uid, isCurrent, isHost, isMod, isSpeaker),
              );
            },
          ),
        );
      },
      loading: () => _buildContainer(
        child: const Center(
            child: CircularProgressIndicator(color: Colors.redAccent)),
      ),
      error: (e, _) => _buildContainer(
        child: Center(
          child: Text('Error loading participants: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  Widget? _buildMenu(BuildContext context, Room room, String uid,
      bool isCurrent, bool isHost, bool isMod, bool isSpeaker) {
    final currentIsHost = _isHost(room, currentUserId);
    final currentIsMod = _isModerator(room, currentUserId);
    if (!currentIsHost && !currentIsMod) return null;
    if (isHost) return null; // cannot act on host

    // Sprint 2: Check if user is removed or muted from room lists
    final isRemoved = room.removedUsers.contains(uid);
    final isMutedByHost = room.mutedUsers.contains(uid);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
      onSelected: (value) {
        switch (value) {
          case 'promote':
            onPromote(uid);
            break;
          case 'demote':
            onDemote(uid);
            break;
          case 'make_mod':
            onMakeModerator(uid);
            break;
          case 'remove_mod':
            onRemoveModerator(uid);
            break;
          case 'kick':
            onKick(uid);
            break;
          case 'ban':
            onBan(uid);
            break;
          case 'mute':
            onMute(uid);
            break;
          case 'unmute':
            onUnmute(uid);
            break;
          case 'disable_video':
            onDisableVideo(uid);
            break;
          case 'enable_video':
            onEnableVideo(uid);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        if (!isSpeaker) {
          items.add(const PopupMenuItem(
              value: 'promote', child: Text('Promote to Speaker')));
        } else {
          items.add(const PopupMenuItem(
              value: 'demote', child: Text('Demote to Listener')));
        }
        if (!isMod) {
          items.add(const PopupMenuItem(
              value: 'make_mod', child: Text('Make Moderator')));
        } else {
          items.add(const PopupMenuItem(
              value: 'remove_mod', child: Text('Remove Moderator')));
        }
        items.add(const PopupMenuDivider());
        // Sprint 2: Smarter mute/unmute based on room.mutedUsers
        if (isMutedByHost) {
          items.add(const PopupMenuItem(
              value: 'unmute', child: Text('ðŸ”Š Unmute Audio')));
        } else {
          items.add(const PopupMenuItem(
              value: 'mute', child: Text('ðŸ”‡ Mute Audio')));
        }
        items.add(const PopupMenuItem(
            value: 'disable_video', child: Text('Disable Video')));
        items.add(const PopupMenuItem(
            value: 'enable_video', child: Text('Enable Video')));
        items.add(const PopupMenuDivider());
        if (isRemoved) {
          items.add(const PopupMenuItem(
            value: 'removed',
            enabled: false,
            child: Text('âŒ Removed', style: TextStyle(color: Colors.grey)),
          ));
        } else {
          items.add(const PopupMenuItem(
              value: 'kick', child: Text('âŒ Remove from Room')));
        }
        return items;
      },
    );
  }
}
