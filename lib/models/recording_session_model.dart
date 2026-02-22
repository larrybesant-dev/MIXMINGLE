// lib/models/recording_session_model.dart

class RecordingSessionModel {
  final String sessionId;
  final String roomId;
  final String hostId;
  final DateTime startedAt;
  final DateTime? endedAt;

  RecordingSessionModel({
    required this.sessionId,
    required this.roomId,
    required this.hostId,
    required this.startedAt,
    this.endedAt,
  });
}
