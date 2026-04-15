enum LiveRoomPhase { idle, joining, joined, leaving, error }

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

class RoomState {
  const RoomState({
    this.phase = LiveRoomPhase.idle,
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
  });

  static const int maxSpeakers = 4;

  final LiveRoomPhase phase;
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

  bool get isConnected => phase == LiveRoomPhase.joined;

  bool get isJoined =>
      phase == LiveRoomPhase.joined && (currentUserId?.isNotEmpty == true);

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
