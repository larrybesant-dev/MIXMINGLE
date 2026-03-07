// Native (IO) implementation of AgoraPlatformService.
// Only compiled when dart.library.io is available (Android, iOS, Windows, macOS, Linux).
// Does NOT import agora_web_bridge_v3 — keeping the web bridge off native builds.

import 'package:agora_rtc_engine/agora_rtc_engine.dart' as native;
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/utils/app_logger.dart';

// ignore: constant_identifier_names
const bool AGORA_WEB_DISABLED = false;

class AgoraPlatformService {
  static native.RtcEngine? _engine;

  static native.RtcEngine? get engine => _engine;

  static Future<void> initializeNative(String appId) async {
    if (_engine != null) return;

    _engine = native.createAgoraRtcEngine();
    await _engine!.initialize(
      native.RtcEngineContext(
        appId: appId,
        channelProfile:
            native.ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    await _engine!.enableVideo();
    await _engine!.enableAudio();
  }

  static Future<bool> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required String uid,
  }) async {
    AppLogger.info('📱 NATIVE PATH: Using Agora NATIVE SDK (Flutter)');

    if (_engine == null) {
      AppLogger.info('Initializing Agora native engine...');
      await initializeNative(appId);
    }

    AppLogger.info('Calling Agora native joinChannel...');
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: int.tryParse(uid) ?? 0,
      options: const native.ChannelMediaOptions(
        clientRoleType: native.ClientRoleType.clientRoleBroadcaster,
        channelProfile:
            native.ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    AppLogger.info('Agora native joinChannel successful');
    return true;
  }

  static Future<bool> leaveChannel() async {
    if (_engine == null) return false;
    await _engine!.leaveChannel();
    return true;
  }

  static Future<bool> setMicMuted(bool muted) async {
    if (_engine == null) return false;
    await _engine!.muteLocalAudioStream(muted);
    return true;
  }

  static Future<bool> setVideoMuted(bool muted) async {
    if (_engine == null) return false;
    await _engine!.muteLocalVideoStream(muted);
    return true;
  }

  // Web-only — always false on native.
  static Future<bool> playCamera(String videoElementId) async => false;

  static Future<bool> playRemoteVideo(
          String uid, String videoElementId) async =>
      false;

  static Future<bool> initializeWeb(String appId) async => false;

  static Map<String, dynamic> getWebBridgeState() => {};

  static void enableWebDebugLogging() {
    debugPrint('[AGORA_IO] enableWebDebugLogging: no-op on native');
  }

  static void enableDebugLogging() {
    debugPrint('[AGORA_IO] enableDebugLogging: no-op on native');
  }

  static void registerRemotePublishedCallback(
      void Function(String uid, String mediaType) callback) {
    // No-op on native — native events are delivered via RtcEngineEventHandler.
  }
}
