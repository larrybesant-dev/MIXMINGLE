enum LiveRoomPhase { idle, joining, joined, leaving, error }

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
    this.speakerIds = const <String>[],
    this.camViewersByUser = const <String, List<String>>{},
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
  final List<String> speakerIds;
  final Map<String, List<String>> camViewersByUser;

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
    List<String>? speakerIds,
    Map<String, List<String>>? camViewersByUser,
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
      speakerIds: speakerIds ?? this.speakerIds,
      camViewersByUser: camViewersByUser ?? this.camViewersByUser,
    );
  }
}

const Object _unset = Object();
