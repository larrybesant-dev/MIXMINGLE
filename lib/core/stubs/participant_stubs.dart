// lib/core/stubs/participant_stubs.dart
// Minimal ParticipantModel stub to unblock analyzer errors in remote_video_tile.dart

class ParticipantModel {
  final bool isHost;
  final bool isScreenSharing;
  final bool hasError;
  const ParticipantModel(
      {this.isHost = false,
      this.isScreenSharing = false,
      this.hasError = false});
}
