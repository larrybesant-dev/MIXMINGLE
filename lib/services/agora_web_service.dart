// lib/services/agora_web_service.dart
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, uri_does_not_exist
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:mix_and_mingle/core/utils/app_logger.dart';

class AgoraWebService {
  static bool get isAvailable => js.context.hasProperty('agoraWeb') && js.context['agoraWeb'] != null;

  static Future<bool> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required String uid,
  }) async {
    AppLogger.info('[AgoraWeb] ━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.info('[AgoraWeb] Attempting to join via JS SDK...');
    AppLogger.info('[AgoraWeb] window.agoraWeb available: $isAvailable');

    if (!isAvailable) {
      AppLogger.warning('[AgoraWeb] ❌ ERROR: window.agoraWeb not found in index.html');
      return false;
    }

    AppLogger.info('[AgoraWeb] Calling window.agoraWeb.joinChannel...');
    AppLogger.info('[AgoraWeb]   └─ appId: ${appId.substring(0, 8)}...');
    AppLogger.info('[AgoraWeb]   └─ channel: $channelName');
    AppLogger.info('[AgoraWeb]   └─ uid: $uid');
    AppLogger.info('[AgoraWeb]   └─ token: ${token.substring(0, 20)}...');

    try {
      // Guard: ensure bridge is ready before calling
      if (js.context['agoraWeb'] == null) {
        AppLogger.warning('[AgoraWeb] ⚠️ JS bridge not ready, retrying...');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Call via wrapper object for stable access
      final jsResult = js.context['agoraWeb'].callMethod('joinChannel', [appId, channelName, token, uid]);
      final result = await js_util.promiseToFuture<bool>(jsResult);

      if (result) {
        AppLogger.info('[AgoraWeb] ✅ JS SDK joinChannel returned SUCCESS');
        AppLogger.info('[AgoraWeb] ✅ Local tracks should be created and published');
        AppLogger.info('[AgoraWeb] ✅ Waiting for remote user events...');
      } else {
        AppLogger.warning('[AgoraWeb] ❌ JS SDK joinChannel returned FALSE');
      }

      AppLogger.info('[AgoraWeb] ━━━━━━━━━━━━━━━━━━━━━━━━');
      return result;
    } catch (e) {
      AppLogger.warning('[AgoraWeb] ❌ EXCEPTION in joinChannel: $e');
      AppLogger.info('[AgoraWeb] ━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  static Future<bool> leaveChannel() async {
    if (!isAvailable) return false;

    final jsResult = js.context.callMethod('agoraWebLeaveChannel', []);
    final result = await js_util.promiseToFuture<bool>(jsResult);
    return result;
  }

  static Future<void> setMicMuted(bool muted) async {
    if (!isAvailable) return;
    final jsResult = js.context.callMethod('agoraWebMuteAudio', [muted]);
    await js_util.promiseToFuture(jsResult);
  }

  static Future<void> setVideoMuted(bool muted) async {
    if (!isAvailable) return;
    final jsResult = js.context.callMethod('agoraWebMuteVideo', [muted]);
    await js_util.promiseToFuture(jsResult);
  }
}
