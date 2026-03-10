// Room & Video Participant Provider - Manages active video rooms and participants

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_models.dart';

/// Active room notifier
class ActiveRoomIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setRoomId(String? roomId) => state = roomId;
  void clearRoom() => state = null;
}

final activeRoomIdProvider = NotifierProvider<ActiveRoomIdNotifier, String?>(
  () => ActiveRoomIdNotifier(),
);

/// Participants notifier for active room
class ParticipantsNotifier extends Notifier<List<VideoParticipant>> {
  @override
  List<VideoParticipant> build() {
    return [];
  }

  /// Add participant
  void addParticipant(VideoParticipant participant) {
    if (!state.any((p) => p.userId == participant.userId)) {
      state = [...state, participant];
    }
  }

  /// Remove participant
  void removeParticipant(String userId) {
    state = state.where((p) => p.userId != userId).toList();
  }

  /// Toggle audio
  void toggleAudio(String userId, bool enabled) {
    state = state.map((participant) {
      if (participant.userId == userId) {
        return participant.copyWith(isAudioEnabled: enabled);
      }
      return participant;
    }).toList();
  }

  /// Toggle video
  void toggleVideo(String userId, bool enabled) {
    state = state.map((participant) {
      if (participant.userId == userId) {
        return participant.copyWith(isVideoEnabled: enabled);
      }
      return participant;
    }).toList();
  }

  /// Toggle screen share
  void toggleScreenShare(String userId, bool enabled) {
    state = state.map((participant) {
      if (participant.userId == userId) {
        return participant.copyWith(isScreenSharing: enabled);
      }
      return participant;
    }).toList();
  }

  /// Update camera approval status
  void updateCameraApprovalStatus(String userId, String status) {
    state = state.map((participant) {
      if (participant.userId == userId) {
        return participant.copyWith(cameraApprovalStatus: status);
      }
      return participant;
    }).toList();
  }

  /// Clear all (when leaving room)
  void clearAll() {
    state = [];
  }
}

/// Participants provider
final participantsProvider = NotifierProvider<ParticipantsNotifier, List<VideoParticipant>>(
  () => ParticipantsNotifier(),
);

/// Participants with video enabled
final videoParticipantsProvider = Provider<List<VideoParticipant>>((ref) {
  final participants = ref.watch(participantsProvider);
  return participants
      .where((p) => p.isVideoEnabled && p.cameraApprovalStatus == 'approved')
      .toList();
});

/// Participants count
final participantsCountProvider = Provider<int>((ref) {
  return ref.watch(participantsProvider).length;
});

/// Audio enabled participants
final audioParticipantsProvider = Provider<List<VideoParticipant>>((ref) {
  final participants = ref.watch(participantsProvider);
  return participants.where((p) => p.isAudioEnabled).toList();
});

/// Screen sharing participant
final screenShareParticipantProvider = Provider<VideoParticipant?>((ref) {
  final participants = ref.watch(participantsProvider);
  try {
    return participants.firstWhere((p) => p.isScreenSharing);
  } catch (e) {
    return null;
  }
});




