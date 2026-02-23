// lib/services/recording_service.dart

import '../models/recording_session_model.dart';

class RecordingService {
  final List<RecordingSessionModel> _sessions = [];

  void startRecording(String roomId, String hostId) {
    final session = RecordingSessionModel(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      hostId: hostId,
      startedAt: DateTime.now(),
      endedAt: null,
    );
    _sessions.add(session);
  }

  void stopRecording(String sessionId) {
    final idx = _sessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx != -1) {
      final old = _sessions[idx];
      _sessions[idx] = RecordingSessionModel(
        sessionId: old.sessionId,
        roomId: old.roomId,
        hostId: old.hostId,
        startedAt: old.startedAt,
        endedAt: DateTime.now(),
      );
    }
  }

  List<RecordingSessionModel> getSessions() => _sessions;
}
