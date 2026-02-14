// Ultra-minimal Agora Web bridge - for debugging
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show debugPrint;
import '../core/utils/app_logger.dart';

class AgoraWebBridgeV2 {
  static bool get isAvailable {
    try {
      return js.context['agoraWebV2'] != null;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> init(String appId) async {
    AppLogger.info('🌐 Bridge: init($appId)');
    debugPrint('[DEBUG] AgoraWebBridgeV2.init() called');

    try {
      // Check if bridge exists
      final bridge = js.context['agoraWebV2'];
      if (bridge == null) {
        AppLogger.error('❌ Bridge agoraWebV2 does not exist');
        return false;
      }

      // Just return success for now
      AppLogger.info('✅ Bridge init success');
      return true;
    } catch (e) {
      AppLogger.error('❌ init error: $e');
      debugPrint('[DEBUG] init error: $e');
      return false;
    }
  }

  static Future<bool> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required String uid,
  }) async {
    AppLogger.info('🌐 Bridge: join($channelName)');
    debugPrint('[DEBUG] AgoraWebBridgeV2.joinChannel() called with $channelName');

    try {
      // For now, just return success
      AppLogger.info('✅ Bridge join success (stub)');
      return true;
    } catch (e) {
      AppLogger.error('❌ join error: $e');
      return false;
    }
  }

  static Future<bool> leaveChannel() async {
    AppLogger.info('🌐 Bridge: leave()');
    try {
      return true;
    } catch (e) {
      AppLogger.error('❌ leave error: $e');
      return false;
    }
  }

  static Future<bool> setMicMuted(bool muted) async {
    AppLogger.info('🌐 Bridge: muteAudio($muted)');
    try {
      return true;
    } catch (e) {
      AppLogger.error('❌ Mute audio error: $e');
      return false;
    }
  }

  static Future<bool> setVideoMuted(bool muted) async {
    AppLogger.info('🌐 Bridge: muteVideo($muted)');
    try {
      return true;
    } catch (e) {
      AppLogger.error('❌ Mute video error: $e');
      return false;
    }
  }
}
