import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/events/app_event.dart';
import '../../core/events/app_event_bus.dart';
import '../../models/mic_access_request_model.dart';
import '../../models/room_participant_model.dart';
import 'controllers/room_state.dart';
import 'providers/host_controls_provider.dart';
import 'providers/mic_access_provider.dart';
import 'providers/participant_providers.dart';
import 'repository/room_repository.dart';
import 'providers/room_policy_provider.dart';
import 'providers/user_cam_permissions_provider.dart';
import 'services/room_session_service.dart';

final roomControllerProvider = NotifierProvider.family
    .autoDispose<RoomController, RoomState, String>(RoomController.new);

enum MicRequestResult { grabbed, queued }

class RoomController extends AutoDisposeFamilyNotifier<RoomState, String> {
  RoomSessionService get _sessionService =>
      ref.read(roomSessionServiceProvider);
  HostControls get _hostControls => ref.read(hostControlsProvider);
  MicAccessController get _micAccess => ref.read(micAccessControllerProvider);
  RoomRepository get _roomRepository => ref.read(roomRepositoryProvider);
  RoomPolicyController get _roomPolicy =>
      ref.read(roomPolicyControllerProvider);
  UserCamPermissionsController get _camPermissions =>
      ref.read(userCamPermissionsControllerProvider);

  static const Duration _kJoinStabilizationDelay = Duration(milliseconds: 350);

  LiveRoomPhase _phase = LiveRoomPhase.idle;
  String? _currentUserId;
  String? _errorMessage;
  DateTime? _joinedAt;
  Set<String> _excludedUserIds = const <String>{};
  final Map<String, RoomSessionSnapshot> _sessionSnapshotsByUser =
      <String, RoomSessionSnapshot>{};
  final Set<String> _pendingUserIds = <String>{};
  final Set<String> _stableUserIds = <String>{};
  Timer? _joinStabilizationTimer;
  Timer? _roomHeartbeatTimer;
  DateTime? _lastParticipantSyncAt;

  static const Duration _kRoomHeartbeatInterval = Duration(seconds: 20);

  @override
  RoomState build(String roomId) {
    ref.onDispose(() {
      _joinStabilizationTimer?.cancel();
      _roomHeartbeatTimer?.cancel();
    });

    final roomDoc = ref.watch(roomDocStreamProvider(roomId)).valueOrNull;
    final participants =
        ref.watch(participantsStreamProvider(roomId)).valueOrNull ??
        const <RoomParticipantModel>[];
    final memberUserIds =
        ref.watch(roomMemberUserIdsProvider(roomId)).valueOrNull ??
        const <String>[];
    final speakerUserIds =
        ref.watch(roomSpeakerUserIdsProvider(roomId)).valueOrNull ??
        const <String>[];

    final hostId = _resolveHostId(roomDoc, participants);
    final userIds = _resolveUserIds(participants, memberUserIds: memberUserIds);
    final speakerIds = _resolveSpeakerIds(
      participants,
      hostId: hostId,
      speakerUserIds: speakerUserIds,
      useSpeakerDocs: _shouldUseSpeakerDocs(roomDoc),
    );
    final camViewersByUser = _resolveCamViewers(userIds);
    final participantRolesByUser = _resolveParticipantRoles(
      participants,
      hostId: hostId,
    );
    final sessionSnapshotsByUser = _resolveSessionSnapshots(
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
      stableUserIds: _resolveStableUserIds(
        mergedUserIds.toList(growable: false),
      ),
      pendingUserIds: Set<String>.unmodifiable(_pendingUserIds),
      speakerIds: speakerIds,
      camViewersByUser: camViewersByUser,
      participantRolesByUser: participantRolesByUser,
      sessionSnapshotsByUser: Map<String, RoomSessionSnapshot>.unmodifiable(
        sessionSnapshotsByUser,
      ),
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

  List<String> _resolveUserIds(
    List<RoomParticipantModel> participants, {
    List<String> memberUserIds = const <String>[],
  }) {
    return <String>{
      ...memberUserIds.map((userId) => userId.trim()),
      ...participants.map((participant) => participant.userId.trim()),
    }.where((userId) => userId.isNotEmpty).toList(growable: false);
  }

  bool _shouldUseSpeakerDocs(Map<String, dynamic>? roomDoc) {
    final rawVersion = roomDoc?['speakerSyncVersion'];
    final rawMaxSpeakers = roomDoc?['maxSpeakers'];
    return rawVersion is num || rawMaxSpeakers is num;
  }

  List<String> _resolveSpeakerIds(
    List<RoomParticipantModel> participants, {
    required String hostId,
    List<String> speakerUserIds = const <String>[],
    required bool useSpeakerDocs,
  }) {
    if (useSpeakerDocs) {
      final participantsByUser = {
        for (final participant in participants)
          participant.userId.trim(): participant,
      };
      final resolvedUserIds = speakerUserIds
          .map((userId) => userId.trim())
          .where((userId) => userId.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort((left, right) {
          final leftParticipant = participantsByUser[left];
          final rightParticipant = participantsByUser[right];
          final leftRank = _speakerRank(
            leftParticipant ??
                RoomParticipantModel(
                  userId: left,
                  role: left == hostId ? 'host' : 'stage',
                  joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
                  lastActiveAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
            hostId: hostId,
          );
          final rightRank = _speakerRank(
            rightParticipant ??
                RoomParticipantModel(
                  userId: right,
                  role: right == hostId ? 'host' : 'stage',
                  joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
                  lastActiveAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
            hostId: hostId,
          );
          if (leftRank != rightRank) {
            return leftRank.compareTo(rightRank);
          }
          final leftJoinedAt =
              leftParticipant?.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final rightJoinedAt =
              rightParticipant?.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return leftJoinedAt.compareTo(rightJoinedAt);
        });
      return resolvedUserIds.take(RoomState.maxSpeakers).toList(growable: false);
    }

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

  bool _isPlaceholderDisplayName(String value) {
    final normalized = value.trim();
    final generatedHandlePattern = RegExp(r'^(User|Guest) [A-Z0-9]{1,4}$');
    return normalized.isEmpty ||
        normalized == 'MixVy User' ||
        generatedHandlePattern.hasMatch(normalized);
  }

  Map<String, RoomSessionSnapshot> _resolveSessionSnapshots(
    List<RoomParticipantModel> participants, {
    required String hostId,
  }) {
    final result = <String, RoomSessionSnapshot>{..._sessionSnapshotsByUser};

    for (final participant in participants) {
      final userId = participant.userId.trim();
      if (userId.isEmpty) {
        continue;
      }
      final existing = result[userId];
      final existingName = existing?.displayName.trim() ?? '';
      result[userId] = RoomSessionSnapshot(
        userId: userId,
        displayName: existingName.isNotEmpty ? existingName : userId,
        role: participant.role.trim().isEmpty
            ? (userId == hostId ? 'host' : 'audience')
            : participant.role.trim().toLowerCase(),
        joinedAt: existing?.joinedAt ?? participant.joinedAt,
      );
    }

    final currentUserId = _currentUserId?.trim() ?? '';
    if (currentUserId.isNotEmpty) {
      result.putIfAbsent(
        currentUserId,
        () => RoomSessionSnapshot(
          userId: currentUserId,
          displayName: currentUserId,
          role: currentUserId == hostId ? 'host' : 'audience',
          joinedAt: _joinedAt,
        ),
      );
    }

    _sessionSnapshotsByUser
      ..clear()
      ..addAll(result);
    return result;
  }

  List<String> _resolveStableUserIds(List<String> userIds) {
    final stable = <String>{...userIds, ..._stableUserIds};
    for (final userId in _pendingUserIds) {
      if (!userIds.contains(userId)) {
        stable.remove(userId);
      }
    }
    return stable.toList(growable: false);
  }

  void _publishSessionState() {
    state = state.copyWith(
      pendingUserIds: Set<String>.unmodifiable(_pendingUserIds),
      stableUserIds: _resolveStableUserIds(state.userIds),
      sessionSnapshotsByUser: Map<String, RoomSessionSnapshot>.unmodifiable(
        _sessionSnapshotsByUser,
      ),
    );
  }

  void _scheduleStabilization(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }
    _pendingUserIds.add(normalizedUserId);
    _stableUserIds.remove(normalizedUserId);
    _publishSessionState();

    _joinStabilizationTimer?.cancel();
    _joinStabilizationTimer = Timer(_kJoinStabilizationDelay, () {
      _pendingUserIds.remove(normalizedUserId);
      _stableUserIds.add(normalizedUserId);
      _publishSessionState();
    });
  }

  void _startRoomHeartbeat() {
    _roomHeartbeatTimer?.cancel();
    if ((_currentUserId?.trim().isEmpty ?? true) ||
        _phase != LiveRoomPhase.joined) {
      return;
    }

    unawaited(_sendRoomHeartbeat(forceSync: true));
    _roomHeartbeatTimer = Timer.periodic(_kRoomHeartbeatInterval, (_) {
      unawaited(_sendRoomHeartbeat());
    });
  }

  void _stopRoomHeartbeat() {
    _roomHeartbeatTimer?.cancel();
    _roomHeartbeatTimer = null;
    _lastParticipantSyncAt = null;
  }

  Future<void> _sendRoomHeartbeat({bool forceSync = false}) async {
    final userId = _currentUserId?.trim() ?? '';
    if (userId.isEmpty || _phase != LiveRoomPhase.joined) {
      return;
    }

    try {
      _lastParticipantSyncAt = await _sessionService.heartbeat(
        roomId: arg,
        userId: userId,
        lastParticipantSyncAt: _lastParticipantSyncAt,
        forceParticipantSync: forceSync,
      );
    } catch (_) {
      // Best-effort roster freshness sync.
    }
  }

  void hydrateCurrentUser(
    String userId, {
    String? displayName,
    String? role,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    _currentUserId = normalizedUserId;
    final existing = _sessionSnapshotsByUser[normalizedUserId];
    final resolvedRole = role?.trim().toLowerCase();
    _sessionSnapshotsByUser[normalizedUserId] = RoomSessionSnapshot(
      userId: normalizedUserId,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (existing?.displayName ?? normalizedUserId),
      role: (resolvedRole != null && resolvedRole.isNotEmpty)
          ? resolvedRole
          : (existing?.role ?? state.roleFor(normalizedUserId)),
      joinedAt: existing?.joinedAt ?? _joinedAt,
    );
    state = state.copyWith(
      currentUserId: normalizedUserId,
      sessionSnapshotsByUser: Map<String, RoomSessionSnapshot>.unmodifiable(
        _sessionSnapshotsByUser,
      ),
      stableUserIds: _resolveStableUserIds(state.userIds),
    );
  }

  void cacheDisplayName({
    required String userId,
    required String displayName,
    String? role,
  }) {
    final normalizedUserId = userId.trim();
    final normalizedDisplayName = displayName.trim();
    if (normalizedUserId.isEmpty || normalizedDisplayName.isEmpty) {
      return;
    }

    final existing = _sessionSnapshotsByUser[normalizedUserId];
    final shouldUpdate =
        existing == null || _isPlaceholderDisplayName(existing.displayName);
    if (!shouldUpdate) {
      return;
    }

    _sessionSnapshotsByUser[normalizedUserId] = RoomSessionSnapshot(
      userId: normalizedUserId,
      displayName: normalizedDisplayName,
      role: role?.trim().isNotEmpty == true
          ? role!.trim().toLowerCase()
          : (existing?.role ?? state.roleFor(normalizedUserId)),
      joinedAt: existing?.joinedAt ?? _joinedAt,
    );

    final normalizedCurrentUserId = _currentUserId?.trim() ?? '';
    final canAffectRosterVisibility =
        normalizedUserId == normalizedCurrentUserId ||
        state.userIds.contains(normalizedUserId);
    if (canAffectRosterVisibility) {
      _stableUserIds.add(normalizedUserId);
      _pendingUserIds.remove(normalizedUserId);
    }
    _publishSessionState();
  }

  String get _actorUserId => state.currentUserId?.trim() ?? '';

  void _requireStageAuthority() {
    final actorUserId = _actorUserId;
    if (!state.canManageStage(actorUserId)) {
      throw StateError('Only room staff can manage the stage.');
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

  Future<RoomJoinResult> joinRoom(
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedDisplayName = displayName?.trim() ?? '';
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
    _sessionSnapshotsByUser[normalizedUserId] = RoomSessionSnapshot(
      userId: normalizedUserId,
      displayName: normalizedDisplayName.isNotEmpty
          ? normalizedDisplayName
          : (_sessionSnapshotsByUser[normalizedUserId]?.displayName ??
                normalizedUserId),
      role: _sessionSnapshotsByUser[normalizedUserId]?.role ?? 'audience',
      joinedAt: DateTime.now(),
    );
    _scheduleStabilization(normalizedUserId);
    state = state.copyWith(
      phase: _phase,
      currentUserId: _currentUserId,
      errorMessage: null,
      pendingUserIds: Set<String>.unmodifiable(_pendingUserIds),
      stableUserIds: _resolveStableUserIds(state.userIds),
      sessionSnapshotsByUser: Map<String, RoomSessionSnapshot>.unmodifiable(
        _sessionSnapshotsByUser,
      ),
    );

    final result = await _sessionService.joinRoom(
      roomId: arg,
      userId: normalizedUserId,
      displayName: normalizedDisplayName,
      photoUrl: avatarUrl,
    );
    if (!result.isSuccess) {
      _stopRoomHeartbeat();
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
    _startRoomHeartbeat();
    _errorMessage = null;
    final existingSnapshot = _sessionSnapshotsByUser[normalizedUserId];
    _sessionSnapshotsByUser[normalizedUserId] = RoomSessionSnapshot(
      userId: normalizedUserId,
      displayName: normalizedDisplayName.isNotEmpty
          ? normalizedDisplayName
          : (existingSnapshot?.displayName ?? normalizedUserId),
      role: existingSnapshot?.role ?? 'audience',
      joinedAt: _joinedAt,
    );
    state = state.copyWith(
      phase: _phase,
      currentUserId: normalizedUserId,
      errorMessage: null,
      joinedAt: _joinedAt,
      excludedUserIds: _excludedUserIds,
      pendingUserIds: Set<String>.unmodifiable(_pendingUserIds),
      stableUserIds: _resolveStableUserIds(state.userIds),
      sessionSnapshotsByUser: Map<String, RoomSessionSnapshot>.unmodifiable(
        _sessionSnapshotsByUser,
      ),
    );
    AppEventBus.instance.emit(
      RoomJoinedEvent(
        id: 'room-joined:$arg:$normalizedUserId:${(_joinedAt ?? DateTime.now()).millisecondsSinceEpoch}',
        timestamp: _joinedAt ?? DateTime.now(),
        sessionId: AppEventIds.roomSession(
          roomId: arg,
          userId: normalizedUserId,
        ),
        correlationId: AppEventIds.roomCorrelation(
          roomId: arg,
          userId: normalizedUserId,
        ),
        userId: normalizedUserId,
        roomId: arg,
      ),
    );
    return result;
  }

  Future<void> leaveRoom() async {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      _stopRoomHeartbeat();
      _phase = LiveRoomPhase.idle;
      _currentUserId = null;
      _joinedAt = null;
      _errorMessage = null;
      _excludedUserIds = const <String>{};
      _pendingUserIds.clear();
      _stableUserIds.clear();
      _sessionSnapshotsByUser.clear();
      state = const RoomState();
      return;
    }

    _stopRoomHeartbeat();
    _phase = LiveRoomPhase.leaving;
    state = state.copyWith(phase: _phase, errorMessage: null);
    await _sessionService.leaveRoom(roomId: arg, userId: userId);
    AppEventBus.instance.emit(
      RoomLeftEvent(
        id: 'room-left:$arg:$userId:${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        sessionId: AppEventIds.roomSession(roomId: arg, userId: userId),
        correlationId: AppEventIds.roomCorrelation(roomId: arg, userId: userId),
        userId: userId,
        roomId: arg,
      ),
    );
    _phase = LiveRoomPhase.idle;
    _currentUserId = null;
    _joinedAt = null;
    _errorMessage = null;
    _excludedUserIds = const <String>{};
    _pendingUserIds.clear();
    _stableUserIds.clear();
    _sessionSnapshotsByUser.clear();
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
    _startRoomHeartbeat();
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

  Future<MicRequestResult> requestMic({required String userId}) async {
    final normalizedUserId = userId.trim();
    if (!state.isUserInRoom(normalizedUserId)) {
      throw StateError('Only joined users can request the mic.');
    }

    if (state.isSpeaker(normalizedUserId)) {
      return MicRequestResult.grabbed;
    }

    final otherSpeakerIds = state.speakerIds
        .where((speakerId) => speakerId != normalizedUserId)
        .toList(growable: false);
    final canGrabDirectly =
        otherSpeakerIds.isEmpty &&
        state.speakerIds.length < RoomState.maxSpeakers;

    if (canGrabDirectly) {
      await _roomRepository.requestMic(
        roomId: arg,
        userId: normalizedUserId,
        displayName: state.snapshotFor(normalizedUserId)?.displayName,
        role: state.roleFor(normalizedUserId),
      );
      AppEventBus.instance.emit(
        MicStateChangedEvent(
          id: 'mic-grab:$arg:$normalizedUserId:${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          sessionId: AppEventIds.roomSession(
            roomId: arg,
            userId: normalizedUserId,
          ),
          correlationId: AppEventIds.roomCorrelation(
            roomId: arg,
            userId: normalizedUserId,
          ),
          userId: normalizedUserId,
          roomId: arg,
          isSpeaker: true,
        ),
      );
      return MicRequestResult.grabbed;
    }

    final hostId = state.hostId.trim();
    if (hostId.isEmpty || hostId == normalizedUserId) {
      await _roomRepository.requestMic(
        roomId: arg,
        userId: normalizedUserId,
        displayName: state.snapshotFor(normalizedUserId)?.displayName,
        role: state.roleFor(normalizedUserId),
      );
      return MicRequestResult.grabbed;
    }

    await _micAccess.requestAccess(
      roomId: arg,
      requesterId: normalizedUserId,
      hostId: hostId,
    );
    return MicRequestResult.queued;
  }

  Future<void> approveMicRequest(MicAccessRequestModel request) async {
    _requireStageAuthority();
    await _roomRepository.requestMic(
      roomId: arg,
      userId: request.requesterId,
      displayName: state.snapshotFor(request.requesterId)?.displayName,
      role: state.roleFor(request.requesterId),
    );
    await _micAccess.approveRequest(arg, request);
  }

  Future<void> denyMicRequest(String requestId) {
    _requireStageAuthority();
    return _micAccess.denyRequest(arg, requestId);
  }

  Future<void> cancelMicRequest(String requestId) {
    final actorUserId = _actorUserId;
    if (actorUserId.isEmpty) {
      throw StateError('You must be in the room to cancel a mic request.');
    }
    return _micAccess.cancelRequest(arg, requestId);
  }

  Future<void> releaseMic({required String userId}) async {
    final normalizedUserId = userId.trim();
    final actorUserId = _actorUserId;
    final isSelfRelease =
        actorUserId.isNotEmpty && actorUserId == normalizedUserId;
    if (!isSelfRelease) {
      _requireStageAuthority();
    }
    await _roomRepository.releaseMic(
      roomId: arg,
      userId: normalizedUserId,
    );
    AppEventBus.instance.emit(
      MicStateChangedEvent(
        id: 'mic-release:$arg:$normalizedUserId:${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        sessionId: AppEventIds.roomSession(
          roomId: arg,
          userId: normalizedUserId,
        ),
        correlationId: AppEventIds.roomCorrelation(
          roomId: arg,
          userId: normalizedUserId,
        ),
        userId: normalizedUserId,
        roomId: arg,
        isSpeaker: false,
      ),
    );
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
    await _roomRepository.requestMic(
      roomId: arg,
      userId: normalizedTargetUserId,
      displayName: state.snapshotFor(normalizedTargetUserId)?.displayName,
      role: state.roleFor(normalizedTargetUserId),
    );
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
    await _roomRepository.forceRemoveSpeaker(
      roomId: arg,
      userId: normalizedTargetUserId,
    );
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
