// Stub for non-web platforms. All methods return no-op values since dart:js is web-only.
import 'dart:async';

class AgoraWebBridgeV2 {
  static bool get isAvailable => false;

  static Future<bool> init(String appId) async => false;

  static Future<bool> joinChannel({
    required String channelName,
    required String token,
    required String uid,
  }) async =>
      false;

  static Future<bool> leaveChannel() async => false;

  static Future<bool> enableLocalTracks({
    required bool enableAudio,
    required bool enableVideo,
  }) async =>
      false;

  static Future<bool> setAudioMuted(bool muted) async => false;

  static Future<bool> setVideoMuted(bool muted) async => false;

  static Future<bool> muteRemoteAudio(int remoteUid, bool muted) async => false;

  static Future<bool> setMicMuted(bool muted) => setAudioMuted(muted);

  static Map<String, bool>? getClientState() => null;

  static void setOnRemoteUserPublished(
      void Function(Map<String, dynamic> event)? callback) {}

  static void setOnRemoteUserUnpublished(
      void Function(Map<String, dynamic> event)? callback) {}

  static void setOnRemoteUserLeft(
      void Function(Map<String, dynamic> event)? callback) {}
}
