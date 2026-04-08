import 'package:flutter/material.dart';

import '../../../models/room_participant_model.dart';
import '../../../features/room/providers/presence_provider.dart';

/// A Paltalk-style always-visible user list panel for the room.
/// Shows role icons (crown/star/shield), online status, mic/cam indicators.
class UserListPanel extends StatelessWidget {
  const UserListPanel({
    super.key,
    required this.participants,
    required this.currentUserId,
    required this.presenceList,
    required this.displayNameById,
    required this.avatarUrlById,
    this.onTapUser,
    this.onWhisper,
    this.onKick,
    this.onMute,
    this.onBan,
    this.onBuzz,
    this.isCurrentUserHost = false,
  });

  final List<RoomParticipantModel> participants;
  final String currentUserId;
  final List<RoomPresenceModel> presenceList;
  final Map<String, String> displayNameById;
  final Map<String, String?> avatarUrlById;

  /// Called when a user row is tapped (e.g. to open a profile popup).
  final void Function(RoomParticipantModel participant)? onTapUser;

  /// Called when the whisper button is tapped for a user.
  final void Function(RoomParticipantModel participant)? onWhisper;

  /// Host-only moderation actions.
  final void Function(RoomParticipantModel participant)? onKick;
  final void Function(RoomParticipantModel participant)? onMute;
  final void Function(RoomParticipantModel participant)? onBan;
  final void Function(RoomParticipantModel participant)? onBuzz;

  /// Whether the current user is a host/cohost/moderator (shows mod menu).
  final bool isCurrentUserHost;

  @override
  Widget build(BuildContext context) {
    const npSurfaceContainer = Color(0xFF161A21);
    const npOnVariant = Color(0xFFB09080);

    final onlineIds = {
      for (final p in presenceList)
        if (p.isOnline &&
            (p.lastHeartbeatAt == null ||
                DateTime.now().difference(p.lastHeartbeatAt!).inSeconds < 90))
          p.userId,
    };

    // Sort: host first, then cohost, then moderators, then others
    final sorted = [...participants]..sort((a, b) {
        return _roleOrder(a.role).compareTo(_roleOrder(b.role));
      });

    if (sorted.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No one here yet.',
            style: TextStyle(color: npOnVariant, fontSize: 13),
          ),
        ),
      );
    }

    return ColoredBox(
      color: npSurfaceContainer,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final p = sorted[index];
          final isOnline = onlineIds.contains(p.userId);
          final displayName =
              displayNameById[p.userId] ?? p.userId;
          final avatarUrl = avatarUrlById[p.userId];
          final isMe = p.userId == currentUserId;

          return _UserListTile(
            participant: p,
            displayName: displayName,
            avatarUrl: avatarUrl,
            isOnline: isOnline,
            isMe: isMe,
            customStatus: presenceList
                .firstWhere((pr) => pr.userId == p.userId,
                    orElse: () => RoomPresenceModel(
                          userId: p.userId,
                          isOnline: false,
                          lastHeartbeatAt: null,
                          lastSeenAt: null,
                        ))
                .customStatus,
            onTap: onTapUser == null ? null : () => onTapUser!(p),
            onWhisper: (onWhisper == null || isMe)
                ? null
                : () => onWhisper!(p),
            onKick: (onKick == null || isMe) ? null : () => onKick!(p),
            onMute: (onMute == null || isMe) ? null : () => onMute!(p),
            onBan: (onBan == null || isMe) ? null : () => onBan!(p),
            onBuzz: (onBuzz == null || isMe) ? null : () => onBuzz!(p),
            showModMenu: isCurrentUserHost && !isMe,
          );
        },
      ),
    );
  }

  static int _roleOrder(String role) {
    switch (role) {
      case 'host':
      case 'owner':
        return 0;
      case 'cohost':
        return 1;
      case 'moderator':
        return 2;
      default:
        return 3;
    }
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({
    required this.participant,
    required this.displayName,
    required this.isOnline,
    required this.isMe,
    this.avatarUrl,
    this.customStatus,
    this.onTap,
    this.onWhisper,
    this.onKick,
    this.onMute,
    this.onBan,
    this.onBuzz,
    this.showModMenu = false,
  });

  final RoomParticipantModel participant;
  final String displayName;
  final String? avatarUrl;
  final String? customStatus;
  final bool isOnline;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onWhisper;
  final VoidCallback? onKick;
  final VoidCallback? onMute;
  final VoidCallback? onBan;
  final VoidCallback? onBuzz;
  final bool showModMenu;

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    const npSurfaceHigh = Color(0xFF241820);
    const npPrimary = Color(0xFFD4A853);

    final selected = await showMenu<String>(
      context: context,
      color: npSurfaceHigh,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'profile',
          child: Row(children: [
            const Icon(Icons.person_outline, color: npPrimary, size: 16),
            const SizedBox(width: 8),
            Text('View Profile', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
          ]),
        ),
        if (onWhisper != null)
          PopupMenuItem(
            value: 'whisper',
            child: Row(children: [
              const Icon(Icons.message_outlined, color: Color(0xFFC45E7A), size: 16),
              const SizedBox(width: 8),
              Text('Whisper', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            ]),
          ),
        if (onBuzz != null)
          PopupMenuItem(
            value: 'buzz',
            child: Row(children: [
              const Icon(Icons.electric_bolt, color: Color(0xFFFF6E84), size: 16),
              const SizedBox(width: 8),
              Text('Buzz ⚡', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            ]),
          ),
        if (showModMenu && onMute != null)
          PopupMenuItem(
            value: 'mute',
            child: Row(children: [
              const Icon(Icons.mic_off_outlined, color: Color(0xFFFFA040), size: 16),
              const SizedBox(width: 8),
              Text('Mute', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            ]),
          ),
        if (showModMenu && onKick != null)
          PopupMenuItem(
            value: 'kick',
            child: Row(children: [
              const Icon(Icons.logout, color: Color(0xFFFF6E84), size: 16),
              const SizedBox(width: 8),
              Text('Kick', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            ]),
          ),
        if (showModMenu && onBan != null)
          PopupMenuItem(
            value: 'ban',
            child: Row(children: [
              const Icon(Icons.block, color: Color(0xFFFF3355), size: 16),
              const SizedBox(width: 8),
              Text('Ban', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            ]),
          ),
      ],
    );
    if (selected == null) return;
    switch (selected) {
      case 'profile':
        onTap?.call();
      case 'whisper':
        onWhisper?.call();
      case 'buzz':
        onBuzz?.call();
      case 'mute':
        onMute?.call();
      case 'kick':
        onKick?.call();
      case 'ban':
        onBan?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    const npSurfaceHigh = Color(0xFF241820);
    const npOnVariant = Color(0xFFB09080);
    const npPrimary = Color(0xFFD4A853);
    const npSecondary = Color(0xFFC45E7A);

    final roleIcon = _roleIcon(participant.role);

    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
      onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: (customStatus != null && customStatus!.isNotEmpty) ? 56 : 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar + online dot
              SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: npSurfaceHigh,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? Text(
                            displayName.isEmpty
                                ? '?'
                                : displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF4CAF50)
                            : npOnVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF161A21),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Name + role
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (roleIcon != null) ...[
                        Text(roleIcon, style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          isMe ? '$displayName (you)' : displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isMe ? npPrimary : Colors.white,
                            fontSize: 12,
                            fontWeight: isMe
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (customStatus != null && customStatus!.isNotEmpty)
                    Text(
                      customStatus!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Mic / cam indicators
            if (participant.micOn)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(Icons.mic, color: npSecondary, size: 13),
              ),
            if (participant.camOn)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(Icons.videocam, color: npSecondary, size: 13),
              ),
            if (participant.isMuted)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(Icons.mic_off, color: Color(0xFFFF6E84), size: 13),
              ),
            // Whisper button (PM)
            if (onWhisper != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: onWhisper,
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.message_outlined,
                      color: npOnVariant,
                      size: 14,
                      semanticLabel: 'Whisper',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    )); // InkWell + GestureDetector
  }

  static String? _roleIcon(String role) {
    switch (role) {
      case 'host':
      case 'owner':
        return '👑';
      case 'cohost':
        return '⭐';
      case 'moderator':
        return '🛡️';
      default:
        return null;
    }
  }
}
