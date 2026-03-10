import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agora_participant.dart';
import 'user_display_name_provider.dart';

/// Participant state for Agora voice/video rooms
///
/// Tracks all participants in a room with their:
/// - uid (Agora user ID)
/// - userId (Firestore user ID)
/// - displayName (cached from Firestore)
/// - hasVideo (camera on/off)
/// - hasAudio (mic on/off)
/// - isSpeaking (active speaker detection)
/// - joinedAt (timestamp)
class AgoraParticipantNotifier extends Notifier<Map<int, AgoraParticipant>> {
  @override
  Map<int, AgoraParticipant> build() => {};

  /// Add or update a participant
  void addParticipant(AgoraParticipant participant) {
    state = {
      ...state,
      participant.uid: participant,
    };
  }

  /// Remove a participant
  void removeParticipant(int uid) {
    final newState = Map<int, AgoraParticipant>.from(state);
    newState.remove(uid);
    state = newState;
  }

  /// Update participant video state
  void updateVideoState(int uid, bool hasVideo) {
    final participant = state[uid];
    if (participant != null) {
      state = {
        ...state,
        uid: participant.copyWith(hasVideo: hasVideo),
      };
    }
  }

  /// Update participant audio state
  void updateAudioState(int uid, bool hasAudio) {
    final participant = state[uid];
    if (participant != null) {
      state = {
        ...state,
        uid: participant.copyWith(hasAudio: hasAudio),
      };
    }
  }

  /// Update speaking state (volume indicator)
  void updateSpeakingState(int uid, bool isSpeaking) {
    final participant = state[uid];
    if (participant != null) {
      state = {
        ...state,
        uid: participant.copyWith(isSpeaking: isSpeaking),
      };
    }
  }

  /// Update display name after fetching from Firestore
  void updateDisplayName(int uid, String displayName) {
    final participant = state[uid];
    if (participant != null) {
      state = {
        ...state,
        uid: participant.copyWith(displayName: displayName),
      };
    }
  }

  /// Clear all participants (when leaving room)
  void clear() {
    state = {};
  }

  /// Get participant by uid
  AgoraParticipant? getParticipant(int uid) => state[uid];

  /// Get all participants as list
  List<AgoraParticipant> get participants => state.values.toList();

  /// Get count of participants
  int get count => state.length;

  /// Get participants with video enabled
  List<AgoraParticipant> get participantsWithVideo => state.values.where((p) => p.hasVideo).toList();

  /// Get participants with audio enabled
  List<AgoraParticipant> get participantsWithAudio => state.values.where((p) => p.hasAudio).toList();

  /// Get currently speaking participants
  List<AgoraParticipant> get speakingParticipants => state.values.where((p) => p.isSpeaking).toList();
}

/// Provider for Agora participants state
final agoraParticipantsProvider = NotifierProvider<AgoraParticipantNotifier, Map<int, AgoraParticipant>>(() {
  return AgoraParticipantNotifier();
});

/// Helper to get participant display name with Firestore lookup
final participantDisplayNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  // Use the cached display name provider we just created
  return await ref.watch(userDisplayNameProvider(userId).future);
});


