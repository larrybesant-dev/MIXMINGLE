// Stub for non-web platforms. All methods return no-op values since dart:js is web-only.
import 'dart:async';

class AgoraWebBridgeV3 {
  static bool get isAvailable => false;

  static Future<bool> init(String appId) async => false;

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

  static Future<bool> playRemoteVideo(String uid, String elementId) async => false;

  static Map<String, dynamic> getState() => {};

  static void enableDebugLogging() {}

  static void printDebugInfo() {}

  static void registerRemotePublishedCallback(
      void Function(String uid, String mediaType) callback) {}

  static Future<bool> renewToken(String newToken) async => false;

  static void registerTokenWillExpireCallback(
      void Function(String channelName, String uid) callback) {}
}
