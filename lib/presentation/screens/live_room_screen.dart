import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

import '../../config/agora_constants.dart';
import '../../models/moderation_model.dart';
import '../../models/room_policy_model.dart';
import '../../models/room_participant_model.dart';
import '../providers/user_provider.dart';
import '../../features/room/providers/room_firestore_provider.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/providers/presence_provider.dart';
import '../../features/room/widgets/message_bubble.dart';
import '../../features/room/widgets/room_control_sheets.dart';
import '../../features/room/providers/cam_access_provider.dart';
import '../../features/room/providers/mic_access_provider.dart';
import '../../features/room/providers/host_controls_provider.dart';
import '../../features/room/providers/host_provider.dart';
import '../../features/room/providers/room_policy_provider.dart';
import '../../features/room/providers/room_gift_provider.dart';
import '../../features/room/room_permissions.dart';
import '../../presentation/providers/wallet_provider.dart';
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

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen>
  with WidgetsBindingObserver {
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
  bool _isMicActionInFlight = false;
  bool _isVideoActionInFlight = false;
  String? _callError;
  Set<String> _excludedUserIds = const <String>{};
  String? _appliedMediaRole;
  bool _isHandlingParticipantRemoval = false;
  Timer? _presenceHeartbeatTimer;
  DateTime? _roomJoinedAt;
  int _lastRenderedMessageCount = 0;
  final Set<String> _shownGiftEventIds = {};
  final List<_GiftToast> _giftToasts = [];
  Timer? _giftToastTimer;
  ProviderSubscription<AsyncValue<List<RoomGiftEvent>>>? _giftEventsSubscription;

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

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
    WidgetsBinding.instance.addObserver(this);
    messageController = TextEditingController();
    scrollController = ScrollController();

    final user = ref.read(userProvider);
    if (user != null) {
      _firestore = ref.read(roomFirestoreProvider);
      _joinedUserId = user.id;
      _joinRoom(user.id);
    }

    _giftEventsSubscription = ref.listenManual<AsyncValue<List<RoomGiftEvent>>>(
      roomGiftStreamProvider(widget.roomId),
      (previous, next) {
        next.whenData((events) {
          final joinedAt = _roomJoinedAt;
          for (final event in events) {
            if (_shownGiftEventIds.contains(event.id)) continue;
            if (joinedAt != null && event.sentAt.isBefore(joinedAt)) {
              _shownGiftEventIds.add(event.id);
              continue;
            }
            _shownGiftEventIds.add(event.id);
            _addGiftToast(event);
          }
        });
      },
    );
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
    final token = _asString(data['token']);
    final serverAppId = _asString(data['appId']);
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
    service.onSpeakerActivityChanged = () {
      if (mounted) {
        setState(() {});
      }
    };

    try {
      developer.log(
        'Starting Agora call connection for userId: $userId, canBroadcast: $canBroadcast',
        name: 'LiveRoom',
      );
      final rtcUid = _buildRtcUid(userId);
      final credentials = await _fetchAgoraToken(
        channelName: widget.roomId,
        rtcUid: rtcUid,
      );
      developer.log('Agora token fetched successfully', name: 'LiveRoom');
      await service.initialize(credentials.appId);
      developer.log('Agora service initialized', name: 'LiveRoom');
      await service.joinChannel(
        credentials.token,
        widget.roomId,
        rtcUid,
        asBroadcaster: canBroadcast,
      );
      developer.log('Successfully joined Agora channel', name: 'LiveRoom');
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
    } catch (e, stackTrace) {
      developer.log(
        'Error connecting to Agora',
        name: 'LiveRoom',
        error: e,
        stackTrace: stackTrace,
      );
      await service.dispose();
      if (mounted) {
        setState(() {
          final mappedError = _mapMediaError(e, canBroadcast: canBroadcast);
          _callError = canBroadcast
              ? mappedError
              : 'Live media preview is unavailable right now, but room chat and requests still work. $mappedError';
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
    if (service == null || !_isCallReady || _isMicActionInFlight) return;
    final next = !_isMicMuted;
    setState(() => _isMicActionInFlight = true);
    try {
      await service.mute(next);
      if (mounted) {
        setState(() {
          _isMicMuted = next;
        });
      }
    } catch (e) {
      _showSnackBar(_mapMediaError(e, canBroadcast: true));
    } finally {
      if (mounted) {
        setState(() => _isMicActionInFlight = false);
      }
    }
  }

  Future<void> _toggleVideo() async {
    final service = _agoraService;
    if (service == null || !_isCallReady || _isVideoActionInFlight) return;
    final next = !_isVideoEnabled;
    setState(() => _isVideoActionInFlight = true);
    try {
      await service.enableVideo(next);
      if (mounted) {
        setState(() {
          _isVideoEnabled = next;
        });
      }
    } catch (e) {
      _showSnackBar(_mapMediaError(e, canBroadcast: true));
    } finally {
      if (mounted) {
        setState(() => _isVideoActionInFlight = false);
      }
    }
  }

  String _mapMediaError(Object error, {required bool canBroadcast}) {
    if (error is AgoraServiceException) {
      switch (error.code) {
        case 'permission-denied':
          return canBroadcast
              ? 'Camera/microphone access was denied. Allow permissions in browser site settings, then rejoin the room.'
              : 'Microphone access was denied. Allow permission in browser site settings, then retry.';
        case 'no-media-devices':
          return 'No camera/microphone was detected. Connect a device and retry.';
        case 'device-in-use':
          return 'Camera/microphone is busy in another app or tab. Close the other session and retry.';
        case 'unsupported-browser':
          return 'This browser is not fully supported for live media. Use the latest Chrome or Edge.';
        case 'insecure-context':
          return 'Live media requires HTTPS (or localhost). Open MixVy on a secure origin.';
        default:
          return error.message;
      }
    }

    final lower = error.toString().toLowerCase();
    if (lower.contains('unsupported browser') ||
        lower.contains('webrtc is not supported') ||
        lower.contains('not supported on this browser')) {
      return 'This browser is not fully supported for live media. Use the latest Chrome or Edge.';
    }
    if (lower.contains('secure context') ||
        lower.contains('only secure origins')) {
      return 'Live media requires HTTPS (or localhost). Open MixVy on a secure origin.';
    }
    if (lower.contains('permission') || lower.contains('denied')) {
      return canBroadcast
          ? 'Camera/microphone permission denied. Enable permissions in app settings and retry.'
          : 'Microphone permission denied. Enable permissions in app settings and retry.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network issue while connecting audio/video. Check your connection and retry.';
    }
    if (lower.contains('camera') || lower.contains('microphone') || lower.contains('device')) {
      return 'Camera or microphone is unavailable on this device.';
    }
    return 'Audio/video operation failed. Please retry.';
  }

  void _startPresenceHeartbeat(String userId) {
    _presenceHeartbeatTimer?.cancel();
    final presenceController = ref.read(roomPresenceControllerProvider);
    presenceController.setOnline(roomId: widget.roomId, userId: userId);
    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      presenceController.heartbeat(roomId: widget.roomId, userId: userId);
    });
  }

  Future<void> _stopPresenceHeartbeat() async {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    final userId = _joinedUserId;
    if (userId == null) {
      return;
    }
    try {
      await ref
          .read(roomPresenceControllerProvider)
          .setOffline(roomId: widget.roomId, userId: userId);
    } catch (_) {
      // Best-effort cleanup.
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

    final canBroadcast = role == 'host' || role == 'cohost' || role == 'stage';
    final videoEnabled = role == 'host' || role == 'cohost';
    await service.setBroadcaster(canBroadcast);
    await service.mute(!canBroadcast);
    await service.enableVideo(videoEnabled);

    if (!mounted) {
      return;
    }

    setState(() {
      _appliedMediaRole = role;
      _isMicMuted = !canBroadcast;
      _isVideoEnabled = videoEnabled;
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
    final actorRole =
        currentParticipant?.role ?? (isHost ? 'host' : (isModerator ? 'moderator' : 'audience'));
    final canManageParticipant = RoomPermissions.canManageParticipant(
      actorRole: actorRole,
      actorUserId: currentUserId,
      targetRole: target.role,
      targetUserId: target.userId,
      hostUserId: hostId,
    );
    final canHostOnlyManage = RoomPermissions.isHost(actorRole) && !isSelf && !targetIsHost;
    final canTransferOwnership = RoomPermissions.canTransferOwnership(
      actorRole: actorRole,
      actorUserId: currentUserId,
      targetUserId: target.userId,
      hostUserId: hostId,
    );
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
          if (canHostOnlyManage)
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
          if (canHostOnlyManage)
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
          if (canTransferOwnership)
            RoomActionItem(
              label: 'Transfer room ownership',
              icon: Icons.workspace_premium_outlined,
              destructive: true,
              onTap: () => runAction(() async {
                final confirmed = await _confirmAction(
                  title: 'Transfer ownership',
                  message:
                      'Make ${target.userId} the new room host? You will be moved to cohost.',
                  confirmLabel: 'Transfer',
                );
                if (!confirmed) {
                  return;
                }
                try {
                  await hostControls.transferHost(
                    roomId: widget.roomId,
                    fromUserId: currentUserId,
                    toUserId: target.userId,
                  );
                  _showSnackBar('${target.userId} is now the room host.');
                } catch (e) {
                  _showSnackBar('Could not transfer ownership: $e');
                }
              }),
            ),
          if (canHostOnlyManage)
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
        final username = _asString(data['username']);
        final avatarUrl = _asString(data['avatarUrl']);
        presentationByUserId[userDoc.id] = RoomUserPresentation(
          displayName: username.isEmpty ? userDoc.id : username,
          avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
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

      final hostId = _asString(roomDoc.data()?['hostId']);
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
          final participantId = _asString(participantData['userId'], fallback: doc.id);
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

      final isLocked = _asBool(roomDoc.data()?['isLocked']);
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
          ? _asString(doc.data()?['role'], fallback: 'audience')
          : (hostId == userId ? 'host' : 'audience');
      await _connectCall(
        userId,
        canBroadcast:
            participantRole == 'host' ||
            participantRole == 'cohost' ||
            participantRole == 'stage',
      );

      if (!_hasTrackedRoomJoin) {
        _hasTrackedRoomJoin = true;
        await AnalyticsService().logEvent(
          'room_joined',
          params: {'room_id': widget.roomId, 'user_id': userId},
        );
      }
      _startPresenceHeartbeat(userId);
      _roomJoinedAt = DateTime.now();
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
      await _stopPresenceHeartbeat();
      await docRef.delete();
    } catch (_) {
      // Best-effort cleanup when users leave a room.
    }
  }

  String _requestStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Waiting for host approval';
      case 'approved':
        return 'Approved';
      case 'denied':
        return 'Denied';
      case 'expired':
        return 'Expired';
      default:
        return 'Not requested';
    }
  }

  String _cameraAccessHint({
    required String role,
    required String? camRequestStatus,
  }) {
    if (RoomPermissions.canUseCamera(role)) {
      return 'Camera controls are unlocked. Use the camera button above to turn video on.';
    }
    if (camRequestStatus == 'pending') {
      return 'Your camera request is pending. The host must approve it before your camera controls unlock.';
    }
    if (camRequestStatus == 'denied') {
      return 'Your last camera request was denied. You can send another request when you are ready.';
    }
    if (camRequestStatus == 'expired') {
      return 'Your last camera request expired. Send a new request to unlock camera controls.';
    }
    return 'You are currently in the audience. Request camera access to unlock the camera button.';
  }

  String _micAccessHint({
    required String role,
    required String? micRequestStatus,
  }) {
    if (RoomPermissions.canUseMic(role)) {
      return 'Mic controls are unlocked.';
    }
    if (micRequestStatus == 'pending') {
      return 'Your mic request is pending host approval.';
    }
    if (micRequestStatus == 'denied') {
      return 'Your last mic request was denied.';
    }
    if (micRequestStatus == 'expired') {
      return 'Your last mic request expired.';
    }
    return 'Request mic access if you want to speak without camera.';
  }

  void _addGiftToast(RoomGiftEvent event) {
    final catalog = RoomGiftCatalog.findById(event.giftId);
    final toast = _GiftToast(
      senderId: event.senderId,
      senderName: event.senderName.isNotEmpty ? event.senderName : event.senderId,
      giftEmoji: catalog?.emoji ?? '🎁',
      giftName: catalog?.displayName ?? event.giftId,
      coinCost: event.coinCost,
    );
    if (mounted) {
      setState(() => _giftToasts.insert(0, toast));
      _giftToastTimer?.cancel();
      _giftToastTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _giftToasts.clear());
      });
    }
  }

  Future<void> _showGiftSheet({
    required String hostId,
    required String hostName,
    required String senderName,
    required int coinBalance,
  }) async {
    RoomGiftItem? selectedGift;
    bool isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: MediaQuery.of(ctx).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Send a Gift to $hostName',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.monetization_on, size: 14),
                          label: Text('$coinBalance coins'),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: RoomGiftCatalog.items.length,
                    itemBuilder: (ctx, i) {
                      final gift = RoomGiftCatalog.items[i];
                      final chosen = selectedGift?.id == gift.id;
                      return GestureDetector(
                        onTap: isSending
                            ? null
                            : () => setSheetState(() => selectedGift = gift),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: chosen
                                ? Theme.of(ctx).colorScheme.primaryContainer
                                : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: chosen
                                ? Border.all(
                                    color: Theme.of(ctx).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                gift.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gift.displayName,
                                style: Theme.of(ctx).textTheme.labelSmall,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${gift.coinCost}🪙',
                                style: Theme.of(ctx).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: selectedGift == null ||
                                isSending ||
                                coinBalance < (selectedGift?.coinCost ?? 0)
                            ? null
                            : () async {
                                setSheetState(() => isSending = true);
                                try {
                                  await ref
                                      .read(roomGiftControllerProvider)
                                      .sendGift(
                                        roomId: widget.roomId,
                                        receiverId: hostId,
                                        senderName: senderName,
                                        gift: selectedGift!,
                                      );
                                  if (sheetCtx.mounted) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                  _showSnackBar(
                                    'Sent ${selectedGift!.emoji} ${selectedGift!.displayName}!',
                                  );
                                } catch (e) {
                                  if (sheetCtx.mounted) {
                                    setSheetState(() => isSending = false);
                                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not send gift: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.card_giftcard),
                        label: Text(
                          selectedGift == null
                              ? 'Select a gift'
                              : coinBalance < (selectedGift?.coinCost ?? 0)
                                  ? 'Not enough coins'
                                  : 'Send ${selectedGift!.emoji} for ${selectedGift!.coinCost} coins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceHeartbeatTimer?.cancel();
    _giftToastTimer?.cancel();
    _giftEventsSubscription?.close();
    unawaited(_disconnectCall());
    unawaited(_leaveRoom());
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final userId = _joinedUserId;
    if (userId == null) {
      return;
    }
    final presenceController = ref.read(roomPresenceControllerProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _presenceHeartbeatTimer?.cancel();
      _presenceHeartbeatTimer = null;
      presenceController.setOffline(roomId: widget.roomId, userId: userId);
    } else if (state == AppLifecycleState.resumed) {
      _startPresenceHeartbeat(userId);
    }
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
    final presenceAsync = ref.watch(roomPresenceStreamProvider(widget.roomId));
    final hostAsync = ref.watch(hostProvider(widget.roomId));
    final coHostsAsync = ref.watch(coHostsProvider(widget.roomId));
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final camRequestsAsync = ref.watch(
      roomCamAccessRequestsProvider(widget.roomId),
    );
    final micRequestsAsync = ref.watch(
      roomMicAccessRequestsProvider(widget.roomId),
    );
    final hostControls = ref.read(hostControlsProvider);
    final camAccessController = ref.read(camAccessControllerProvider);
    final micAccessController = ref.read(micAccessControllerProvider);
    final roomPolicyController = ref.read(roomPolicyControllerProvider);
    final walletAsync = ref.watch(walletDetailsProvider);
    final topGifters = ref.watch(topGiftersProvider(widget.roomId));

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
        final myMicRequestAsync = ref.watch(
          myMicAccessRequestProvider((
            roomId: widget.roomId,
            requesterId: user.id,
          )),
        );
        final camRequestStatus = myCamRequestAsync.valueOrNull?.status;
        final micRequestStatus = myMicRequestAsync.valueOrNull?.status;
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
            final hostId = _asString(roomData?['hostId']);
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
              body: Stack(
                children: [
                  Column(
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
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _agoraService!.localSpeaking
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _agoraService!.canRenderLocalView
                                    ? _agoraService!.getLocalView()
                                    : ColoredBox(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.videocam_off,
                                                size: 40,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                RoomPermissions.canUseCamera(role)
                                                    ? 'Camera is available. Use the camera button to start video.'
                                                    : 'Camera unlocks after host approval.',
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
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
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _agoraService!
                                                  .isRemoteSpeaking(remoteUid)
                                              ? Colors.green
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _agoraService!.getRemoteView(
                                          remoteUid,
                                          widget.roomId,
                                        ),
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
                                onPressed: RoomPermissions.canUseMic(role) &&
                                        !_isMicActionInFlight
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
                                onPressed:
                                  RoomPermissions.canUseCamera(role) &&
                                    !_isVideoActionInFlight
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
                          const SizedBox(height: 8),
                          Text(
                            _cameraAccessHint(
                              role: role,
                              camRequestStatus: camRequestStatus,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
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
                                      SizedBox(
                                        width: 220,
                                        child: DropdownButtonFormField<int>(
                                          initialValue:
                                              roomPolicyAsync.valueOrNull
                                                  ?.micLimit ??
                                              6,
                                          decoration: const InputDecoration(
                                            labelText: 'Mic seats',
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 2,
                                              child: Text('2 seats'),
                                            ),
                                            DropdownMenuItem(
                                              value: 4,
                                              child: Text('4 seats'),
                                            ),
                                            DropdownMenuItem(
                                              value: 6,
                                              child: Text('6 seats'),
                                            ),
                                            DropdownMenuItem(
                                              value: 8,
                                              child: Text('8 seats'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) return;
                                            roomPolicyController.setMicLimit(
                                              widget.roomId,
                                              value,
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: DropdownButtonFormField<int>(
                                          initialValue:
                                              roomPolicyAsync.valueOrNull
                                                  ?.camLimit ??
                                              6,
                                          decoration: const InputDecoration(
                                            labelText: 'Camera seats',
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 2,
                                              child: Text('2 seats'),
                                            ),
                                            DropdownMenuItem(
                                              value: 4,
                                              child: Text('4 seats'),
                                            ),
                                            DropdownMenuItem(
                                              value: 6,
                                              child: Text('6 seats'),
                                            ),
                                            DropdownMenuItem(
                                              value: 8,
                                              child: Text('8 seats'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) return;
                                            roomPolicyController.setCamLimit(
                                              widget.roomId,
                                              value,
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 240,
                                        child: DropdownButtonFormField<String>(
                                          initialValue:
                                              roomPolicyAsync.valueOrNull
                                                  ?.defaultCamViewPolicy
                                                  .name ??
                                              CamViewPolicy.approvedOnly.name,
                                          decoration: const InputDecoration(
                                            labelText: 'Default cam policy',
                                          ),
                                          items: CamViewPolicy.values
                                              .map(
                                                (policy) => DropdownMenuItem(
                                                  value: policy.name,
                                                  child: Text(policy.name),
                                                ),
                                              )
                                              .toList(growable: false),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            final policy = CamViewPolicy.values
                                                .firstWhere(
                                                  (item) =>
                                                      item.name == value,
                                                  orElse: () =>
                                                      CamViewPolicy.approvedOnly,
                                                );
                                            roomPolicyController
                                                .setDefaultCamViewPolicy(
                                                  widget.roomId,
                                                  policy,
                                                );
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 220,
                                        child: DropdownButtonFormField<String>(
                                          initialValue:
                                              roomPolicyAsync
                                                  .valueOrNull
                                                  ?.visibility
                                                  .name ??
                                              MixVyRoomVisibility.public.name,
                                          decoration: const InputDecoration(
                                            labelText: 'Room visibility',
                                          ),
                                          items: MixVyRoomVisibility.values
                                              .map(
                                                (visibility) =>
                                                    DropdownMenuItem(
                                                      value: visibility.name,
                                                      child: Text(
                                                        visibility.name,
                                                      ),
                                                    ),
                                              )
                                              .toList(growable: false),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            final visibility =
                                                MixVyRoomVisibility.values
                                                    .firstWhere(
                                                      (item) =>
                                                          item.name == value,
                                                      orElse: () =>
                                                          MixVyRoomVisibility
                                                              .public,
                                                    );
                                            roomPolicyController
                                                .setVisibility(
                                                  widget.roomId,
                                                  visibility,
                                                );
                                          },
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'Mic request queue',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  micRequestsAsync.when(
                                    data: (requests) {
                                      final pendingRequests = requests
                                          .where(
                                            (request) =>
                                                request.status == 'pending',
                                          )
                                          .toList(growable: false);
                                      if (pendingRequests.isEmpty) {
                                        return const Text(
                                          'No pending mic requests.',
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
                                                    'Mic request from ${request.requesterId}',
                                                  ),
                                                  subtitle: Text(
                                                    'Approve for stage audio access • Priority ${request.priority}',
                                                  ),
                                                  trailing: Wrap(
                                                    spacing: 8,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () =>
                                                            micAccessController
                                                                .bumpPriority(
                                                                  widget.roomId,
                                                                  request.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.arrow_upward,
                                                        ),
                                                        tooltip: 'Bump priority',
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            micAccessController
                                                                .lowerPriority(
                                                                  widget.roomId,
                                                                  request.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.arrow_downward,
                                                        ),
                                                        tooltip: 'Lower priority',
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            micAccessController
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
                                                            micAccessController
                                                                .denyRequest(
                                                                  widget.roomId,
                                                                  request.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.cancel_outlined,
                                                        ),
                                                        tooltip: 'Deny',
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            micAccessController
                                                                .expireNow(
                                                                  widget.roomId,
                                                                  request.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.timer_off_outlined,
                                                        ),
                                                        tooltip: 'Expire now',
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
                                        Text('Could not load mic requests: $e'),
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
                                ? 'Request host approval to unlock your camera in this room. After approval, the camera button above becomes available.'
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
                                        label: const Text('Request Camera Access'),
                                      ),
                                      if (requestStatus != null)
                                        Chip(
                                          avatar: Icon(
                                            requestStatus == 'approved'
                                                ? Icons.check_circle_outline
                                                : requestStatus == 'pending'
                                                ? Icons.hourglass_top
                                                : Icons.info_outline,
                                            size: 16,
                                          ),
                                          label: Text(
                                            _requestStatusLabel(requestStatus),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) =>
                                    Text('Could not load request status: $e'),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _micAccessHint(
                                  role: role,
                                  micRequestStatus: micRequestStatus,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              myMicRequestAsync.when(
                                data: (request) {
                                  final requestStatus = request?.status;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed:
                                            !allowMicRequests ||
                                                hostId.isEmpty ||
                                                requestStatus == 'pending'
                                            ? null
                                            : () async {
                                                try {
                                                  await micAccessController
                                                      .requestAccess(
                                                        roomId: widget.roomId,
                                                        requesterId: user.id,
                                                        hostId: hostId,
                                                      );
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Mic access request sent.',
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
                                        icon: const Icon(Icons.mic_none),
                                        label: const Text('Request Mic Access'),
                                      ),
                                      if (requestStatus != null)
                                        Chip(
                                          avatar: Icon(
                                            requestStatus == 'approved'
                                                ? Icons.check_circle_outline
                                                : requestStatus == 'pending'
                                                ? Icons.hourglass_top
                                                : Icons.info_outline,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Mic: ${_requestStatusLabel(requestStatus)}',
                                          ),
                                        ),
                                    ],
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) =>
                                    Text('Could not load mic request status: $e'),
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
                          presenceAsync.when(
                            data: (presence) {
                              final activeCutoff = DateTime.now().subtract(
                                const Duration(seconds: 50),
                              );
                              final onlineCount = presence
                                  .where(
                                    (entry) =>
                                        entry.isOnline &&
                                        (entry.lastHeartbeatAt == null ||
                                            entry.lastHeartbeatAt!
                                                .isAfter(activeCutoff)),
                                  )
                                  .length;
                              return Chip(
                                avatar: const Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 10,
                                ),
                                label: Text('$onlineCount online'),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
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
                  if (topGifters.isNotEmpty)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: topGifters.length,
                        separatorBuilder: (_, separatorIndex) =>
                            const SizedBox(width: 6),
                        itemBuilder: (ctx, i) {
                          final gifter = topGifters[i];
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            label: Text(
                              '${gifter.displayName} - ${gifter.totalCoins} coins',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: messageStreamAsync.when(
                      data: (messages) {
                        if (messages.length != _lastRenderedMessageCount) {
                          _lastRenderedMessageCount = messages.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (scrollController.hasClients) {
                              scrollController.jumpTo(
                                scrollController.position.maxScrollExtent,
                              );
                            }
                          });
                        }
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
                        if (allowGifts &&
                            !isHost &&
                            hostId.isNotEmpty &&
                            hostId != user.id)
                          IconButton(
                            tooltip: 'Send a gift',
                            icon: const Icon(Icons.card_giftcard),
                            onPressed: () => _showGiftSheet(
                              hostId: hostId,
                              hostName: 'Host',
                              senderName: user.username,
                              coinBalance:
                                  walletAsync.valueOrNull?.coinBalance ?? 0,
                            ),
                          ),
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
              if (_giftToasts.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Column(
                      children: _giftToasts.take(3).map((toast) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                toast.giftEmoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${toast.senderName} sent ${toast.giftName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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

// ---------------------------------------------------------------------------
// Gift toast data class
// ---------------------------------------------------------------------------

class _GiftToast {
  final String senderId;
  final String senderName;
  final String giftEmoji;
  final String giftName;
  final int coinCost;

  const _GiftToast({
    required this.senderId,
    required this.senderName,
    required this.giftEmoji,
    required this.giftName,
    required this.coinCost,
  });
}
