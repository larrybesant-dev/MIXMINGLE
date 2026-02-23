// Mic states and enums
// Mic states and enums
enum MicStatus {
  inactive, // Not in use
  muted, // Muted but active
  active, // Speaking
  noiseDetected, // Noise suppression active
  error, // Error state
}

enum MicQuality {
  low, // 8kHz, mono, codec voice
  medium, // 16kHz, mono, codec voice
  high, // 48kHz, stereo, codec music
}

class MicState {
  final String uid;
  final bool isActive;
  final bool isMuted;
  final MicStatus status;
  final MicQuality quality;
  final int noiseLevel; // 0-100
  final int gainLevel; // 0-100
  final bool prioritySpeaker;
  final int queuePosition;
  final DateTime? approvedAt;

  // Metadata
  final String userName;
  final String? userPhotoUrl;
  final bool isVIP;
  final bool isBroadcaster;

  const MicState({
    required this.uid,
    required this.isActive,
    required this.isMuted,
    required this.status,
    required this.quality,
    required this.noiseLevel,
    required this.gainLevel,
    required this.prioritySpeaker,
    required this.queuePosition,
    this.approvedAt,
    required this.userName,
    this.userPhotoUrl,
    required this.isVIP,
    required this.isBroadcaster,
  });

  bool get canSpeak => isActive && !isMuted && status != MicStatus.error;

  String get statusIcon {
    switch (status) {
      case MicStatus.active:
        return 'ðŸŽ¤'; // Speaking
      case MicStatus.muted:
        return 'ðŸ”‡'; // Muted
      case MicStatus.noiseDetected:
        return 'ðŸ”Š'; // Noise suppression
      case MicStatus.error:
        return 'âŒ'; // Error
      case MicStatus.inactive:
        return 'â­•'; // Inactive
    }
  }

  String get statusText {
    switch (status) {
      case MicStatus.active:
        return 'SPEAKING';
      case MicStatus.muted:
        return 'MUTED';
      case MicStatus.noiseDetected:
        return 'NOISY';
      case MicStatus.error:
        return 'ERROR';
      case MicStatus.inactive:
        return 'INACTIVE';
    }
  }

  @override
  String toString() => 'MicState(uid: $uid, userName: $userName, status: ${status.name})';
}

// Mic timer for auto-mute after duration
class MicTimer {
  final String userId;
  final Duration duration;
  final DateTime startedAt;
  bool isExpired;

  MicTimer({
    required this.userId,
    required this.duration,
    required this.startedAt,
    this.isExpired = false,
  });

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(startedAt);
    return duration - elapsed;
  }

  bool get hasExpired => remainingTime.inSeconds <= 0;
}

// Noise suppression settings
class NoiseSuppressionSettings {
  final bool enabled;
  final double threshold; // 0-1
  final int reductionFactor; // dB

  const NoiseSuppressionSettings({
    this.enabled = true,
    this.threshold = 0.3,
    this.reductionFactor = 20,
  });

  const NoiseSuppressionSettings.low()
      : enabled = true,
        threshold = 0.5,
        reductionFactor = 10;

  const NoiseSuppressionSettings.medium()
      : enabled = true,
        threshold = 0.3,
        reductionFactor = 20;

  const NoiseSuppressionSettings.high()
      : enabled = true,
        threshold = 0.1,
        reductionFactor = 30;
}
