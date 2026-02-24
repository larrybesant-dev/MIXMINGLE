// lib/features/room/live/live_room_audio.dart
//
// Active microphone manager.
//
// Enforces the rule: only 1–4 mics can be active at once depending on type.
//
//   social    → max 4 simultaneous mics (group conversation)
//   broadcast → max 1  (host/streamer only)
//   concert   → max 1  (performer only)
//   voice     → max 4  (audio-only room)
//
// This class is pure logic — it returns a MicDecision but never calls
// the video engine directly. The controller acts on that decision.
// ───────────────────────────────────────────────────────────────────────────

import 'live_room_schema.dart';

// ── Decision result ────────────────────────────────────────────────────────

class MicDecision {
  final bool   allowed;
  final String? reason;

  const MicDecision._(this.allowed, this.reason);

  static const allow = MicDecision._(true, null);

  factory MicDecision.denied(String reason) => MicDecision._(false, reason);

  @override
  String toString() =>
      allowed ? 'MicDecision(allow)' : 'MicDecision(denied: $reason)';
}

// ── Manager ────────────────────────────────────────────────────────────────

class LiveRoomAudioManager {
  LiveRoomAudioManager({required this.maxActiveMics});

  final int maxActiveMics;

  factory LiveRoomAudioManager.forRoomType(String roomType) =>
      LiveRoomAudioManager(maxActiveMics: maxMicsForRoomType(roomType));

  // ── Active mic tracking ───────────────────────────────────────────────────

  final Set<String> _activeMicUsers = {};

  int get activeMicCount => _activeMicUsers.length;
  bool get hasCapacity   => _activeMicUsers.length < maxActiveMics;

  Set<String> get activeMicUsers => Set.unmodifiable(_activeMicUsers);

  // ── Rules ─────────────────────────────────────────────────────────────────

  /// Can [userId] unmute right now?
  MicDecision canUnmute(String userId) {
    if (_activeMicUsers.contains(userId)) return MicDecision.allow;
    if (_activeMicUsers.length >= maxActiveMics) {
      return MicDecision.denied(
        'Only $maxActiveMics mic(s) allowed at once '
        '(${_activeMicUsers.length} currently active).',
      );
    }
    return MicDecision.allow;
  }

  /// Can [userId] turn their camera on given current cam/broadcaster counts?
  MicDecision canTurnCamOn({
    required String userId,
    required int currentCamCount,
    required int maxCams,
  }) {
    if (maxCams == 0) {
      return MicDecision.denied('Camera is not allowed in this room type.');
    }
    if (currentCamCount >= maxCams) {
      return MicDecision.denied('All $maxCams camera slot(s) are taken.');
    }
    return MicDecision.allow;
  }

  // ── Sync with Firestore participant list ──────────────────────────────────

  /// Rebuild the in-memory active set from the ground-truth Firestore snapshot.
  void syncFromParticipants(List<RoomParticipant> participants) {
    _activeMicUsers
      ..clear()
      ..addAll(participants.where((p) => p.isMicActive).map((p) => p.userId));
  }

  // ── Mutation helpers ─────────────────────────────────────────────────────

  void markMicActive(String userId)   => _activeMicUsers.add(userId);
  void markMicInactive(String userId) => _activeMicUsers.remove(userId);
  void clear()                        => _activeMicUsers.clear();
}
