// Stub implementation — used on platforms where neither dart:js_interop
// nor dart:io are available (e.g. WASM preview, unknown targets).
// All methods return safe no-op defaults.

// ignore: constant_identifier_names
const bool AGORA_WEB_DISABLED = true;

class AgoraPlatformService {
  static Future<void> initializeNative(String appId) async {}

  static Future<bool> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required String uid,
  }) async =>
      false;

  static Future<bool> leaveChannel() async => false;

  static Future<bool> setMicMuted(bool muted) async => false;

  static Future<bool> setVideoMuted(bool muted) async => false;

  static Future<bool> playCamera(String videoElementId) async => false;

  static Future<bool> playRemoteVideo(String uid, String videoElementId) async =>
      false;

  static Future<bool> initializeWeb(String appId) async => false;

  static Map<String, dynamic> getWebBridgeState() => {};

  static void enableWebDebugLogging() {}

  static void enableDebugLogging() {}

  // Returns Null so callers can assign to RtcEngine? without importing
  // agora_rtc_engine in this file.
  static Null get engine => null;

  static void registerRemotePublishedCallback(
      void Function(String uid, String mediaType) callback) {}
}
