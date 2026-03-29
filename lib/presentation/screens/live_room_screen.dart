import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

import '../../config/agora_constants.dart';
import '../../models/moderation_model.dart';
import '../../models/room_participant_model.dart';
import '../providers/user_provider.dart';
import '../../features/room/providers/room_firestore_provider.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/widgets/message_bubble.dart';
import '../../features/room/widgets/room_control_sheets.dart';
import '../../features/room/providers/cam_access_provider.dart';
import '../../features/room/providers/host_controls_provider.dart';
import '../../features/room/providers/host_provider.dart';
import '../../features/room/providers/room_policy_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/agora_service.dart';
import '../../services/follow_service.dart';
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
  bool _isHandlingParticipantRemoval = false;

  bool _looksLikeAgoraAppId(String value) {
    final trimmed = value.trim();
    if (trimmed.length != 32) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(trimmed);
  }

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

  Future<({String token, String appId})> _fetchAgoraToken({
    required String channelName,
    required int rtcUid,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'generateAgoraToken',
    );
    final result = await callable.call<Map<String, dynamic>>({
      'channelName': channelName,
      'rtcUid': rtcUid,
    });
    final data = Map<String, dynamic>.from(result.data);
    final token = (data['token'] as String?)?.trim() ?? '';
    final serverAppId = (data['appId'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Missing Agora token from backend response.');
    }

    final localAppId = AgoraConstants.appId.trim();
    final resolvedAppId = serverAppId.isNotEmpty ? serverAppId : localAppId;
    if (!_looksLikeAgoraAppId(resolvedAppId)) {
      throw Exception(
        'Invalid AGORA_APP_ID. Expected a 32-character Agora App ID.',
      );
    }

    return (token: token, appId: resolvedAppId);
  }

  Future<void> _connectCall(String userId, {required bool canBroadcast}) async {
    if (_isCallConnecting || _isCallReady) return;

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
      print('[LiveRoom] Starting Agora call connection for userId: $userId, canBroadcast: $canBroadcast');
      final rtcUid = _buildRtcUid(userId);
      final credentials = await _fetchAgoraToken(
        channelName: widget.roomId,
        rtcUid: rtcUid,
      );
      print('[LiveRoom] Agora token fetched successfully');
      await service.initialize(credentials.appId);
      print('[LiveRoom] Agora service initialized');
      await service.joinChannel(
        credentials.token,
        widget.roomId,
        rtcUid,
        asBroadcaster: canBroadcast,
      );
      print('[LiveRoom] Successfully joined Agora channel');
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() {
        _agoraService = service;
        _isCallReady = true;
        _appliedMediaRole = canBroadcast ? 'cohost' : 'audience';
        _isMicMuted = !canBroadcast;
        _isVideoEnabled = canBroadcast;
      });
    } catch (e) {
      print('[LiveRoom] Error connecting to Agora: $e');
      await service.dispose();
      if (mounted) {
        setState(() {
          _callError = 'Video connection failed: ${e.toString()}';
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
    await service.setBroadcaster(canBroadcast);
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

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _reportTarget({
    required String targetId,
    required ReportTargetType targetType,
    required String title,
    required String fallbackReason,
  }) async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted != true) {
      return;
    }

    try {
      await ModerationService().reportTarget(
        targetId: targetId,
        targetType: targetType,
        reason: reasonController.text.trim().isEmpty
            ? fallbackReason
            : reasonController.text.trim(),
        details: detailsController.text.trim(),
      );
      _showSnackBar('Report submitted.');
    } catch (e) {
      _showSnackBar('Could not submit report: $e');
    }
  }

  Future<void> _handleForcedRoomExit(String message) async {
    if (_isHandlingParticipantRemoval) {
      return;
    }

    _isHandlingParticipantRemoval = true;
    await _disconnectCall();

    if (!mounted) {
      return;
    }

    setState(() {
      _roomJoinError = message;
      _joinedUserId = null;
    });
    _showSnackBar(message);
    _exitRoom();
  }

  Future<void> _showParticipantActions({
    required RoomParticipantModel target,
    required RoomParticipantModel? currentParticipant,
    required String currentUserId,
    required String hostId,
    required bool isHost,
    required bool isModerator,
    required HostControls hostControls,
    required Map<String, RoomUserPresentation> presentationByUserId,
  }) async {
    final isSelf = target.userId == currentUserId;
    final targetIsHost = target.userId == hostId || target.role == 'host';
    final actorIsModeratorOnly = isModerator && !isHost;
    final canModerateTarget =
        !targetIsHost && (!actorIsModeratorOnly || target.role == 'audience');
    final canManageParticipant =
        !isSelf && (isHost || isModerator) && canModerateTarget;
    final moderationService = ModerationService();
    final followService = FollowService();
    var isBlocked = false;
    var isFollowing = false;

    if (!isSelf) {
      try {
        isBlocked = await moderationService.isBlocked(target.userId);
        isFollowing = await followService.isFollowing(
          currentUserId,
          target.userId,
        );
      } catch (_) {
        isBlocked = false;
        isFollowing = false;
      }
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        Future<void> runAction(Future<void> Function() action) async {
          Navigator.of(sheetContext).pop();
          await action();
        }

        final actions = <RoomActionItem>[
          RoomActionItem(
            label: 'View profile',
            icon: Icons.person_outline,
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.go('/profile/${target.userId}');
            },
          ),
          if (!isSelf)
            RoomActionItem(
              label: isFollowing ? 'Unfollow user' : 'Follow user',
              icon: isFollowing
                  ? Icons.person_remove_outlined
                  : Icons.person_add_alt_1_outlined,
              onTap: () => runAction(() async {
                try {
                  if (isFollowing) {
                    await followService.unfollowUser(target.userId);
                    _showSnackBar('Unfollowed ${target.userId}.');
                  } else {
                    await followService.followUser(target.userId);
                    _showSnackBar('Now following ${target.userId}.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update follow status: $e');
                }
              }),
            ),
          if (!isSelf)
            RoomActionItem(
              label: isBlocked ? 'Unblock user' : 'Block user',
              icon: isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
              destructive: !isBlocked,
              onTap: () => runAction(() async {
                try {
                  if (isBlocked) {
                    await moderationService.unblockUser(target.userId);
                    _showSnackBar('User unblocked.');
                  } else {
                    final confirmed = await _confirmAction(
                      title: 'Block user',
                      message:
                          'You will stop seeing each other in rooms and discovery.',
                      confirmLabel: 'Block',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await moderationService.blockUser(target.userId);
                    _showSnackBar('User blocked.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update block status: $e');
                }
              }),
            ),
          if (!isSelf)
            RoomActionItem(
              label: 'Report user',
              icon: Icons.flag_outlined,
              destructive: true,
              onTap: () => runAction(() {
                return _reportTarget(
                  targetId: target.userId,
                  targetType: ReportTargetType.user,
                  title: 'Report user',
                  fallbackReason: 'In-room user review requested',
                );
              }),
            ),
          if (canManageParticipant)
            RoomActionItem(
              label: target.isMuted ? 'Unmute user chat' : 'Mute user chat',
              icon: target.isMuted
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              onTap: () => runAction(() async {
                try {
                  if (target.isMuted) {
                    await hostControls.unmuteUser(widget.roomId, target.userId);
                    _showSnackBar('${target.userId} can chat again.');
                  } else {
                    await hostControls.muteUser(widget.roomId, target.userId);
                    _showSnackBar('${target.userId} was muted.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update mute status: $e');
                }
              }),
            ),
          if (isHost && !isSelf && !targetIsHost)
            RoomActionItem(
              label: target.role == 'moderator'
                  ? 'Remove moderator'
                  : 'Make moderator',
              icon: target.role == 'moderator'
                  ? Icons.shield_moon_outlined
                  : Icons.shield_outlined,
              onTap: () => runAction(() async {
                try {
                  if (target.role == 'moderator') {
                    await hostControls.demoteToAudience(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} is now audience.');
                  } else {
                    await hostControls.promoteToModerator(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} is now a moderator.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update moderator role: $e');
                }
              }),
            ),
          if (isHost && !isSelf && !targetIsHost)
            RoomActionItem(
              label: target.role == 'cohost'
                  ? 'Move to audience'
                  : 'Invite to stage',
              icon: target.role == 'cohost'
                  ? Icons.keyboard_double_arrow_down
                  : Icons.keyboard_double_arrow_up,
              onTap: () => runAction(() async {
                try {
                  if (target.role == 'cohost') {
                    await hostControls.demoteToAudience(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} moved to the audience.');
                  } else {
                    await hostControls.promoteToCohost(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} invited to the stage.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update role: $e');
                }
              }),
            ),
          if (isHost && !isSelf && !targetIsHost)
            RoomActionItem(
              label: target.isBanned ? 'Unban user' : 'Ban user',
              icon: target.isBanned
                  ? Icons.verified_user_outlined
                  : Icons.gpp_bad_outlined,
              destructive: !target.isBanned,
              onTap: () => runAction(() async {
                try {
                  if (target.isBanned) {
                    await hostControls.unbanUser(widget.roomId, target.userId);
                    _showSnackBar('${target.userId} was unbanned.');
                  } else {
                    final confirmed = await _confirmAction(
                      title: 'Ban user',
                      message:
                          'This removes the user from the room until you unban them.',
                      confirmLabel: 'Ban',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await hostControls.banUser(widget.roomId, target.userId);
                    _showSnackBar('${target.userId} was banned.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update ban status: $e');
                }
              }),
            ),
          if (canManageParticipant)
            RoomActionItem(
              label: 'Remove from room',
              icon: Icons.exit_to_app,
              destructive: true,
              onTap: () => runAction(() async {
                final confirmed = await _confirmAction(
                  title: 'Remove user',
                  message:
                      'This kicks ${target.userId} out of the room right now.',
                  confirmLabel: 'Remove',
                );
                if (!confirmed) {
                  return;
                }
                try {
                  await hostControls.removeUser(widget.roomId, target.userId);
                  _showSnackBar('${target.userId} was removed from the room.');
                } catch (e) {
                  _showSnackBar('Could not remove user: $e');
                }
              }),
            ),
          if (isSelf)
            RoomActionItem(
              label: 'Leave room',
              icon: Icons.logout,
              destructive: true,
              onTap: () => runAction(() async {
                await _disconnectCall();
                await _leaveRoom();
                if (mounted) {
                  context.pop();
                }
              }),
            ),
        ];

        return RoomParticipantActionSheet(
          participant: currentParticipant != null && isSelf
              ? currentParticipant
              : target,
          userPresentation:
              presentationByUserId[target.userId] ??
              RoomUserPresentation(displayName: target.userId),
          currentUserId: currentUserId,
          hostUserId: hostId,
          actions: actions,
        );
      },
    );
  }

  Future<void> _showPeopleSheet({
    required List<RoomParticipantModel> participants,
    required RoomParticipantModel? currentParticipant,
    required String currentUserId,
    required String hostId,
    required bool isHost,
    required bool isModerator,
    required HostControls hostControls,
    required Map<String, RoomUserPresentation> presentationByUserId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: RoomRosterSheet(
            participants: participants,
            presentationByUserId: presentationByUserId,
            currentUserId: currentUserId,
            hostUserId: hostId,
            onParticipantTap: (selected) {
              Navigator.of(sheetContext).pop();
              _showParticipantActions(
                target: selected,
                currentParticipant: currentParticipant,
                currentUserId: currentUserId,
                hostId: hostId,
                isHost: isHost,
                isModerator: isModerator,
                hostControls: hostControls,
                presentationByUserId: presentationByUserId,
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, RoomUserPresentation>> _loadParticipantPresentation({
    required List<RoomParticipantModel> participants,
    required String currentUserId,
    required String currentUsername,
    required String? currentAvatarUrl,
  }) async {
    final firestore = _firestore ?? ref.read(roomFirestoreProvider);
    final participantIds = participants
        .map((participant) => participant.userId.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (firestore == null || participantIds.isEmpty) {
      return const <String, RoomUserPresentation>{};
    }

    final presentationByUserId = <String, RoomUserPresentation>{};
    for (var i = 0; i < participantIds.length; i += 10) {
      final upperBound = (i + 10 > participantIds.length)
          ? participantIds.length
          : i + 10;
      final batchIds = participantIds.sublist(i, upperBound);
      final userDocs = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      for (final userDoc in userDocs.docs) {
        final data = userDoc.data();
        final username = (data['username'] as String?)?.trim() ?? '';
        final avatarUrl = (data['avatarUrl'] as String?)?.trim();
        presentationByUserId[userDoc.id] = RoomUserPresentation(
          displayName: username.isEmpty ? userDoc.id : username,
          avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
        );
      }
    }

    presentationByUserId[currentUserId] = RoomUserPresentation(
      displayName: currentUsername.trim().isEmpty
          ? currentUserId
          : currentUsername.trim(),
      avatarUrl: currentAvatarUrl == null || currentAvatarUrl.trim().isEmpty
          ? presentationByUserId[currentUserId]?.avatarUrl
          : currentAvatarUrl.trim(),
    );

    for (final participantId in participantIds) {
      presentationByUserId.putIfAbsent(
        participantId,
        () => RoomUserPresentation(displayName: participantId),
      );
    }

    return presentationByUserId;
  }

  Future<void> _openPeopleSheet({
    required List<RoomParticipantModel> participants,
    required RoomParticipantModel? currentParticipant,
    required String currentUserId,
    required String currentUsername,
    required String? currentAvatarUrl,
    required String hostId,
    required bool isHost,
    required bool isModerator,
    required HostControls hostControls,
  }) async {
    final presentationByUserId = await _loadParticipantPresentation(
      participants: participants,
      currentUserId: currentUserId,
      currentUsername: currentUsername,
      currentAvatarUrl: currentAvatarUrl,
    );
    if (!mounted) {
      return;
    }

    await _showPeopleSheet(
      participants: participants,
      currentParticipant: currentParticipant,
      currentUserId: currentUserId,
      hostId: hostId,
      isHost: isHost,
      isModerator: isModerator,
      hostControls: hostControls,
      presentationByUserId: presentationByUserId,
    );
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
      final roomDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .get();
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
        final hasBlockingRelationship = await moderationService
            .hasBlockingRelationship(userId, hostId);
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
          final participantId = (participantData['userId'] as String? ?? doc.id)
              .trim();
          return participantId.isNotEmpty &&
              participantId != userId &&
              _excludedUserIds.contains(participantId);
        });
        if (hasBlockedParticipant) {
          setState(
            () => _roomJoinError =
                'You cannot join while a blocked user is in this room.',
          );
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

      final docRef = firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('participants')
          .doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isBanned'] == true) {
          setState(() => _roomJoinError = 'You are banned from this room.');
          _joinedUserId = null;
          _exitRoom();
          return;
        }
        await docRef.update({'lastActiveAt': now});
      } else {
        final participantRole = hostId == userId ? 'host' : 'audience';
        await docRef.set({
          'userId': userId,
          'role': participantRole,
          'isMuted': false,
          'isBanned': false,
          'joinedAt': now,
          'lastActiveAt': now,
        });
      }

      final participantRole = doc.exists
          ? (doc.data()?['role'] as String? ?? 'audience')
          : (hostId == userId ? 'host' : 'audience');
      await _connectCall(
        userId,
        canBroadcast: participantRole == 'host' || participantRole == 'cohost',
      );

      if (!_hasTrackedRoomJoin) {
        _hasTrackedRoomJoin = true;
        await AnalyticsService().logEvent(
          'room_joined',
          params: {'room_id': widget.roomId, 'user_id': userId},
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _roomJoinError = 'Could not join room. Please try again.',
        );
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

    final docRef = firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('participants')
        .doc(userId);
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
      currentParticipantProvider(
        CurrentParticipantParams(roomId: widget.roomId, userId: user.id),
      ),
    );
    final participantsAsync = ref.watch(
      participantsStreamProvider(widget.roomId),
    );
    final messageStreamAsync = ref.watch(messageStreamProvider(widget.roomId));
    final participantCountAsync = ref.watch(
      participantCountProvider(widget.roomId),
    );
    final hostAsync = ref.watch(hostProvider(widget.roomId));
    final coHostsAsync = ref.watch(coHostsProvider(widget.roomId));
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final camRequestsAsync = ref.watch(
      roomCamAccessRequestsProvider(widget.roomId),
    );
    final hostControls = ref.read(hostControlsProvider);
    final camAccessController = ref.read(camAccessControllerProvider);

    return currentParticipantAsync.when(
      data: (participant) {
        final isHost = ref.watch(isHostProvider(participant));
        final isCohost = ref.watch(isCohostProvider(participant));
        final isModerator = participant?.role == 'moderator';
        final role = participant?.role ?? 'audience';
        final myCamRequestAsync = ref.watch(
          myCamAccessRequestProvider((
            roomId: widget.roomId,
            requesterId: user.id,
          )),
        );
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
            final allowGifts = roomPolicyAsync.valueOrNull?.allowGifts ?? true;
            final allowMicRequests =
                roomPolicyAsync.valueOrNull?.allowMicRequests ?? true;
            // Ban enforcement
            if (participant?.isBanned == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleForcedRoomExit('You were banned from this room.');
              });
              return const Scaffold(
                body: Center(child: Text('You are banned from this room.')),
              );
            }
            if (participant == null &&
                _hasTrackedRoomJoin &&
                !_isJoiningRoom &&
                _joinedUserId == user.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleForcedRoomExit('You were removed from this room.');
              });
              return const Scaffold(
                body: Center(child: Text('You were removed from this room.')),
              );
            }
            if (_roomJoinError != null && _joinedUserId == null) {
              return Scaffold(body: Center(child: Text(_roomJoinError!)));
            }
            final sendMessage = ref.read(sendMessageProvider(widget.roomId));
            final participantsInRoom =
                participantsAsync.valueOrNull ?? const [];
            final hasBlockedParticipantInRoom = participantsInRoom.any((
              participantItem,
            ) {
              final participantId = participantItem.userId.trim();
              if (participantId.isEmpty || participantId == user.id) {
                return false;
              }
              return _excludedUserIds.contains(participantId);
            });
            final allowChat = roomPolicyAsync.valueOrNull?.allowChat ?? true;
            final allowCamRequests =
                roomPolicyAsync.valueOrNull?.allowCamRequests ?? true;
            if (isLocked && !isHost && !isCohost && !isModerator) {
              return const Scaffold(
                body: Center(child: Text('Room is locked.')),
              );
            }
            return Scaffold(
              appBar: AppBar(
                title: Text('Live Room ($role)'),
                actions: [
                  IconButton(
                    tooltip: 'People in room',
                    onPressed: participantsInRoom.isEmpty
                        ? null
                        : () => _openPeopleSheet(
                            participants: participantsInRoom,
                            currentParticipant: participant,
                            currentUserId: user.id,
                            currentUsername: user.username,
                            currentAvatarUrl: user.avatarUrl,
                            hostId: hostId,
                            isHost: isHost,
                            isModerator: isModerator,
                            hostControls: hostControls,
                          ),
                    icon: const Icon(Icons.people_alt_outlined),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'report_room') {
                        _reportTarget(
                          targetId: widget.roomId,
                          targetType: ReportTargetType.room,
                          title: 'Report room',
                          fallbackReason: 'Live room review requested',
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'report_room',
                        child: Text('Report room'),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (_callError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        _callError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_isCallConnecting)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: LinearProgressIndicator(),
                    ),
                  if (_isCallReady && _agoraService != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                                  final remoteUid =
                                      _agoraService!.remoteUids[index];
                                  return SizedBox(
                                    width: 150,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _agoraService!.getRemoteView(
                                        remoteUid,
                                        widget.roomId,
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, unusedIndex) =>
                                    const SizedBox(width: 8),
                                itemCount: _agoraService!.remoteUids.length,
                              ),
                            )
                          else
                            const Text(
                              'Waiting for other participants to join video...',
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: _isMicMuted
                                    ? 'Unmute microphone'
                                    : 'Mute microphone',
                                onPressed: isHost || isCohost
                                    ? _toggleMic
                                    : null,
                                icon: Icon(
                                  _isMicMuted ? Icons.mic_off : Icons.mic,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                tooltip: _isVideoEnabled
                                    ? 'Turn camera off'
                                    : 'Turn camera on',
                                onPressed: isHost || isCohost
                                    ? _toggleVideo
                                    : null,
                                icon: Icon(
                                  _isVideoEnabled
                                      ? Icons.videocam
                                      : Icons.videocam_off,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (isHost)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Host Controls',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: 190,
                                        child: DropdownButtonFormField<int>(
                                          initialValue: slowModeSeconds,
                                          decoration: const InputDecoration(
                                            labelText: 'Slow mode',
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 0,
                                              child: Text('Off'),
                                            ),
                                            DropdownMenuItem(
                                              value: 5,
                                              child: Text('5 seconds'),
                                            ),
                                            DropdownMenuItem(
                                              value: 10,
                                              child: Text('10 seconds'),
                                            ),
                                            DropdownMenuItem(
                                              value: 30,
                                              child: Text('30 seconds'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              hostControls.toggleSlowMode(
                                                widget.roomId,
                                                val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: SwitchListTile.adaptive(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Lock room'),
                                          subtitle: Text(
                                            isLocked
                                                ? 'New listeners blocked'
                                                : 'Room is open',
                                          ),
                                          value: isLocked,
                                          onChanged: (_) => hostControls
                                              .toggleLockRoom(widget.roomId),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: SwitchListTile.adaptive(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Chat'),
                                          subtitle: Text(
                                            allowChat
                                                ? 'Members can message'
                                                : 'Chat paused',
                                          ),
                                          value: allowChat,
                                          onChanged: (_) => hostControls
                                              .toggleAllowChat(widget.roomId),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: SwitchListTile.adaptive(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Mic requests'),
                                          subtitle: Text(
                                            allowMicRequests
                                                ? 'Users can request stage access'
                                                : 'Requests paused',
                                          ),
                                          value: allowMicRequests,
                                          onChanged: (_) => hostControls
                                              .toggleAllowMicRequests(
                                                widget.roomId,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: SwitchListTile.adaptive(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Cam requests'),
                                          subtitle: Text(
                                            allowCamRequests
                                                ? 'Users can request camera'
                                                : 'Camera requests paused',
                                          ),
                                          value: allowCamRequests,
                                          onChanged: (_) => hostControls
                                              .toggleAllowCamRequests(
                                                widget.roomId,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: SwitchListTile.adaptive(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Gifts'),
                                          subtitle: Text(
                                            allowGifts
                                                ? 'Gift interactions enabled'
                                                : 'Gifts paused',
                                          ),
                                          value: allowGifts,
                                          onChanged: (_) => hostControls
                                              .toggleAllowGifts(widget.roomId),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: participantsInRoom.isEmpty
                                            ? null
                                            : () => _openPeopleSheet(
                                                participants:
                                                    participantsInRoom,
                                                currentParticipant: participant,
                                                currentUserId: user.id,
                                                currentUsername: user.username,
                                                currentAvatarUrl:
                                                    user.avatarUrl,
                                                hostId: hostId,
                                                isHost: true,
                                                isModerator: false,
                                                hostControls: hostControls,
                                              ),
                                        icon: const Icon(
                                          Icons.manage_accounts_outlined,
                                        ),
                                        label: const Text('Manage people'),
                                      ),
                                      if (participantsInRoom.isNotEmpty)
                                        Chip(
                                          label: Text(
                                            '${participantsInRoom.length} participants',
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  camRequestsAsync.when(
                                    data: (requests) {
                                      final pendingRequests = requests
                                          .where(
                                            (request) =>
                                                request.status == 'pending',
                                          )
                                          .toList(growable: false);
                                      if (pendingRequests.isEmpty) {
                                        return const Text(
                                          'No pending cam requests.',
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: pendingRequests
                                            .map((request) {
                                              return Card(
                                                child: ListTile(
                                                  title: Text(
                                                    'Cam request from ${request.requesterId}',
                                                  ),
                                                  subtitle: Text(
                                                    'Scope: ${request.decisionScope}',
                                                  ),
                                                  trailing: Wrap(
                                                    spacing: 8,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () =>
                                                            camAccessController
                                                                .approveRequest(
                                                                  widget.roomId,
                                                                  request,
                                                                ),
                                                        icon: const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                        ),
                                                        tooltip: 'Approve',
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            camAccessController
                                                                .denyRequest(
                                                                  widget.roomId,
                                                                  request.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.cancel_outlined,
                                                        ),
                                                        tooltip: 'Deny',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(growable: false),
                                      );
                                    },
                                    loading: () =>
                                        const LinearProgressIndicator(),
                                    error: (e, _) =>
                                        Text('Could not load cam requests: $e'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!isHost) ...[
                    if (!isCohost && !isModerator)
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stage & camera access',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                allowCamRequests
                                    ? 'Request host approval to come on stage and use your mic and camera in this room.'
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
                                        onPressed:
                                            !allowCamRequests ||
                                                hostId.isEmpty ||
                                                requestStatus == 'pending'
                                            ? null
                                            : () async {
                                                try {
                                                  await camAccessController
                                                      .requestAccess(
                                                        roomId: widget.roomId,
                                                        requesterId: user.id,
                                                        broadcasterId: hostId,
                                                      );
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Stage access request sent.',
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Could not send request: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                        icon: const Icon(
                                          Icons.videocam_outlined,
                                        ),
                                        label: const Text(
                                          'Request Stage Access',
                                        ),
                                      ),
                                      if (requestStatus != null)
                                        Chip(
                                          label: Text('Status: $requestStatus'),
                                        ),
                                    ],
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) =>
                                    Text('Could not load request status: $e'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Presence header and avatar strip
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          participantCountAsync.when(
                            data: (participantCount) => Text(
                              '$participantCount in room',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            loading: () => const SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(),
                            ),
                            error: (e, _) => const Text('—'),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'People in room',
                            onPressed: participantsInRoom.isEmpty
                                ? null
                                : () => _openPeopleSheet(
                                    participants: participantsInRoom,
                                    currentParticipant: participant,
                                    currentUserId: user.id,
                                    currentUsername: user.username,
                                    currentAvatarUrl: user.avatarUrl,
                                    hostId: hostId,
                                    isHost: isHost,
                                    isModerator: isModerator,
                                    hostControls: hostControls,
                                  ),
                            icon: const Icon(Icons.people_outline),
                          ),
                          hostAsync.when(
                            data: (host) => host != null
                                ? CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.amber,
                                    child: Text(
                                      'H',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                            ),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          coHostsAsync.when(
                            data: (cohosts) => Row(
                              children: cohosts
                                  .map(
                                    (cohost) => Padding(
                                      padding: const EdgeInsets.only(left: 2.0),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          'C',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            loading: () => const SizedBox(
                              width: 32,
                              child: LinearProgressIndicator(),
                            ),
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
                            scrollController.jumpTo(
                              scrollController.position.maxScrollExtent,
                            );
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
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
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            enabled:
                                !isSending &&
                                participant?.isMuted != true &&
                                participant?.isBanned != true &&
                                !hasBlockedParticipantInRoom,
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
                          onPressed:
                              isSending ||
                                  participant?.isMuted == true ||
                                  participant?.isBanned == true ||
                                  !allowChat ||
                                  hasBlockedParticipantInRoom
                              ? null
                              : () async {
                                  if (messageController.text.trim().isEmpty) {
                                    return;
                                  }
                                  if (slowModeSeconds > 0 &&
                                      lastMessageTime != null) {
                                    final secondsSinceLastMessage =
                                        DateTime.now()
                                            .difference(lastMessageTime!)
                                            .inSeconds;
                                    if (secondsSinceLastMessage <
                                        slowModeSeconds) {
                                      setState(() {
                                        cooldownMessage =
                                            'Slow mode is on. Wait ${slowModeSeconds - secondsSinceLastMessage}s.';
                                      });
                                      return;
                                    }
                                  }

                                  setState(() => isSending = true);
                                  try {
                                    await sendMessage(
                                      messageController.text.trim(),
                                    );
                                    lastMessageTime = DateTime.now();
                                    cooldownMessage = '';
                                    messageController.clear();

                                    if (!_hasTrackedFirstMessage) {
                                      _hasTrackedFirstMessage = true;
                                      await AnalyticsService().logEvent(
                                        'first_message_sent',
                                        params: {
                                          'room_id': widget.roomId,
                                          'user_id': user.id,
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
