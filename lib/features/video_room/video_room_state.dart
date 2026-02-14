/// Immutable state model for video room
class VideoRoomState {
  final String roomId;
  final String userId;
  final bool isInitializing;
  final bool isInitialized;
  final bool isJoining;
  final bool isJoined;
  final bool isLeaving;
  final bool cameraEnabled;
  final bool micEnabled;
  final String? error;
  final int remoteUserCount;
  final List<String> remoteUserIds;
  final DateTime? joinedAt;

  const VideoRoomState({
    required this.roomId,
    required this.userId,
    this.isInitializing = false,
    this.isInitialized = false,
    this.isJoining = false,
    this.isJoined = false,
    this.isLeaving = false,
    this.cameraEnabled = false,
    this.micEnabled = false,
    this.error,
    this.remoteUserCount = 0,
    this.remoteUserIds = const [],
    this.joinedAt,
  });

  /// Current phase of video room lifecycle
  VideoRoomPhase get phase {
    if (error != null) return VideoRoomPhase.error;
    if (isInitializing) return VideoRoomPhase.initializing;
    if (!isInitialized) return VideoRoomPhase.notInitialized;
    if (isJoining) return VideoRoomPhase.joining;
    if (isJoined) return VideoRoomPhase.joined;
    if (isLeaving) return VideoRoomPhase.leaving;
    return VideoRoomPhase.left;
  }

  bool get isReady => isInitialized && isJoined && error == null;

  /// Create a copy with modified fields
  VideoRoomState copyWith({
    String? roomId,
    String? userId,
    bool? isInitializing,
    bool? isInitialized,
    bool? isJoining,
    bool? isJoined,
    bool? isLeaving,
    bool? cameraEnabled,
    bool? micEnabled,
    String? error,
    int? remoteUserCount,
    List<String>? remoteUserIds,
    DateTime? joinedAt,
  }) {
    return VideoRoomState(
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      isJoining: isJoining ?? this.isJoining,
      isJoined: isJoined ?? this.isJoined,
      isLeaving: isLeaving ?? this.isLeaving,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      error: error ?? this.error,
      remoteUserCount: remoteUserCount ?? this.remoteUserCount,
      remoteUserIds: remoteUserIds ?? this.remoteUserIds,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() => 'VideoRoomState(phase=$phase, isReady=$isReady, error=$error)';
}

/// Lifecycle phases for video room
enum VideoRoomPhase {
  notInitialized,
  initializing,
  joined,
  joining,
  leaving,
  left,
  error,
}



