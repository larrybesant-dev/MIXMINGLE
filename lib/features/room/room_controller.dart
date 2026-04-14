import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/mic_access_request_model.dart';
import '../../models/room_participant_model.dart';
import 'controllers/room_state.dart';
import 'providers/host_controls_provider.dart';
import 'providers/mic_access_provider.dart';
import 'providers/participant_providers.dart';
import 'providers/room_policy_provider.dart';
import 'providers/user_cam_permissions_provider.dart';
import 'services/room_session_service.dart';

final roomControllerProvider = NotifierProvider.family
    .autoDispose<RoomController, RoomState, String>(RoomController.new);

class RoomController extends AutoDisposeFamilyNotifier<RoomState, String> {
  RoomSessionService get _sessionService =>
      ref.read(roomSessionServiceProvider);
  HostControls get _hostControls => ref.read(hostControlsProvider);
  MicAccessController get _micAccess => ref.read(micAccessControllerProvider);
  RoomPolicyController get _roomPolicy =>
      ref.read(roomPolicyControllerProvider);
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
    final participantRolesByUser = _resolveParticipantRoles(
      participants,
      hostId: hostId,
    );

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
      participantRolesByUser: participantRolesByUser,
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

  Map<String, String> _resolveParticipantRoles(
    List<RoomParticipantModel> participants, {
    required String hostId,
  }) {
    final result = <String, String>{};
    for (final participant in participants) {
      final userId = participant.userId.trim();
      if (userId.isEmpty) {
        continue;
      }
      final normalizedRole = participant.role.trim().toLowerCase();
      result[userId] = normalizedRole.isEmpty ? 'audience' : normalizedRole;
    }
    if (hostId.trim().isNotEmpty) {
      result.putIfAbsent(hostId.trim(), () => 'host');
    }
    return result;
  }

  String get _actorUserId => state.currentUserId?.trim() ?? '';

  void _requireStageAuthority() {
    final actorUserId = _actorUserId;
    if (!state.canManageStage(actorUserId)) {
      throw StateError('Only the host or co-host can manage the stage.');
    }
  }

  void _requireModerationAuthority() {
    final actorUserId = _actorUserId;
    if (!state.canModerate(actorUserId)) {
      throw StateError('Only room staff can manage participants.');
    }
  }

  void _requireHostAuthority() {
    final actorUserId = _actorUserId;
    if (!state.isHost(actorUserId) && state.roleFor(actorUserId) != 'owner') {
      throw StateError('Only the room host can perform this action.');
    }
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
    _requireStageAuthority();
    if (!state.canAddSpeaker(request.requesterId)) {
      throw StateError(
        'The stage already has ${RoomState.maxSpeakers} speakers.',
      );
    }
    await _micAccess.approveRequest(arg, request);
  }

  Future<void> denyMicRequest(String requestId) {
    _requireStageAuthority();
    return _micAccess.denyRequest(arg, requestId);
  }

  Future<void> releaseMic({required String userId}) {
    final normalizedUserId = userId.trim();
    final actorUserId = _actorUserId;
    final isSelfRelease =
        actorUserId.isNotEmpty && actorUserId == normalizedUserId;
    if (!isSelfRelease) {
      _requireStageAuthority();
    }
    return _micAccess.releaseMic(roomId: arg, userId: normalizedUserId);
  }

  Future<void> promoteSpeaker({
    String? actorUserId,
    required String targetUserId,
  }) async {
    final normalizedControllerActor = _actorUserId;
    final normalizedActorUserId = (actorUserId ?? normalizedControllerActor)
        .trim();
    final normalizedTargetUserId = targetUserId.trim();
    if (normalizedControllerActor.isNotEmpty &&
        normalizedActorUserId != normalizedControllerActor) {
      throw StateError(
        'Stage mutations must come from the active room controller.',
      );
    }
    if (!state.canManageStage(normalizedActorUserId)) {
      throw StateError('Only the host or co-host can promote listeners.');
    }
    if (!state.isUserInRoom(normalizedTargetUserId)) {
      throw StateError('Only joined users can be added to the stage.');
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
    final actorUserId = _actorUserId;
    if (actorUserId != normalizedTargetUserId) {
      _requireStageAuthority();
    }
    if (!state.isSpeaker(normalizedTargetUserId)) {
      return;
    }
    await _hostControls.forceReleaseMic(arg, normalizedTargetUserId);
  }

  Future<void> muteUser(String userId) {
    _requireModerationAuthority();
    return _hostControls.muteUser(arg, userId.trim());
  }

  Future<void> unmuteUser(String userId) {
    _requireModerationAuthority();
    return _hostControls.unmuteUser(arg, userId.trim());
  }

  Future<void> promoteToModerator(String userId) {
    _requireHostAuthority();
    return _hostControls.promoteToModerator(arg, userId.trim());
  }

  Future<void> promoteToCohost(String userId) {
    _requireHostAuthority();
    return _hostControls.promoteToCohost(arg, userId.trim());
  }

  Future<void> demoteToAudience(String userId) {
    _requireHostAuthority();
    return _hostControls.demoteToAudience(arg, userId.trim());
  }

  Future<void> removeUser(String userId) {
    _requireModerationAuthority();
    return _hostControls.removeUser(arg, userId.trim());
  }

  Future<void> banUser(String userId) {
    _requireModerationAuthority();
    return _hostControls.banUser(arg, userId.trim());
  }

  Future<void> unbanUser(String userId) {
    _requireModerationAuthority();
    return _hostControls.unbanUser(arg, userId.trim());
  }

  Future<void> transferHost({required String targetUserId}) {
    _requireHostAuthority();
    return _hostControls.transferHost(
      roomId: arg,
      fromUserId: _actorUserId,
      toUserId: targetUserId.trim(),
    );
  }

  Future<void> toggleSlowMode(int seconds) {
    _requireHostAuthority();
    return _hostControls.toggleSlowMode(arg, seconds);
  }

  Future<void> toggleLockRoom() {
    _requireHostAuthority();
    return _hostControls.toggleLockRoom(arg);
  }

  Future<void> toggleAllowChat() {
    _requireHostAuthority();
    return _hostControls.toggleAllowChat(arg);
  }

  Future<void> toggleAllowCamRequests() {
    _requireHostAuthority();
    return _hostControls.toggleAllowCamRequests(arg);
  }

  Future<void> toggleAllowMicRequests() {
    _requireHostAuthority();
    return _hostControls.toggleAllowMicRequests(arg);
  }

  Future<void> toggleAllowGifts() {
    _requireHostAuthority();
    return _hostControls.toggleAllowGifts(arg);
  }

  Future<void> setMaxBroadcasters(int max) {
    _requireHostAuthority();
    return _hostControls.setMaxBroadcasters(arg, max);
  }

  Future<void> setMicLimit(int limit) {
    _requireHostAuthority();
    return _roomPolicy.setMicLimit(arg, limit);
  }

  Future<void> setMicTimer(int? seconds) {
    _requireHostAuthority();
    return _roomPolicy.setMicTimer(arg, seconds);
  }

  Future<void> setCamLimit(int limit) {
    _requireHostAuthority();
    return _roomPolicy.setCamLimit(arg, limit);
  }

  Future<void> bumpMicRequest(String requestId) {
    _requireStageAuthority();
    return _micAccess.bumpPriority(arg, requestId);
  }

  Future<void> lowerMicRequest(String requestId) {
    _requireStageAuthority();
    return _micAccess.lowerPriority(arg, requestId);
  }

  Future<void> expireMicRequest(String requestId) {
    _requireStageAuthority();
    return _micAccess.expireNow(arg, requestId);
  }

  Future<void> endRoom() {
    _requireHostAuthority();
    return _hostControls.endRoom(arg);
  }

  Future<void> setRoomInfo({
    String? name,
    String? description,
    String? category,
  }) {
    _requireHostAuthority();
    return _hostControls.setRoomInfo(
      arg,
      name: name,
      description: description,
      category: category,
    );
  }

  Future<void> approveCameraViewer({
    required String ownerUserId,
    required String viewerUserId,
    required bool approved,
  }) async {
    final normalizedOwnerUserId = ownerUserId.trim();
    final normalizedViewerUserId = viewerUserId.trim();
    final actorUserId = _actorUserId;
    final canManageViewerAccess =
        actorUserId == normalizedOwnerUserId || state.isHost(actorUserId);
    if (!canManageViewerAccess) {
      throw StateError(
        'Only the camera owner or room host can manage viewers.',
      );
    }
    if (approved) {
      await _camPermissions.addAllowedViewer(
        userId: normalizedOwnerUserId,
        viewerId: normalizedViewerUserId,
      );
      return;
    }
    await _camPermissions.removeAllowedViewer(
      userId: normalizedOwnerUserId,
      viewerId: normalizedViewerUserId,
    );
  }
}
