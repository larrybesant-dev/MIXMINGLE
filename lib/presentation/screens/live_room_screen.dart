import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

import '../../config/agora_constants.dart';
import '../providers/user_provider.dart';
import '../../features/room/providers/room_firestore_provider.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/widgets/message_bubble.dart';
import '../../features/room/providers/cam_access_provider.dart';
import '../../features/room/providers/host_controls_provider.dart';
import '../../features/room/providers/host_provider.dart';
import '../../features/room/providers/room_policy_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/agora_service.dart';
import '../../services/moderation_service.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LiveRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  late TextEditingController messageController;
  late ScrollController scrollController;
  FirebaseFirestore? _firestore;
  String? _joinedUserId;
  DateTime? lastMessageTime;
  int slowModeSeconds = 0;
  bool isSending = false;
  String cooldownMessage = '';
  bool _isJoiningRoom = false;
  String? _roomJoinError;
  bool _hasTrackedRoomJoin = false;
  bool _hasTrackedFirstMessage = false;
  AgoraService? _agoraService;
  bool _isCallConnecting = false;
  bool _isCallReady = false;
  bool _isMicMuted = false;
  bool _isVideoEnabled = true;
  String? _callError;
  Set<String> _excludedUserIds = const <String>{};
  String? _appliedMediaRole;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    scrollController = ScrollController();

    final user = ref.read(userProvider);
    if (user != null) {
      _firestore = ref.read(roomFirestoreProvider);
      _joinedUserId = user.id;
      _joinRoom(user.id);
    }
  }

  int _buildRtcUid(String userId) {
    return userId.hashCode.abs() % 2147483647;
  }

  Future<String> _fetchAgoraToken({required String channelName, required int rtcUid}) async {
    final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
    final result = await callable.call<Map<String, dynamic>>({
      'channelName': channelName,
      'rtcUid': rtcUid,
    });
    final data = Map<String, dynamic>.from(result.data);
    final token = (data['token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Missing Agora token from backend response.');
    }
    return token;
  }

  Future<void> _connectCall(String userId) async {
    if (_isCallConnecting || _isCallReady) return;
    final appId = AgoraConstants.appId.trim();
    if (appId.isEmpty) {
      setState(() {
        _callError = 'Audio/video unavailable: missing AGORA_APP_ID.';
      });
      return;
    }

    setState(() {
      _isCallConnecting = true;
      _callError = null;
    });

    final service = AgoraService();
    service.onRemoteUserJoined = () {
      if (mounted) {
        setState(() {});
      }
    };
    service.onRemoteUserLeft = () {
      if (mounted) {
        setState(() {});
      }
    };

    try {
      final rtcUid = _buildRtcUid(userId);
      final token = await _fetchAgoraToken(channelName: widget.roomId, rtcUid: rtcUid);
      await service.initialize(appId);
      await service.joinChannel(token, widget.roomId, rtcUid);
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() {
        _agoraService = service;
        _isCallReady = true;
      });
    } catch (e) {
      await service.dispose();
      if (mounted) {
        setState(() {
          _callError = 'Audio/video connection failed. ${e.toString()}';
          _isCallReady = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallConnecting = false;
        });
      }
    }
  }

  Future<void> _toggleMic() async {
    final service = _agoraService;
    if (service == null || !_isCallReady) return;
    final next = !_isMicMuted;
    await service.mute(next);
    if (mounted) {
      setState(() {
        _isMicMuted = next;
      });
    }
  }

  Future<void> _toggleVideo() async {
    final service = _agoraService;
    if (service == null || !_isCallReady) return;
    final next = !_isVideoEnabled;
    await service.enableVideo(next);
    if (mounted) {
      setState(() {
        _isVideoEnabled = next;
      });
    }
  }

  Future<void> _disconnectCall() async {
    final service = _agoraService;
    _agoraService = null;
    _isCallReady = false;
    _appliedMediaRole = null;
    if (service != null) {
      await service.dispose();
    }
  }

  Future<void> _applyRoleMediaState(String role) async {
    final service = _agoraService;
    if (service == null || !_isCallReady || _appliedMediaRole == role) {
      return;
    }

    final canBroadcast = role == 'host' || role == 'cohost';
    await service.mute(!canBroadcast);
    await service.enableVideo(canBroadcast);

    if (!mounted) {
      return;
    }

    setState(() {
      _appliedMediaRole = role;
      _isMicMuted = !canBroadcast;
      _isVideoEnabled = canBroadcast;
    });
  }

  void _exitRoom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    });
  }

  Future<void> _joinRoom(String userId) async {
    final firestore = _firestore;
    if (firestore == null || _isJoiningRoom) return;

    setState(() {
      _isJoiningRoom = true;
      _roomJoinError = null;
    });

    try {
      _joinedUserId = userId;
      final now = DateTime.now();
      final roomDoc = await firestore.collection('rooms').doc(widget.roomId).get();
      if (!roomDoc.exists) {
        setState(() => _roomJoinError = 'This room no longer exists.');
        _joinedUserId = null;
        _exitRoom();
        return;
      }

      final hostId = (roomDoc.data()?['hostId'] as String? ?? '').trim();
      final moderationService = ModerationService(firestore: firestore);
      _excludedUserIds = await moderationService.getExcludedUserIds(userId);

      if (hostId.isNotEmpty) {
        final hasBlockingRelationship = await moderationService.hasBlockingRelationship(userId, hostId);
        if (hasBlockingRelationship) {
          setState(() => _roomJoinError = 'You cannot join this room.');
          _joinedUserId = null;
          _exitRoom();
          return;
        }
      }

      if (_excludedUserIds.isNotEmpty) {
        final participantsSnapshot = await firestore
            .collection('rooms')
            .doc(widget.roomId)
            .collection('participants')
            .get();
        final hasBlockedParticipant = participantsSnapshot.docs.any((doc) {
          final participantData = doc.data();
          final participantId = (participantData['userId'] as String? ?? doc.id).trim();
          return participantId.isNotEmpty && participantId != userId && _excludedUserIds.contains(participantId);
        });
        if (hasBlockedParticipant) {
          setState(() => _roomJoinError = 'You cannot join while a blocked user is in this room.');
          _joinedUserId = null;
          _exitRoom();
          return;
        }
      }

      final isLocked = (roomDoc.data()?['isLocked'] ?? false) as bool;
      if (isLocked) {
        setState(() => _roomJoinError = 'Room is locked by host.');
        _joinedUserId = null;
        _exitRoom();
        return;
      }

      final docRef = firestore.collection('rooms').doc(widget.roomId).collection('participants').doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isBanned'] == true) {
          setState(() => _roomJoinError = 'You are banned from this room.');
          _joinedUserId = null;
          _exitRoom();
          return;
        }
        await docRef.update({
          'lastActiveAt': now,
        });
      } else {
        await docRef.set({
          'userId': userId,
          'role': 'audience',
          'isMuted': false,
          'isBanned': false,
          'joinedAt': now,
          'lastActiveAt': now,
        });
      }

      await _connectCall(userId);

      if (!_hasTrackedRoomJoin) {
        _hasTrackedRoomJoin = true;
        await AnalyticsService().logEvent('room_joined', params: {
          'room_id': widget.roomId,
          'user_id': userId,
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _roomJoinError = 'Could not join room. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isJoiningRoom = false);
      }
    }
  }

  Future<void> _leaveRoom() async {
    final userId = _joinedUserId;
    final firestore = _firestore;
    if (userId == null || firestore == null) return;

    final docRef = firestore.collection('rooms').doc(widget.roomId).collection('participants').doc(userId);
    try {
      await docRef.delete();
    } catch (_) {
      // Best-effort cleanup when users leave a room.
    }
  }

  @override
  void dispose() {
    _disconnectCall();
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
    if (_joinedUserId != user.id && !_isJoiningRoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _firestore = ref.read(roomFirestoreProvider);
          _joinRoom(user.id);
        }
      });
    }
    final currentParticipantAsync = ref.watch(
      currentParticipantProvider(CurrentParticipantParams(roomId: widget.roomId, userId: user.id)),
    );
    final participantsAsync = ref.watch(participantsStreamProvider(widget.roomId));
    final messageStreamAsync = ref.watch(messageStreamProvider(widget.roomId));
    final participantCountAsync = ref.watch(participantCountProvider(widget.roomId));
    final hostAsync = ref.watch(hostProvider(widget.roomId));
    final coHostsAsync = ref.watch(coHostsProvider(widget.roomId));
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final camRequestsAsync = ref.watch(roomCamAccessRequestsProvider(widget.roomId));
    final hostControls = ref.read(hostControlsProvider);
    final camAccessController = ref.read(camAccessControllerProvider);

    return currentParticipantAsync.when(
      data: (participant) {
        final isHost = ref.watch(isHostProvider(participant));
        final isCohost = ref.watch(isCohostProvider(participant));
        final role = participant?.role ?? 'audience';
        final myCamRequestAsync = ref.watch(myCamAccessRequestProvider((roomId: widget.roomId, requesterId: user.id)));
        final firestore = ref.watch(roomFirestoreProvider);
        if (_isCallReady && _appliedMediaRole != role) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyRoleMediaState(role);
          });
        }
        return StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('rooms').doc(widget.roomId).snapshots(),
          builder: (context, roomSnap) {
            final roomData = roomSnap.data?.data() as Map<String, dynamic>?;
            slowModeSeconds = roomData?['slowModeSeconds'] ?? 0;
            final isLocked = roomData?['isLocked'] ?? false;
            final hostId = (roomData?['hostId'] as String? ?? '').trim();
            // Ban enforcement
            if (participant?.isBanned == true) {
              return const Scaffold(body: Center(child: Text('You are banned from this room.')));
            }
            if (_roomJoinError != null && _joinedUserId == null) {
              return Scaffold(body: Center(child: Text(_roomJoinError!)));
            }
            final sendMessage = ref.read(sendMessageProvider(widget.roomId));
            final participantsInRoom = participantsAsync.valueOrNull ?? const [];
            final hasBlockedParticipantInRoom = participantsInRoom.any((participantItem) {
              final participantId = participantItem.userId.trim();
              if (participantId.isEmpty || participantId == user.id) {
                return false;
              }
              return _excludedUserIds.contains(participantId);
            });
            final allowChat = roomPolicyAsync.valueOrNull?.allowChat ?? true;
            final allowCamRequests = roomPolicyAsync.valueOrNull?.allowCamRequests ?? true;
            if (isLocked && !isHost && !isCohost) {
              return const Scaffold(body: Center(child: Text('Room is locked.')));
            }
            return Scaffold(
              appBar: AppBar(title: Text('Live Room ($role)')),
              body: Column(
                children: [
                  if (_callError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        _callError!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_isCallConnecting)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: LinearProgressIndicator(),
                    ),
                  if (_isCallReady && _agoraService != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 170,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _agoraService!.getLocalView(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_agoraService!.remoteUids.isNotEmpty)
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  final remoteUid = _agoraService!.remoteUids[index];
                                  return SizedBox(
                                    width: 150,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _agoraService!.getRemoteView(remoteUid, widget.roomId),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, unusedIndex) => const SizedBox(width: 8),
                                itemCount: _agoraService!.remoteUids.length,
                              ),
                            )
                          else
                            const Text('Waiting for other participants to join video...'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: _isMicMuted ? 'Unmute microphone' : 'Mute microphone',
                                onPressed: isHost || isCohost ? _toggleMic : null,
                                icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                tooltip: _isVideoEnabled ? 'Turn camera off' : 'Turn camera on',
                                onPressed: isHost || isCohost ? _toggleVideo : null,
                                icon: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (isHost)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Host Controls', style: Theme.of(context).textTheme.titleMedium),
                          Row(
                            children: [
                              Text('Slow Mode:'),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: slowModeSeconds,
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('Off')),
                                  DropdownMenuItem(value: 5, child: Text('5s')),
                                  DropdownMenuItem(value: 10, child: Text('10s')),
                                  DropdownMenuItem(value: 30, child: Text('30s')),
                                ],
                                onChanged: (val) {
                                  if (val != null) hostControls.toggleSlowMode(widget.roomId, val);
                                },
                              ),
                              const SizedBox(width: 24),
                              Text('Room:'),
                              const SizedBox(width: 8),
                              Switch(
                                value: isLocked,
                                onChanged: (_) => hostControls.toggleLockRoom(widget.roomId),
                                activeThumbColor: Colors.red,
                                inactiveThumbColor: Colors.green,
                              ),
                              Text(isLocked ? 'Locked' : 'Open'),
                              const SizedBox(width: 24),
                              Text('Chat:'),
                              const SizedBox(width: 8),
                              Switch(
                                value: allowChat,
                                onChanged: (_) => hostControls.toggleAllowChat(widget.roomId),
                              ),
                              Text(allowChat ? 'On' : 'Off'),
                              const SizedBox(width: 24),
                              Text('Cam Req:'),
                              const SizedBox(width: 8),
                              Switch(
                                value: allowCamRequests,
                                onChanged: (_) => hostControls.toggleAllowCamRequests(widget.roomId),
                              ),
                              Text(allowCamRequests ? 'On' : 'Off'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          camRequestsAsync.when(
                            data: (requests) {
                              final pendingRequests = requests.where((request) => request.status == 'pending').toList(growable: false);
                              if (pendingRequests.isEmpty) {
                                return const Text('No pending cam requests.');
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: pendingRequests.map((request) {
                                  return Card(
                                    child: ListTile(
                                      title: Text('Cam request from ${request.requesterId}'),
                                      subtitle: Text('Scope: ${request.decisionScope}'),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            onPressed: () => camAccessController.approveRequest(widget.roomId, request),
                                            icon: const Icon(Icons.check_circle_outline),
                                            tooltip: 'Approve',
                                          ),
                                          IconButton(
                                            onPressed: () => camAccessController.denyRequest(widget.roomId, request.id),
                                            icon: const Icon(Icons.cancel_outlined),
                                            tooltip: 'Deny',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(growable: false),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Could not load cam requests: $e'),
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
                                    onPressed: () => p.isMuted
                                        ? hostControls.unmuteUser(widget.roomId, p.userId)
                                        : hostControls.muteUser(widget.roomId, p.userId),
                                  ),
                                  IconButton(
                                    icon: Icon(p.isBanned ? Icons.block : Icons.check),
                                    tooltip: p.isBanned ? 'Unban' : 'Ban',
                                    onPressed: () => p.isBanned
                                        ? hostControls.unbanUser(widget.roomId, p.userId)
                                        : hostControls.banUser(widget.roomId, p.userId),
                                  ),
                                  IconButton(
                                    icon: Icon(p.role == 'cohost' ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up),
                                    tooltip: p.role == 'cohost' ? 'Demote to audience' : 'Promote to cohost',
                                    onPressed: p.userId == user.id
                                        ? null
                                        : () => p.role == 'cohost'
                                            ? hostControls.demoteToAudience(widget.roomId, p.userId)
                                            : hostControls.promoteToCohost(widget.roomId, p.userId),
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
                  if (!isHost) ...[
                    if (!isCohost)
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stage & camera access', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 6),
                              Text(
                                allowCamRequests
                                    ? 'Request host approval to speak and use your camera in this room.'
                                    : 'Host has paused cam access requests for this room.',
                              ),
                              const SizedBox(height: 8),
                              myCamRequestAsync.when(
                                data: (request) {
                                  final requestStatus = request?.status;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: !allowCamRequests || hostId.isEmpty || requestStatus == 'pending'
                                            ? null
                                            : () async {
                                                try {
                                                  await camAccessController.requestAccess(
                                                    roomId: widget.roomId,
                                                    requesterId: user.id,
                                                    broadcasterId: hostId,
                                                  );
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Cam access request sent.')),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Could not send request: $e')),
                                                  );
                                                }
                                              },
                                        icon: const Icon(Icons.videocam_outlined),
                                        label: const Text('Request Cam Access'),
                                      ),
                                      if (requestStatus != null)
                                        Chip(label: Text('Status: $requestStatus')),
                                    ],
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text('Could not load request status: $e'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Presence header and avatar strip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          participantCountAsync.when(
                              data: (participantCount) => Text(
                                '$participantCount in room',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            loading: () => const SizedBox(width: 60, child: LinearProgressIndicator()),
                            error: (e, _) => const Text('—'),
                          ),
                          const Spacer(),
                          hostAsync.when(
                            data: (host) => host != null
                                ? CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.amber,
                                    child: Text('H', style: TextStyle(color: Colors.white)),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          coHostsAsync.when(
                            data: (cohosts) => Row(
                              children: cohosts.map((cohost) => Padding(
                                padding: const EdgeInsets.only(left: 2.0),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.blue,
                                  child: Text('C', style: TextStyle(color: Colors.white)),
                                ),
                              )).toList(),
                            ),
                            loading: () => const SizedBox(width: 32, child: LinearProgressIndicator()),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                              isMe: msg.senderId == user.id,
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                  participantsAsync.when(
                    data: (participants) {
                      final hasBlockedParticipant = participants.any((p) {
                        final participantId = p.userId.trim();
                        if (participantId.isEmpty || participantId == user.id) {
                          return false;
                        }
                        return _excludedUserIds.contains(participantId);
                      });

                      if (!hasBlockedParticipant) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Blocked relationship detected in this room. Leave to continue safely.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
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
                            enabled: !isSending
                                && participant?.isMuted != true
                                && participant?.isBanned != true
                                && !hasBlockedParticipantInRoom,
                            decoration: InputDecoration(
                              hintText: participant?.isMuted == true
                                  ? 'You are muted'
                                  : participant?.isBanned == true
                                      ? 'You are banned'
                                      : hasBlockedParticipantInRoom
                                          ? 'Blocked relationship in room'
                                        : !allowChat
                                          ? 'Chat disabled by host'
                                      : 'Type your message...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSending
                                  || participant?.isMuted == true
                                  || participant?.isBanned == true
                                    || !allowChat
                                  || hasBlockedParticipantInRoom
                              ? null
                              : () async {
                                  if (messageController.text.trim().isEmpty) return;
                                  if (slowModeSeconds > 0 && lastMessageTime != null) {
                                    final secondsSinceLastMessage = DateTime.now().difference(lastMessageTime!).inSeconds;
                                    if (secondsSinceLastMessage < slowModeSeconds) {
                                      setState(() {
                                        cooldownMessage =
                                            'Slow mode is on. Wait ${slowModeSeconds - secondsSinceLastMessage}s.';
                                      });
                                      return;
                                    }
                                  }

                                  setState(() => isSending = true);
                                  try {
                                    await sendMessage(messageController.text.trim());
                                    lastMessageTime = DateTime.now();
                                    cooldownMessage = '';
                                    messageController.clear();

                                    if (!_hasTrackedFirstMessage) {
                                      _hasTrackedFirstMessage = true;
                                      await AnalyticsService().logEvent('first_message_sent', params: {
                                        'room_id': widget.roomId,
                                        'user_id': user.id,
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setState(() => isSending = false);
                                    }
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
                  await _disconnectCall();
                  await _leaveRoom();
                  if (context.mounted) context.pop();
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
