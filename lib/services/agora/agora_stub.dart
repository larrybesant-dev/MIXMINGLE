  Future<List<Map<String, dynamic>>> getDevices() async {
    return [
      {'kind': 'videoinput', 'deviceId': 'default-camera', 'label': 'Default Camera'},
      {'kind': 'audioinput', 'deviceId': 'default-mic', 'label': 'Default Microphone'},
    ];
  }

  Future<bool> switchCamera(String deviceId) async {
    return true;
  }

  Future<bool> switchMic(String deviceId) async {
    return true;
  }

  Future<bool> init(String appId) async {
    return true;
  }

  Future<bool> startCamera(String containerId, String? deviceId) async {
    return true;
  }

  Future<bool> startMic(String? deviceId) async {
    return true;
  }

class AgoraService {
  bool get isInitialized => true;
  Future<void> initialize() async {}
  Future<void> joinChannel({String? token, String? channelId, String? uid}) async {}
  Future<void> leaveChannel() async {}
  Future<void> setMicrophoneMuted(bool muted) async {}
  Future<void> setVideoCameraMuted(bool muted) async {}
  Future<void> dispose() async {}

  Future<List<Map<String, dynamic>>> getDevices() async {
    return [
      {'kind': 'videoinput', 'deviceId': 'default-camera', 'label': 'Default Camera'},
      {'kind': 'audioinput', 'deviceId': 'default-mic', 'label': 'Default Microphone'},
    ];
  }

  Future<bool> switchCamera(String deviceId) async {
    return true;
  }

  Future<bool> switchMic(String deviceId) async {
    return true;
  }

  Future<bool> startMic(String? deviceId) async {
    return true;
  }

  // Add missing methods for web stub
  Future<bool> init(String appId) async {
    return true;
  }

  Future<bool> startCamera(String containerId, String? deviceId) async {
    return true;
  }
}

// Web-safe stub instance
final agoraEngine = AgoraService();

