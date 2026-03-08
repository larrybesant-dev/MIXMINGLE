// lib/features/room/widgets/moderation_panel_widget.dart
//
// Bottom-sheet moderation panel shown to owners, room admins, and superadmins.
// Lists live participants and provides kick / ban / mute actions.
//
// Usage:
//   showModalBottomSheet(
//     context: context,
//     builder: (_) => ModerationPanelWidget(roomId: roomId, moderatorId: uid),
//   );

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/room_permission_service.dart';
import '../services/room_moderation_service.dart';
import '../providers/room_subcollection_providers.dart';

class ModerationPanelWidget extends StatefulWidget {
  const ModerationPanelWidget({
    super.key,
    required this.roomId,
    required this.moderatorId,
  });

  final String roomId;
  final String moderatorId;

  @override
  State<ModerationPanelWidget> createState() => _ModerationPanelWidgetState();
}

class _ModerationPanelWidgetState extends State<ModerationPanelWidget> {
  late final Stream<QuerySnapshot> _participantsStream;
  late final RoomModerationService _modService;
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    _participantsStream = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('participants')
        .where('role', whereNotIn: ['banned'])
        .orderBy('role')
        .snapshots();
    _modService = RoomModerationService(
      RoomSubcollectionRepository(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _kick(String targetId, String targetName) async {
    final confirmed = await _confirm(
      'Kick $targetName',
      'They can rejoin unless banned.',
    );
    if (!confirmed) return;
    setState(() => _busyUserId = targetId);
    try {
      await _modService.kickUser(
        roomId: widget.roomId,
        moderatorId: widget.moderatorId,
        targetUserId: targetId,
      );
      _snack('$targetName was kicked');
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _ban(String targetId, String targetName) async {
    final confirmed = await _confirm(
      'Ban $targetName',
      'They will be prevented from rejoining this room.',
    );
    if (!confirmed) return;
    setState(() => _busyUserId = targetId);
    try {
      await _modService.banUser(
        roomId: widget.roomId,
        moderatorId: widget.moderatorId,
        targetUserId: targetId,
      );
      _snack('$targetName was banned from this room');
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _mute(String targetId, String targetName, bool isMuted) async {
    setState(() => _busyUserId = targetId);
    try {
      if (isMuted) {
        await _modService.unmuteUser(
          roomId: widget.roomId,
          moderatorId: widget.moderatorId,
          targetUserId: targetId,
        );
        _snack('$targetName unmuted');
      } else {
        await _modService.muteUser(
          roomId: widget.roomId,
          moderatorId: widget.moderatorId,
          targetUserId: targetId,
        );
        _snack('$targetName muted');
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _assignAdmin(String targetId, String targetName) async {
    final confirmed = await _confirm(
      'Assign $targetName as Room Admin?',
      'They will be able to kick, ban, and mute participants.',
    );
    if (!confirmed) return;
    try {
      await RoomPermissionService().addRoomAdmin(widget.roomId, targetId);
      _snack('$targetName is now a room admin');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A0A2E),
            title: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: Text(body,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirm',
                      style: TextStyle(color: Color(0xFFFF4C4C)))),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[800] : const Color(0xFF1A8A4A),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Moderation Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Color(0xFF2A1A3E), height: 20),
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: _participantsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF4C4C)),
                  );
                }
                final docs = snap.data?.docs ?? [];
                final others = docs
                    .where((d) => d.id != widget.moderatorId)
                    .toList();
                if (others.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No other participants in the room.',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: others.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFF2A1A3E), height: 1),
                  itemBuilder: (ctx, i) {
                    final data =
                        others[i].data() as Map<String, dynamic>;
                    final uid = others[i].id;
                    final name =
                        data['displayName'] as String? ?? 'User';
                    final role = data['role'] as String? ?? 'member';
                    final isMuted = data['isMuted'] == true ||
                        role == 'muted';
                    final isBusy = _busyUserId == uid;
                    final avatar = data['avatarUrl'] as String? ?? '';

                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF2A1A3E),
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar.isEmpty
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        role,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                      trailing: isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF4C4C)),
                            )
                          : Wrap(
                              spacing: 0,
                              children: [
                                // Mute / Unmute
                                IconButton(
                                  icon: Icon(
                                    isMuted
                                        ? Icons.mic
                                        : Icons.mic_off,
                                    size: 18,
                                    color: isMuted
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                  ),
                                  tooltip:
                                      isMuted ? 'Unmute' : 'Mute',
                                  onPressed: () =>
                                      _mute(uid, name, isMuted),
                                ),
                                // Kick
                                IconButton(
                                  icon: const Icon(Icons.logout,
                                      size: 18,
                                      color: Colors.orangeAccent),
                                  tooltip: 'Kick',
                                  onPressed: () => _kick(uid, name),
                                ),
                                // Ban
                                IconButton(
                                  icon: const Icon(Icons.block,
                                      size: 18,
                                      color: Color(0xFFFF4C4C)),
                                  tooltip: 'Ban',
                                  onPressed: () => _ban(uid, name),
                                ),
                                // Make Admin
                                if (role == 'member')
                                  IconButton(
                                    icon: const Icon(Icons.shield,
                                        size: 18,
                                        color: Colors.purpleAccent),
                                    tooltip: 'Make Room Admin',
                                    onPressed: () =>
                                        _assignAdmin(uid, name),
                                  ),
                              ],
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
