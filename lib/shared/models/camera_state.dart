enum CameraQuality {
  low, // 360p, 500 kbps
  medium, // 720p, 1 mbps
  high, // 1080p, 2 mbps
}

enum CameraStatus {
  inactive, // Not streaming
  loading, // Connecting
  active, // Streaming
  frozen, // Detected frozen
  error, // Error state
}

class CameraState {
  final String uid;
  final bool isLive;
  final CameraQuality quality;
  final CameraStatus status;
  final int viewCount;
  final bool isFrozen;
  final bool isSpotlighted;
  final DateTime startedAt;

  // Paltalk-style metadata
  final String userName;
  final String? userPhotoUrl;
  final bool isVIP;
  final bool isBroadcaster;

  const CameraState({
    required this.uid,
    required this.isLive,
    required this.quality,
    required this.status,
    required this.viewCount,
    required this.isFrozen,
    required this.isSpotlighted,
    required this.startedAt,
    required this.userName,
    this.userPhotoUrl,
    required this.isVIP,
    required this.isBroadcaster,
  });

  // Uptime in seconds
  int get uptimeSeconds {
    return DateTime.now().difference(startedAt).inSeconds;
  }

  // Quality icon for display
  String get qualityIcon {
    switch (quality) {
      case CameraQuality.high:
        return '📡'; // HD
      case CameraQuality.medium:
        return '📶'; // SD
      case CameraQuality.low:
        return '📱'; // Mobile
    }
  }

  @override
  String toString() => 'CameraState(uid: $uid, userName: $userName, quality: ${quality.name}, status: ${status.name})';
}
