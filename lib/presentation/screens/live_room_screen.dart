import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/user_provider.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/widgets/message_bubble.dart';
import '../../features/room/providers/host_controls_provider.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LiveRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  late TextEditingController messageController;
  late ScrollController scrollController;
  DateTime? lastMessageTime;
  int slowModeSeconds = 0;
  bool isSending = false;
  String cooldownMessage = '';

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    scrollController = ScrollController();
    _joinRoom();
  }

  Future<void> _joinRoom() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(user.id);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({
        'lastActiveAt': now,
        'isMuted': false,
        'isBanned': false,
      });
    } else {
      await docRef.set({
        'userId': user.id,
        'role': 'audience',
        'isMuted': false,
        'isBanned': false,
        'joinedAt': now,
        'lastActiveAt': now,
      });
    }
  }

  Future<void> _leaveRoom() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(user.id);
    await docRef.delete();
  }

  @override
  void dispose() {
    _leaveRoom();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }
    final currentParticipantAsync = ref.watch(currentParticipantProvider({'roomId': widget.roomId, 'userId': user.id}));
    final participantsAsync = ref.watch(participantsStreamProvider(widget.roomId));
    final messageStreamAsync = ref.watch(messageStreamProvider(widget.roomId));
    // Use sendMessageProvider(widget.roomId) directly in the widget tree
    final hostControls = ref.read(hostControlsProvider);

    return currentParticipantAsync.when(
      data: (participant) {
        final isHost = ref.watch(isHostProvider(participant));
        final isCohost = ref.watch(isCohostProvider(participant));
        final role = participant?.role ?? 'audience';
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
          builder: (context, roomSnap) {
            if (!roomSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final roomData = roomSnap.data!.data() as Map<String, dynamic>?;
            slowModeSeconds = roomData?['slowModeSeconds'] ?? 0;
            final isLocked = roomData?['isLocked'] ?? false;
            // Ban enforcement
            if (participant?.isBanned == true) {
              return const Scaffold(body: Center(child: Text('You are banned from this room.')));
            }
      final sendMessage = ref.read(sendMessageProvider(widget.roomId));
            if (isLocked && !isHost && !isCohost) {
              return const Scaffold(body: Center(child: Text('Room is locked.')));
            }
            return Scaffold(
              appBar: AppBar(title: Text('Live Room ($role)')),
              body: Column(
                children: [
                  if (isHost)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Host Controls', style: Theme.of(context).textTheme.titleMedium),
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock),
                            color: isLocked ? Colors.red : Colors.grey,
                            tooltip: isLocked ? 'Unlock Room' : 'Lock Room',
                            onPressed: () => hostControls.setLock(widget.roomId, !isLocked),
                          ),
                          IconButton(
                            icon: const Icon(Icons.timer),
                            tooltip: 'Set Slow Mode',
                            onPressed: () async {
                              final controller = TextEditingController(text: slowModeSeconds.toString());
                              final result = await showDialog<int>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Set Slow Mode (seconds)'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'Seconds'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
                                      child: const Text('Set'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null) await hostControls.setSlowMode(widget.roomId, result);
                            },
                          ),
                        ],
                      ),
                    ),
                  if (isHost)
                    Expanded(
                      child: participantsAsync.when(
                        data: (participants) {
                          return ListView(
                            children: participants.map((p) => ListTile(
                              title: Text(p.userId),
                              subtitle: Text('${p.role}${p.isMuted ? ' (muted)' : ''}${p.isBanned ? ' (banned)' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(p.isMuted ? Icons.volume_off : Icons.volume_up),
                                    tooltip: p.isMuted ? 'Unmute' : 'Mute',
                                    onPressed: () => hostControls.muteUser(widget.roomId, p.userId, !p.isMuted),
                                  ),
                                  IconButton(
                                    icon: Icon(p.isBanned ? Icons.block : Icons.check),
                                    tooltip: p.isBanned ? 'Unban' : 'Ban',
                                    onPressed: () => hostControls.banUser(widget.roomId, p.userId, !p.isBanned),
                                  ),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  Expanded(
                    child: messageStreamAsync.when(
                      data: (messages) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (scrollController.hasClients) {
                            scrollController.jumpTo(scrollController.position.maxScrollExtent);
                          }
                        });
                        if (messages.isEmpty) {
                          return const Center(child: Text('No messages yet.'));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: messages.length,
                          itemBuilder: (context, i) {
                            final msg = messages[i];
                            return MessageBubble(
                              message: msg,
                              user: user,
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                  if (cooldownMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        cooldownMessage,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            enabled: !isSending && participant?.isMuted != true && participant?.isBanned != true,
                            decoration: InputDecoration(
                              hintText: participant?.isMuted == true
                                  ? 'You are muted'
                                  : participant?.isBanned == true
                                      ? 'You are banned'
                                      : 'Type your message...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSending || participant?.isMuted == true || participant?.isBanned == true
                              ? null
                              : () async {
                                  if (messageController.text.trim().isEmpty) return;
                                  setState(() => isSending = true);
                                  try {
                                    await sendMessage(messageController.text.trim());
                                    messageController.clear();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  } finally {
                                    setState(() => isSending = false);
                                  }
                                },
                          child: isSending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Send'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  await _leaveRoom();
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Leave Room'),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
