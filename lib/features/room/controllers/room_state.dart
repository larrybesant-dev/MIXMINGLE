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

  bool get isJoined =>
      phase == LiveRoomPhase.joined && (currentUserId?.isNotEmpty == true);

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

    return stableUserIds.contains(normalized) &&
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
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return 'audience';
    }
    final role = participantRolesByUser[normalized]?.trim().toLowerCase();
    if (role != null && role.isNotEmpty) {
      return role;
    }
    final snapshotRole =
        snapshotFor(normalized)?.role.trim().toLowerCase() ?? '';
    if (snapshotRole.isNotEmpty) {
      return snapshotRole;
    }
    return hostId.trim() == normalized ? 'host' : 'audience';
  }

  bool isHost(String userId) {
    final normalized = userId.trim();
    return normalized.isNotEmpty && hostId.trim() == normalized;
  }

  bool isCohost(String userId) => roleFor(userId) == 'cohost';

  bool isModerator(String userId) => roleFor(userId) == 'moderator';

  bool canManageStage(String userId) {
    final role = roleFor(userId);
    return role == 'host' ||
        role == 'owner' ||
        role == 'cohost' ||
        role == 'moderator';
  }

  bool canModerate(String userId) {
    final role = roleFor(userId);
    return role == 'host' ||
        role == 'owner' ||
        role == 'cohost' ||
        role == 'moderator';
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
