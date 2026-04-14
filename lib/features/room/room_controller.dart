import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/mic_access_request_model.dart';
import '../../models/room_participant_model.dart';
import 'controllers/room_state.dart';
import 'providers/host_controls_provider.dart';
import 'providers/mic_access_provider.dart';
import 'providers/participant_providers.dart';
import 'providers/user_cam_permissions_provider.dart';
import 'services/room_session_service.dart';

final roomControllerProvider = NotifierProvider.family
    .autoDispose<RoomController, RoomState, String>(RoomController.new);

class RoomController extends AutoDisposeFamilyNotifier<RoomState, String> {
  RoomSessionService get _sessionService =>
      ref.read(roomSessionServiceProvider);
  HostControls get _hostControls => ref.read(hostControlsProvider);
  MicAccessController get _micAccess => ref.read(micAccessControllerProvider);
  UserCamPermissionsController get _camPermissions =>
      ref.read(userCamPermissionsControllerProvider);

  LiveRoomPhase _phase = LiveRoomPhase.idle;
  String? _currentUserId;
  String? _errorMessage;
  DateTime? _joinedAt;
  Set<String> _excludedUserIds = const <String>{};

  @override
  RoomState build(String roomId) {
    final roomDoc = ref.watch(roomDocStreamProvider(roomId)).valueOrNull;
    final participants =
        ref.watch(participantsStreamProvider(roomId)).valueOrNull ??
        const <RoomParticipantModel>[];

    final hostId = _resolveHostId(roomDoc, participants);
    final userIds = _resolveUserIds(participants);
    final speakerIds = _resolveSpeakerIds(participants, hostId: hostId);
    final camViewersByUser = _resolveCamViewers(userIds);

    final mergedUserIds = <String>{...userIds};
    final normalizedCurrentUserId = _currentUserId?.trim() ?? '';
    if (normalizedCurrentUserId.isNotEmpty) {
      mergedUserIds.add(normalizedCurrentUserId);
    }

    return RoomState(
      phase: _phase,
      roomId: roomId,
      currentUserId: _currentUserId,
      errorMessage: _errorMessage,
      joinedAt: _joinedAt,
      excludedUserIds: _excludedUserIds,
      hostId: hostId,
      userIds: mergedUserIds.toList(growable: false),
      speakerIds: speakerIds,
      camViewersByUser: camViewersByUser,
    );
  }

  String _resolveHostId(
    Map<String, dynamic>? roomDoc,
    List<RoomParticipantModel> participants,
  ) {
    final ownerId = (roomDoc?['ownerId'] as String?)?.trim() ?? '';
    if (ownerId.isNotEmpty) {
      return ownerId;
    }

    final hostId = (roomDoc?['hostId'] as String?)?.trim() ?? '';
    if (hostId.isNotEmpty) {
      return hostId;
    }

    for (final participant in participants) {
      if (participant.role == 'host' || participant.role == 'owner') {
        return participant.userId.trim();
      }
    }
    return '';
  }

  List<String> _resolveUserIds(List<RoomParticipantModel> participants) {
    return participants
        .map((participant) => participant.userId.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<String> _resolveSpeakerIds(
    List<RoomParticipantModel> participants, {
    required String hostId,
  }) {
    final speakers =
        participants.where(_isSpeakerParticipant).toList(growable: false)
          ..sort((left, right) {
            final leftRank = _speakerRank(left, hostId: hostId);
            final rightRank = _speakerRank(right, hostId: hostId);
            if (leftRank != rightRank) {
              return leftRank.compareTo(rightRank);
            }
            return left.joinedAt.compareTo(right.joinedAt);
          });

    return speakers
        .map((participant) => participant.userId.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .take(RoomState.maxSpeakers)
        .toList(growable: false);
  }

  bool _isSpeakerParticipant(RoomParticipantModel participant) {
    if (participant.userId.trim().isEmpty || participant.isBanned) {
      return false;
    }

    final normalizedRole = participant.role.trim().toLowerCase();
    final stageRole =
        normalizedRole == 'host' ||
        normalizedRole == 'owner' ||
        normalizedRole == 'cohost' ||
        normalizedRole == 'stage';

    return stageRole || (participant.micOn && !participant.isMuted);
  }

  int _speakerRank(RoomParticipantModel participant, {required String hostId}) {
    final normalizedRole = participant.role.trim().toLowerCase();
    if (participant.userId == hostId ||
        normalizedRole == 'host' ||
        normalizedRole == 'owner') {
      return 0;
    }
    if (normalizedRole == 'cohost') {
      return 1;
    }
    if (normalizedRole == 'stage') {
      return 2;
    }
    return 3;
  }

  Map<String, List<String>> _resolveCamViewers(List<String> userIds) {
    final result = <String, List<String>>{};
    for (final userId in userIds) {
      result[userId] =
          (ref.watch(userCamAllowedViewersProvider(userId)).valueOrNull ??
                  const <String>[])
              .map((viewerId) => viewerId.trim())
              .where((viewerId) => viewerId.isNotEmpty)
              .toSet()
              .toList(growable: false);
    }
    return result;
  }

  Future<RoomJoinResult> joinRoom(String userId) async {
    final normalizedUserId = userId.trim();
    if (_phase == LiveRoomPhase.joining ||
        (state.isJoined && state.currentUserId == normalizedUserId)) {
      return RoomJoinResult.success(
        joinedAt: state.joinedAt ?? DateTime.now(),
        excludedUserIds: state.excludedUserIds,
      );
    }

    _phase = LiveRoomPhase.joining;
    _currentUserId = normalizedUserId;
    _errorMessage = null;
    state = state.copyWith(
      phase: _phase,
      currentUserId: _currentUserId,
      errorMessage: null,
    );

    final result = await _sessionService.joinRoom(
      roomId: arg,
      userId: normalizedUserId,
    );
    if (!result.isSuccess) {
      _phase = LiveRoomPhase.error;
      _currentUserId = null;
      _errorMessage = result.errorMessage;
      _joinedAt = null;
      _excludedUserIds = result.excludedUserIds;
      state = state.copyWith(
        phase: _phase,
        currentUserId: null,
        errorMessage: _errorMessage,
        joinedAt: null,
        excludedUserIds: _excludedUserIds,
      );
      return result;
    }

    _phase = LiveRoomPhase.joined;
    _joinedAt = result.joinedAt;
    _excludedUserIds = result.excludedUserIds;
    _errorMessage = null;
    state = state.copyWith(
      phase: _phase,
      currentUserId: normalizedUserId,
      errorMessage: null,
      joinedAt: _joinedAt,
      excludedUserIds: _excludedUserIds,
    );
    return result;
  }

  Future<void> leaveRoom() async {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      _phase = LiveRoomPhase.idle;
      _currentUserId = null;
      _joinedAt = null;
      _errorMessage = null;
      _excludedUserIds = const <String>{};
      state = const RoomState();
      return;
    }

    _phase = LiveRoomPhase.leaving;
    state = state.copyWith(phase: _phase, errorMessage: null);
    await _sessionService.leaveRoom(roomId: arg, userId: userId);
    _phase = LiveRoomPhase.idle;
    _currentUserId = null;
    _joinedAt = null;
    _errorMessage = null;
    _excludedUserIds = const <String>{};
    state = const RoomState();
  }

  Future<void> pausePresence() async {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return;
    }
    await _sessionService.setCustomStatus(
      roomId: arg,
      userId: userId,
      status: null,
    );
  }

  Future<void> resumePresence() async {
    if (_currentUserId?.trim().isEmpty ?? true) {
      return;
    }
    _phase = LiveRoomPhase.joined;
    _errorMessage = null;
    state = state.copyWith(phase: _phase, errorMessage: null);
  }

  Future<void> postSystemEvent(String content) {
    return _sessionService.postSystemEvent(roomId: arg, content: content);
  }

  Future<void> setCustomStatus({
    required String userId,
    required String? status,
  }) {
    return _sessionService.setCustomStatus(
      roomId: arg,
      userId: userId,
      status: status,
    );
  }

  Future<void> setTyping({required String userId, required bool isTyping}) {
    return _sessionService.setTyping(
      roomId: arg,
      userId: userId,
      isTyping: isTyping,
    );
  }

  Future<void> setSpotlightUser(String? userId) {
    return _sessionService.setSpotlightUser(roomId: arg, userId: userId);
  }

  Future<void> requestMic({required String userId}) async {
    final normalizedUserId = userId.trim();
    if (!state.isUserInRoom(normalizedUserId)) {
      throw StateError('Only joined users can request the mic.');
    }
    if (!state.canAddSpeaker(normalizedUserId)) {
      throw StateError(
        'The stage already has ${RoomState.maxSpeakers} speakers.',
      );
    }
    final hostId = state.hostId.trim();
    if (hostId.isEmpty) {
      throw StateError('No active host was found for this room.');
    }
    await _micAccess.requestAccess(
      roomId: arg,
      requesterId: normalizedUserId,
      hostId: hostId,
    );
  }

  Future<void> approveMicRequest(MicAccessRequestModel request) async {
    if (!state.canAddSpeaker(request.requesterId)) {
      throw StateError(
        'The stage already has ${RoomState.maxSpeakers} speakers.',
      );
    }
    await _micAccess.approveRequest(arg, request);
  }

  Future<void> denyMicRequest(String requestId) {
    return _micAccess.denyRequest(arg, requestId);
  }

  Future<void> releaseMic({required String userId}) {
    return _micAccess.releaseMic(roomId: arg, userId: userId);
  }

  Future<void> promoteSpeaker({
    required String actorUserId,
    required String targetUserId,
  }) async {
    final normalizedActorUserId = actorUserId.trim();
    final normalizedTargetUserId = targetUserId.trim();
    final actorCanPromote =
        state.hostId == normalizedActorUserId ||
        state.isSpeaker(normalizedActorUserId);
    if (!actorCanPromote) {
      throw StateError(
        'Only the host or an active speaker can promote listeners.',
      );
    }
    if (!state.canAddSpeaker(normalizedTargetUserId)) {
      throw StateError(
        'The stage already has ${RoomState.maxSpeakers} speakers.',
      );
    }
    await _hostControls.inviteToMic(arg, normalizedTargetUserId);
  }

  Future<void> demoteSpeaker(String targetUserId) async {
    final normalizedTargetUserId = targetUserId.trim();
    if (!state.isSpeaker(normalizedTargetUserId)) {
      return;
    }
    await _hostControls.forceReleaseMic(arg, normalizedTargetUserId);
  }

  Future<void> muteUser(String userId) {
    return _hostControls.muteUser(arg, userId);
  }

  Future<void> unmuteUser(String userId) {
    return _hostControls.unmuteUser(arg, userId);
  }

  Future<void> approveCameraViewer({
    required String ownerUserId,
    required String viewerUserId,
    required bool approved,
  }) async {
    final normalizedOwnerUserId = ownerUserId.trim();
    final normalizedViewerUserId = viewerUserId.trim();
    final currentViewers = Set<String>.from(
      state.camViewersByUser[normalizedOwnerUserId] ?? const <String>[],
    );
    if (approved) {
      currentViewers.add(normalizedViewerUserId);
    } else {
      currentViewers.remove(normalizedViewerUserId);
    }
    await _camPermissions.setAllowedViewers(
      userId: normalizedOwnerUserId,
      allowedViewers: currentViewers.toList(growable: false),
    );
  }
}
