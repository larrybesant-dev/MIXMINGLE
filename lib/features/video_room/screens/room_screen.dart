/// Room Screen
///
/// Main video room UI displaying:
/// - Join flow phase text
/// - Participant cards with animations
/// - Room energy indicator
/// - Control buttons (mic, video, leave)
///
/// Usage:
/// ```dart
/// RoomScreen(
///   roomId: 'room_123',
///   roomName: 'Gaming Room',
///   agoraToken: 'token_from_backend',
/// )
/// ```
///
/// Architecture:
/// - Consumes: AgoraRoomController (via Provider)
/// - Depends on: JoinFlowController, AgoraService, RoomFirestoreService
///
/// Enforces: DESIGN_BIBLE.md (colors, spacing, animations)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/design_system/design_constants.dart' hide JoinPhase;
import '../controllers/agora_room_controller.dart';
import '../controllers/join_flow_controller.dart';
import '../../../shared/models/participant.dart';
import '../../../shared/models/room.dart';
import '../../../shared/providers/room_providers.dart';
import '../widgets/participant_card_widget.dart';

class RoomScreen extends ConsumerStatefulWidget {
  /// Room ID for Agora channel
  final String roomId;

  /// Display name of room
  final String roomName;

  /// Token from backend for Agora authentication
  final String agoraToken;

  /// Callback when user leaves room
  final VoidCallback? onLeaveRoom;

  const RoomScreen({
    required this.roomId,
    required this.roomName,
    required this.agoraToken,
    this.onLeaveRoom,
    super.key,
  });

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    final notifier = ref.read(agoraRoomProvider.notifier);
    final currentUser = FirebaseAuth.instance.currentUser;
    notifier.setRoomContext(
      roomId: widget.roomId,
      userId: currentUser?.uid ?? 'anonymous',
      userName: currentUser?.displayName ??
          currentUser?.email?.split('@').first ??
          'Guest',
    );
    try {
      await notifier.joinRoom(agoraToken: widget.agoraToken);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to join room: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: DesignTypography.heading,
        ),
        content: Text(
          message,
          style: DesignTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: DesignTypography.body.copyWith(
                color: DesignColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveRoom() async {
    try {
      await ref.read(agoraRoomProvider.notifier).leaveRoom();
      if (!mounted) return;
      widget.onLeaveRoom?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to leave room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(agoraRoomProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';

    final roomAsync = ref.watch(roomStreamProvider(widget.roomId));
    final room = roomAsync.asData?.value;

    final isOwner = room != null && room.ownerId == currentUserId;
    final isAdmin = room != null &&
        (isOwner || room.admins.contains(currentUserId));

    return Scaffold(
      // ✅ Use dark background
      backgroundColor: DesignColors.surfaceDefault,

      appBar: AppBar(
        // ✅ Use dark app bar
        backgroundColor: DesignColors.surfaceDefault,
        elevation: 0,
        title: Text(
          widget.roomName,
          style: DesignTypography.heading,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: DesignColors.textPrimary,
          ),
          onPressed: _handleLeaveRoom,
        ),
        actions: [
          // Admin controls button — only visible to owner/admin
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: DesignColors.accent),
              tooltip: 'Admin Controls',
              onPressed: () => _showAdminControlsSheet(context, room),
            ),
          // Room energy indicator top-right
          Padding(
            padding: const EdgeInsets.all(DesignSpacing.md),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSpacing.md,
                  vertical: DesignSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: RoomEnergyThresholds.getEnergyColor(roomState.energy)
                      .withValues(alpha: 0.1),
                  border: Border.all(
                      color:
                          RoomEnergyThresholds.getEnergyColor(roomState.energy),
                      width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  RoomEnergyThresholds.getEnergyLabel(roomState.energy),
                  style: DesignTypography.caption.copyWith(
                    color:
                        RoomEnergyThresholds.getEnergyColor(roomState.energy),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: roomState.isInRoom
          ? _buildRoomContent(roomState, isAdmin: isAdmin, room: room)
          : _buildJoinFlowOverlay(roomState),

      // Bottom control bar
      bottomNavigationBar: roomState.isInRoom
          ? Container(
              padding: const EdgeInsets.all(DesignSpacing.lg),
              decoration: const BoxDecoration(
                color: DesignColors.surfaceDefault,
                border: Border(
                    top:
                        BorderSide(color: DesignColors.surfaceLight, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.small(
                    backgroundColor: roomState.isMicMuted
                        ? DesignColors.error
                        : DesignColors.surfaceLight,
                    onPressed: () =>
                        ref.read(agoraRoomProvider.notifier).toggleMicrophone(),
                    child: Icon(
                        roomState.isMicMuted ? Icons.mic_off : Icons.mic,
                        color: DesignColors.white),
                  ),
                  FloatingActionButton.small(
                    backgroundColor: roomState.isVideoMuted
                        ? DesignColors.error
                        : DesignColors.surfaceLight,
                    onPressed: () =>
                        ref.read(agoraRoomProvider.notifier).toggleVideo(),
                    child: Icon(
                        roomState.isVideoMuted
                            ? Icons.videocam_off
                            : Icons.videocam,
                        color: DesignColors.white),
                  ),
                  FloatingActionButton.small(
                    backgroundColor: const Color(0xFFEF5350),
                    onPressed: _handleLeaveRoom,
                    child: const Icon(Icons.phone_disabled,
                        color: DesignColors.white),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Build join flow overlay while room is connecting
  Widget _buildJoinFlowOverlay(AgoraRoomState roomState) {
    final joinFlow = ref.watch(joinFlowProvider);
    final phase = joinFlow.phase;
    final displayText = phase.displayText;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DesignColors.accent),
          ),
          const SizedBox(height: DesignSpacing.xl),
          Text(displayText,
              style: DesignTypography.heading, textAlign: TextAlign.center),
          const SizedBox(height: DesignSpacing.md),
          if (phase == JoinPhase.error)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
              child: Text(
                joinFlow.errorMessage ?? 'Unknown error',
                style: DesignTypography.caption
                    .copyWith(color: const Color(0xFFEF5350)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Build main room content with participant cards
  Widget _buildRoomContent(AgoraRoomState roomState, {required bool isAdmin, Room? room}) {
    final participants = roomState.participants;

    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for participants...',
          style: DesignTypography.body,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(DesignSpacing.lg),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: DesignSpacing.lg,
          crossAxisSpacing: DesignSpacing.lg,
          childAspectRatio: 1.2,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];

          return ParticipantCardWidget(
            participant: participant,
            onTap: () {
              _showParticipantActionsMenu(context, participant, isAdmin: isAdmin);
            },
            showArrivalAnimation: true,
          );
        },
      ),
    );
  }

<<<<<<< HEAD
  void _showParticipantActionsMenu(BuildContext context, Participant participant,
      {required bool isAdmin}) {
=======
  void _showParticipantActionsMenu(
      BuildContext context, Participant participant) {
>>>>>>> origin/develop
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                Icon(participant.isMuted ? Icons.volume_up : Icons.volume_off),
            title: Text(participant.isMuted ? 'Unmute for me' : 'Mute for me'),
            onTap: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(participant.isMuted
                        ? 'Unmuted ${participant.name}'
                        : 'Muted ${participant.name}')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context)
                  .pushNamed('/profile/user', arguments: participant.uid);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Spotlight'),
            onTap: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Spotlighting ${participant.name}')),
              );
            },
          ),
          // Admin-only actions
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.orangeAccent),
              title: Text('Kick ${participant.name}'),
              onTap: () {
                Navigator.of(ctx).pop();
                _adminAction(() => ref.read(roomServiceProvider).adminKickUser(widget.roomId, participant.uid),
                    'Kicked ${participant.name}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text('Ban ${participant.name}'),
              onTap: () {
                Navigator.of(ctx).pop();
                _adminAction(() => ref.read(roomServiceProvider).adminBanUser(widget.roomId, participant.uid),
                    'Banned ${participant.name}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield, color: Colors.green),
              title: Text('Add Admin: ${participant.name}'),
              onTap: () {
                Navigator.of(ctx).pop();
                _adminAction(() => ref.read(roomServiceProvider).makeAdmin(widget.roomId, participant.uid),
                    '${participant.name} is now an admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: Colors.grey),
              title: Text('Remove Admin: ${participant.name}'),
              onTap: () {
                Navigator.of(ctx).pop();
                _adminAction(() => ref.read(roomServiceProvider).removeAdmin(widget.roomId, participant.uid),
                    'Removed admin from ${participant.name}');
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showAdminControlsSheet(BuildContext context, Room? room) {
    if (room == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Admin Controls', style: DesignTypography.heading),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: DesignColors.accent),
              title: const Text('Edit Room Name'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditTextDialog(
                  context,
                  title: 'Edit Room Name',
                  initialValue: room.title,
                  onSave: (v) => _adminAction(
                      () => ref.read(roomServiceProvider).updateRoomName(widget.roomId, v),
                      'Room name updated'),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.short_text, color: DesignColors.accent),
              title: const Text('Edit Room Header'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditTextDialog(
                  context,
                  title: 'Edit Header',
                  initialValue: '',
                  onSave: (v) => _adminAction(
                      () => ref.read(roomServiceProvider).updateRoomHeader(widget.roomId, v),
                      'Header updated'),
                );
              },
            ),
            ListTile(
              leading: Icon(
                room.isLocked ? Icons.lock_open : Icons.lock,
                color: room.isLocked ? Colors.green : Colors.orange,
              ),
              title: Text(room.isLocked ? 'Unlock Room' : 'Lock Room'),
              onTap: () {
                Navigator.of(ctx).pop();
                if (room.isLocked) {
                  _adminAction(() => ref.read(roomServiceProvider).unlockRoom(widget.roomId), 'Room unlocked');
                } else {
                  _adminAction(() => ref.read(roomServiceProvider).lockRoom(widget.roomId), 'Room locked');
                }
              },
            ),
            if (room.bannedUsers.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: Text('Banned Users (${room.bannedUsers.length})'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showBannedUsersSheet(context, room);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _adminAction(Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    }
  }

  void _showBannedUsersSheet(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Banned Users', style: DesignTypography.heading),
            ),
            const Divider(),
            if (room.bannedUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No banned users.', style: DesignTypography.body),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: room.bannedUsers.length,
                  itemBuilder: (_, i) {
                    final uid = room.bannedUsers[i];
                    return ListTile(
                      leading: const Icon(Icons.person_off, color: Colors.redAccent),
                      title: Text(uid, style: DesignTypography.body),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _adminAction(
                            () => ref.read(roomServiceProvider).unbanUser(widget.roomId, uid),
                            'User unbanned',
                          );
                        },
                        child: Text('Unban',
                            style: DesignTypography.body.copyWith(color: DesignColors.accent)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditTextDialog(BuildContext context,
      {required String title, required String initialValue, required void Function(String) onSave}) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignColors.surfaceDefault,
        title: Text(title, style: DesignTypography.heading),
        content: TextField(
          controller: controller,
          style: DesignTypography.body,
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: DesignColors.surfaceLight)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DesignColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: DesignTypography.body.copyWith(color: DesignColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onSave(controller.text.trim());
            },
            child: Text('Save', style: DesignTypography.body.copyWith(color: DesignColors.accent)),
          ),
        ],
      ),
    );
  }
}
