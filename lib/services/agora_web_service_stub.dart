// Stub for non-web platforms
class AgoraWebService {
  static bool get isAvailable => false;

  static Future<bool> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required String uid,
  }) async {
    throw UnsupportedError('AgoraWebService is only available on web');
  }

  static Future<bool> leaveChannel() async {
    throw UnsupportedError('AgoraWebService is only available on web');
  }

  static Future<void> setMicMuted(bool muted) async {
    throw UnsupportedError('AgoraWebService is only available on web');
  }

  static Future<void> setVideoMuted(bool muted) async {
    throw UnsupportedError('AgoraWebService is only available on web');
  }
}
