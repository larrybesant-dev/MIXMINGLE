abstract class AppEvent {
  const AppEvent({required this.id, required this.timestamp});

  final String id;
  final DateTime timestamp;
}

class RoomJoinedEvent extends AppEvent {
  const RoomJoinedEvent({
    required super.id,
    required super.timestamp,
    required this.userId,
    required this.roomId,
    this.roomName,
  });

  final String userId;
  final String roomId;
  final String? roomName;
}

class RoomLeftEvent extends AppEvent {
  const RoomLeftEvent({
    required super.id,
    required super.timestamp,
    required this.userId,
    required this.roomId,
    this.roomName,
  });

  final String userId;
  final String roomId;
  final String? roomName;
}

class MicStateChangedEvent extends AppEvent {
  const MicStateChangedEvent({
    required super.id,
    required super.timestamp,
    required this.userId,
    required this.roomId,
    required this.isSpeaker,
  });

  final String userId;
  final String roomId;
  final bool isSpeaker;
}

class CameraStateChangedEvent extends AppEvent {
  const CameraStateChangedEvent({
    required super.id,
    required super.timestamp,
    required this.userId,
    required this.roomId,
    required this.isCameraOn,
  });

  final String userId;
  final String roomId;
  final bool isCameraOn;
}

class FollowEvent extends AppEvent {
  const FollowEvent({
    required super.id,
    required super.timestamp,
    required this.fromUserId,
    required this.toUserId,
    this.fromUsername,
    this.toUsername,
  });

  final String fromUserId;
  final String toUserId;
  final String? fromUsername;
  final String? toUsername;
}

class ProfileUpdatedEvent extends AppEvent {
  const ProfileUpdatedEvent({
    required super.id,
    required super.timestamp,
    required this.userId,
  });

  final String userId;
}

class CamViewEvent extends AppEvent {
  const CamViewEvent({
    required super.id,
    required super.timestamp,
    required this.viewerId,
    required this.targetUserId,
  });

  final String viewerId;
  final String targetUserId;
}
