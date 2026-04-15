import '../../../models/room_participant_model.dart';

enum LiveRoomPhase { idle, joining, joined, leaving, error }

enum RoomLifecycleState { initializing, hydrating, active, degraded, ended }

enum RoomAction {
  requestMic,
  manageStage,
  manageMicQueue,
  moderateParticipants,
  manageRoom,
  manageCameraViewer,
}

class RoomStateMachine {
  const RoomStateMachine._();

  static RoomLifecycleState resolveLifecycleState({
    required String roomId,
    required LiveRoomPhase phase,
    required bool isHydrated,
    String? currentUserId,
    String? errorMessage,
  }) {
    final normalizedRoomId = roomId.trim();
    final hasCurrentUser = currentUserId?.trim().isNotEmpty == true;
    final hasError = errorMessage?.trim().isNotEmpty == true;

    switch (phase) {
      case LiveRoomPhase.joining:
        return RoomLifecycleState.hydrating;
      case LiveRoomPhase.joined:
        if (!hasCurrentUser || hasError) {
          return RoomLifecycleState.degraded;
        }
        return isHydrated
            ? RoomLifecycleState.active
            : RoomLifecycleState.hydrating;
      case LiveRoomPhase.error:
        return RoomLifecycleState.degraded;
      case LiveRoomPhase.leaving:
        return RoomLifecycleState.ended;
      case LiveRoomPhase.idle:
        if (normalizedRoomId.isEmpty) {
          return RoomLifecycleState.initializing;
        }
        if (!hasCurrentUser) {
          return RoomLifecycleState.ended;
        }
        if (hasError) {
          return RoomLifecycleState.degraded;
        }
        return isHydrated
            ? RoomLifecycleState.active
            : RoomLifecycleState.hydrating;
    }
  }

  static String resolveHostId({
    Map<String, dynamic>? roomDoc,
    Iterable<RoomParticipantModel> participants =
        const <RoomParticipantModel>[],
  }) {
    final ownerId = (roomDoc?['ownerId'] as String?)?.trim() ?? '';
    if (ownerId.isNotEmpty) {
      return ownerId;
    }

    final hostId = (roomDoc?['hostId'] as String?)?.trim() ?? '';
    if (hostId.isNotEmpty) {
      return hostId;
    }

    for (final participant in participants) {
      final userId = participant.userId.trim();
      if (userId.isEmpty) {
        continue;
      }
      if (isHostLikeRole(participant.role)) {
        return userId;
      }
    }

    return '';
  }

  static String resolveParticipantRole({
    required String userId,
    String hostId = '',
    Map<String, String> participantRolesByUser = const <String, String>{},
    Map<String, RoomSessionSnapshot> sessionSnapshotsByUser =
        const <String, RoomSessionSnapshot>{},
    String fallbackRole = roomRoleAudience,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return fallbackRole;
    }

    final participantRole = normalizeRoomRole(
      participantRolesByUser[normalizedUserId],
      fallbackRole: '',
    );
    if (participantRole.isNotEmpty) {
      return participantRole;
    }

    if (hostId.trim() == normalizedUserId) {
      return roomRoleHost;
    }

    final snapshotRole = normalizeRoomRole(
      sessionSnapshotsByUser[normalizedUserId]?.role,
      fallbackRole: '',
    );
    if (snapshotRole.isNotEmpty) {
      return snapshotRole;
    }

    return normalizeRoomRole(fallbackRole);
  }
}

RoomLifecycleState resolveRoomLifecycleState({
  required String roomId,
  required LiveRoomPhase phase,
  required bool isHydrated,
  String? currentUserId,
  String? errorMessage,
}) {
  return RoomStateMachine.resolveLifecycleState(
    roomId: roomId,
    phase: phase,
    isHydrated: isHydrated,
    currentUserId: currentUserId,
    errorMessage: errorMessage,
  );
}

class RoomSessionSnapshot {
  const RoomSessionSnapshot({
    required this.userId,
    required this.displayName,
    required this.role,
    this.joinedAt,
  });

  final String userId;
  final String displayName;
  final String role;
  final DateTime? joinedAt;

  RoomSessionSnapshot copyWith({
    String? userId,
    String? displayName,
    String? role,
    Object? joinedAt = _unset,
  }) {
    return RoomSessionSnapshot(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: identical(joinedAt, _unset)
          ? this.joinedAt
          : joinedAt as DateTime?,
    );
  }
}

const String roomRoleHost = 'host';
const String roomRoleOwner = 'owner';
const String roomRoleCohost = 'cohost';
const String roomRoleModerator = 'moderator';
const String roomRoleStage = 'stage';
const String roomRoleAudience = 'audience';

String normalizeRoomRole(
  String? role, {
  String fallbackRole = roomRoleAudience,
}) {
  final normalized = role?.trim().toLowerCase() ?? '';
  switch (normalized) {
    case roomRoleHost:
    case roomRoleOwner:
    case roomRoleCohost:
    case roomRoleModerator:
    case roomRoleStage:
    case roomRoleAudience:
      return normalized;
    case '':
      return fallbackRole;
    default:
      return fallbackRole;
  }
}

bool isHostLikeRole(String role) {
  final normalized = normalizeRoomRole(role, fallbackRole: '');
  return normalized == roomRoleHost || normalized == roomRoleOwner;
}

bool canManageStageRole(String role) {
  final normalized = normalizeRoomRole(role, fallbackRole: '');
  return isHostLikeRole(normalized) || normalized == roomRoleCohost;
}

bool canModerateRole(String role) {
  final normalized = normalizeRoomRole(role, fallbackRole: '');
  return canManageStageRole(normalized) || normalized == roomRoleModerator;
}

bool canUseMicRole(String role) {
  final normalized = normalizeRoomRole(role, fallbackRole: '');
  return canModerateRole(normalized) || normalized == roomRoleStage;
}

bool canUseCameraRole(String role) {
  return normalizeRoomRole(role, fallbackRole: '').isNotEmpty;
}

String resolveParticipantRole({
  required String userId,
  String hostId = '',
  Map<String, String> participantRolesByUser = const <String, String>{},
  Map<String, RoomSessionSnapshot> sessionSnapshotsByUser =
      const <String, RoomSessionSnapshot>{},
  String fallbackRole = roomRoleAudience,
}) {
  return RoomStateMachine.resolveParticipantRole(
    userId: userId,
    hostId: hostId,
    participantRolesByUser: participantRolesByUser,
    sessionSnapshotsByUser: sessionSnapshotsByUser,
    fallbackRole: fallbackRole,
  );
}


class RoomState {
  const RoomState({
    this.phase = LiveRoomPhase.idle,
    RoomLifecycleState lifecycleState = RoomLifecycleState.initializing,
    this.roomId = '',
    this.currentUserId,
    this.errorMessage,
    this.joinedAt,
    this.excludedUserIds = const <String>{},
    this.hostId = '',
    this.userIds = const <String>[],
    this.stableUserIds = const <String>[],
    this.pendingUserIds = const <String>{},
    this.speakerIds = const <String>[],
    this.camViewersByUser = const <String, List<String>>{},
    this.participantRolesByUser = const <String, String>{},
    this.sessionSnapshotsByUser = const <String, RoomSessionSnapshot>{},
  }) : _lifecycleState = lifecycleState;

  static const int maxSpeakers = 4;

  final LiveRoomPhase phase;
  final RoomLifecycleState _lifecycleState;
  final String roomId;
  final String? currentUserId;
  final String? errorMessage;
  final DateTime? joinedAt;
  final Set<String> excludedUserIds;
  final String hostId;
  final List<String> userIds;
  final List<String> stableUserIds;
  final Set<String> pendingUserIds;
  final List<String> speakerIds;
  final Map<String, List<String>> camViewersByUser;
  final Map<String, String> participantRolesByUser;
  final Map<String, RoomSessionSnapshot> sessionSnapshotsByUser;

  String? get userId => currentUserId;

  List<String> get users => List<String>.unmodifiable(userIds);

  List<String> get speakers => List<String>.unmodifiable(speakerIds);

  RoomLifecycleState get lifecycleState {
    final resolvedLifecycleState = resolveRoomLifecycleState(
      roomId: roomId,
      phase: phase,
      isHydrated: isRoomFullyHydrated,
      currentUserId: currentUserId,
      errorMessage: errorMessage,
    );
    if (_lifecycleState == RoomLifecycleState.ended &&
        resolvedLifecycleState == RoomLifecycleState.initializing) {
      return _lifecycleState;
    }
    return resolvedLifecycleState;
  }

  bool get isConnected => phase == LiveRoomPhase.joined;

  bool get isJoined =>
      phase == LiveRoomPhase.joined && (currentUserId?.isNotEmpty == true);

  bool get isActive => lifecycleState == RoomLifecycleState.active;

  bool get isDegraded => lifecycleState == RoomLifecycleState.degraded;

  bool get isRoomFullyHydrated {
    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    if (normalizedCurrentUserId.isEmpty) {
      return false;
    }

    final snapshotRole =
        sessionSnapshotsByUser[normalizedCurrentUserId]?.role
            .trim()
            .toLowerCase() ??
        '';
    final hasExplicitAuthorityRole =
        snapshotRole.isNotEmpty && snapshotRole != 'audience';

    if (pendingUserIds.contains(normalizedCurrentUserId) &&
        hostId.trim() != normalizedCurrentUserId &&
        !hasExplicitAuthorityRole) {
      return false;
    }

    return stableUserIds.contains(normalizedCurrentUserId) ||
        participantRolesByUser.containsKey(normalizedCurrentUserId) ||
        hostId.trim() == normalizedCurrentUserId ||
        hasExplicitAuthorityRole;
  }

  bool isUserInRoom(String userId) {
    final normalized = userId.trim();
    return normalized.isNotEmpty && userIds.contains(normalized);
  }

  bool canChat(String userId) => isUserInRoom(userId);

  bool isSpeaker(String userId) {
    final normalized = userId.trim();
    return normalized.isNotEmpty && speakerIds.contains(normalized);
  }

  bool shouldRenderUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return false;
    }

    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    if (normalized == normalizedCurrentUserId) {
      return stableUserIds.contains(normalized) ||
          userIds.contains(normalized) ||
          sessionSnapshotsByUser.containsKey(normalized);
    }

    return userIds.contains(normalized) &&
        stableUserIds.contains(normalized) &&
        !pendingUserIds.contains(normalized);
  }

  RoomSessionSnapshot? snapshotFor(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return sessionSnapshotsByUser[normalized];
  }

  String displayNameFor(String userId, {String fallbackName = ''}) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return fallbackName.trim().isEmpty ? 'MixVy User' : fallbackName.trim();
    }
    final snapshotName = snapshotFor(normalized)?.displayName.trim() ?? '';
    if (snapshotName.isNotEmpty) {
      return snapshotName;
    }
    final trimmedFallback = fallbackName.trim();
    if (trimmedFallback.isNotEmpty) {
      return trimmedFallback;
    }
    return normalized;
  }

  String roleFor(String userId) {
    return resolveParticipantRole(
      userId: userId,
      hostId: hostId,
      participantRolesByUser: participantRolesByUser,
      sessionSnapshotsByUser: sessionSnapshotsByUser,
    );
  }

  bool _canResolveAuthorityFor(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    if (normalizedCurrentUserId.isEmpty ||
        normalized != normalizedCurrentUserId) {
      return true;
    }
    return isRoomFullyHydrated;
  }

  bool isHost(String userId) {
    if (!_canResolveAuthorityFor(userId)) {
      return false;
    }
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return isHostLikeRole(roleFor(normalized));
  }

  bool isCohost(String userId) =>
      _canResolveAuthorityFor(userId) &&
      normalizeRoomRole(roleFor(userId), fallbackRole: '') == roomRoleCohost;

  bool isModerator(String userId) =>
      _canResolveAuthorityFor(userId) &&
      normalizeRoomRole(roleFor(userId), fallbackRole: '') == roomRoleModerator;

  bool canManageStage(String userId) {
    if (!_canResolveAuthorityFor(userId)) {
      return false;
    }
    return canManageStageRole(roleFor(userId));
  }

  bool canModerate(String userId) {
    if (!_canResolveAuthorityFor(userId)) {
      return false;
    }
    return canModerateRole(roleFor(userId));
  }

  bool canExecute(
    RoomAction action, {
    required String userId,
    String? targetUserId,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty ||
        lifecycleState != RoomLifecycleState.active) {
      return false;
    }

    switch (action) {
      case RoomAction.requestMic:
        return isUserInRoom(normalizedUserId);
      case RoomAction.manageStage:
      case RoomAction.manageMicQueue:
        return canManageStage(normalizedUserId);
      case RoomAction.moderateParticipants:
        return canModerate(normalizedUserId);
      case RoomAction.manageRoom:
        return isHost(normalizedUserId);
      case RoomAction.manageCameraViewer:
        final normalizedTargetUserId = targetUserId?.trim() ?? '';
        if (normalizedTargetUserId.isEmpty) {
          return false;
        }
        return normalizedUserId == normalizedTargetUserId ||
            isHost(normalizedUserId);
    }
  }

  bool canAddSpeaker(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    if (speakerIds.contains(normalized)) {
      return true;
    }
    return speakerIds.length < maxSpeakers;
  }

  bool canViewCamera({
    required String targetUserId,
    required String viewerUserId,
  }) {
    final normalizedTarget = targetUserId.trim();
    final normalizedViewer = viewerUserId.trim();
    if (normalizedTarget.isEmpty || normalizedViewer.isEmpty) {
      return false;
    }
    if (normalizedTarget == normalizedViewer) {
      return true;
    }
    return camViewersByUser[normalizedTarget]?.contains(normalizedViewer) ??
        false;
  }

  bool isWatchingMe({required String myUserId, required String otherUserId}) {
    final normalizedMe = myUserId.trim();
    final normalizedOther = otherUserId.trim();
    if (normalizedMe.isEmpty || normalizedOther.isEmpty) {
      return false;
    }
    return camViewersByUser[normalizedMe]?.contains(normalizedOther) ?? false;
  }

  int viewerCountFor(String targetUserId) {
    final normalized = targetUserId.trim();
    return camViewersByUser[normalized]?.length ?? 0;
  }

  RoomState copyWith({
    LiveRoomPhase? phase,
    RoomLifecycleState? lifecycleState,
    Object? currentUserId = _unset,
    Object? errorMessage = _unset,
    Object? joinedAt = _unset,
    Set<String>? excludedUserIds,
    String? hostId,
    List<String>? userIds,
    List<String>? stableUserIds,
    Set<String>? pendingUserIds,
    List<String>? speakerIds,
    Map<String, List<String>>? camViewersByUser,
    Map<String, String>? participantRolesByUser,
    Map<String, RoomSessionSnapshot>? sessionSnapshotsByUser,
  }) {
    return RoomState(
      phase: phase ?? this.phase,
      lifecycleState: lifecycleState ?? _lifecycleState,
      roomId: roomId,
      currentUserId: identical(currentUserId, _unset)
          ? this.currentUserId
          : currentUserId as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      joinedAt: identical(joinedAt, _unset)
          ? this.joinedAt
          : joinedAt as DateTime?,
      excludedUserIds: excludedUserIds ?? this.excludedUserIds,
      hostId: hostId ?? this.hostId,
      userIds: userIds ?? this.userIds,
      stableUserIds: stableUserIds ?? this.stableUserIds,
      pendingUserIds: pendingUserIds ?? this.pendingUserIds,
      speakerIds: speakerIds ?? this.speakerIds,
      camViewersByUser: camViewersByUser ?? this.camViewersByUser,
      participantRolesByUser:
          participantRolesByUser ?? this.participantRolesByUser,
      sessionSnapshotsByUser:
          sessionSnapshotsByUser ?? this.sessionSnapshotsByUser,
    );
  }
}

const Object _unset = Object();
