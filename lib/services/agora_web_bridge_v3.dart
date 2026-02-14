// Agora Web Bridge v3 - Production Ready
// Interfaces with agora_web_v5_production.js
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../core/utils/app_logger.dart';

class AgoraWebBridgeV3 {
  static bool get isAvailable {
    if (!kIsWeb) return false;
    try {
      final jsAvailable = js.context['agoraWebInit'] != null &&
          js.context['agoraWebJoinChannel'] != null;
      return jsAvailable;
    } catch (e) {
      debugPrint('[BRIDGE] Error checking isAvailable: $e');
      return false;
    }
  }

  /// Initialize Agora Web with App ID
  static Future<bool> init(String appId) async {
    if (!kIsWeb) {
      AppLogger.error('[BRIDGE] Not on web, returning false');
      return false;
    }

    try {
      debugPrint('[BRIDGE] Initializing with appId: ${appId.substring(0, 8)}...');
      AppLogger.info('🌐 Initializing Agora Web SDK v5...');

      final initFn = js.context['agoraWebInit'];
      if (initFn == null) {
        throw Exception('agoraWebInit function not found in window');
      }

      // Call JS init and convert Promise to Future
      final promiseObj = initFn.call(appId);
      final result = await _promiseToFuture(promiseObj);

      if (result == true) {
        AppLogger.info('✅ Agora Web SDK v5 initialized');
        debugPrint('[BRIDGE] Init successful');
        return true;
      } else {
        AppLogger.error('❌ Init returned false');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Agora init failed: $e');
      debugPrint('[BRIDGE] Init error: $e');
      return false;
    }
  }

  /// Join a channel with token
  static Future<bool> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required String uid,
  }) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Joining channel: $channelName, uid: $uid, token length: ${token.length}');
      AppLogger.info('🔗 Joining Agora channel: $channelName...');

      final joinFn = js.context['agoraWebJoinChannel'];
      if (joinFn == null) {
        throw Exception('agoraWebJoinChannel function not found in window');
      }

      // Call JS joinChannel(appId, channelName, token, uid)
      final promiseObj = joinFn.call(appId, channelName, token, uid);
      final result = await _promiseToFuture(promiseObj, timeout: const Duration(seconds: 35));

      if (result == true) {
        AppLogger.info('✅ Successfully joined channel: $channelName');
        debugPrint('[BRIDGE] joinChannel successful');
        return true;
      } else {
        AppLogger.error('❌ joinChannel returned false');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Failed to join channel: $e');
      debugPrint('[BRIDGE] joinChannel error: $e');
      return false;
    }
  }

  /// Leave the current channel
  static Future<bool> leaveChannel() async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Leaving channel...');
      AppLogger.info('👋 Leaving channel...');

      final leaveFn = js.context['agoraWebLeaveChannel'];
      if (leaveFn == null) {
        throw Exception('agoraWebLeaveChannel function not found in window');
      }

      final promiseObj = leaveFn.call();
      final result = await _promiseToFuture(promiseObj);

      if (result == true) {
        AppLogger.info('✅ Left channel');
        return true;
      } else {
        AppLogger.warning('⚠️ Leave returned false');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Failed to leave channel: $e');
      debugPrint('[BRIDGE] leaveChannel error: $e');
      return false;
    }
  }

  /// Set microphone muted state
  static Future<bool> setMicMuted(bool muted) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Setting mic muted: $muted');
      final fn = js.context['agoraWebSetMicMuted'];
      if (fn == null) {
        throw Exception('agoraWebSetMicMuted function not found in window');
      }

      final promiseObj = fn.call(muted);
      final result = await _promiseToFuture(promiseObj);

      if (result == true) {
        AppLogger.info('🎤 Microphone ${muted ? 'muted' : 'unmuted'}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('❌ Failed to set mic mute: $e');
      return false;
    }
  }

  /// Set video muted state
  static Future<bool> setVideoMuted(bool muted) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Setting video muted: $muted');
      final fn = js.context['agoraWebSetVideoMuted'];
      if (fn == null) {
        throw Exception('agoraWebSetVideoMuted function not found in window');
      }

      final promiseObj = fn.call(muted);
      final result = await _promiseToFuture(promiseObj);

      if (result == true) {
        AppLogger.info('📹 Video ${muted ? 'disabled' : 'enabled'}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('❌ Failed to set video mute: $e');
      return false;
    }
  }

  /// Get current Agora Web state (for debugging)
  static Map<String, dynamic> getState() {
    if (!kIsWeb) return {};

    try {
      final stateFn = js.context['agoraWebGetState'];
      if (stateFn == null) {
        return {'error': 'agoraWebGetState not found'};
      }

      final stateObj = stateFn.call();

      // Convert JavaScript object to Dart Map
      return Map<String, dynamic>.from(
        stateObj.keys.fold<Map<String, dynamic>>({}, (map, key) {
          map[key] = stateObj[key];
          return map;
        })
      );
    } catch (e) {
      debugPrint('[BRIDGE] Error getting state: $e');
      return {'error': e.toString()};
    }
  }

  /// Enable debug mode (shows extra logging)
  static void enableDebugLogging() {
    if (!kIsWeb) return;

    try {
      js.context['__AGORA_DEBUG'] = true;
      debugPrint('[BRIDGE] Debug logging enabled');
      AppLogger.info('🔍 Agora debug logging enabled');
    } catch (e) {
      debugPrint('[BRIDGE] Error enabling debug: $e');
    }
  }

  /// Print debug info to console
  static void printDebugInfo() {
    if (!kIsWeb) {
      debugPrint('[BRIDGE] Not on web');
      return;
    }

    try {
      final debugFn = js.context['agoraWebDebug'];
      if (debugFn != null) {
        debugFn.call();
      }
    } catch (e) {
      debugPrint('[BRIDGE] Error printing debug info: $e');
    }
  }

  // ========== INTERNAL UTILITIES ==========

  /// Convert JavaScript Promise to Dart Future
  static Future<dynamic> _promiseToFuture(
    dynamic jsPromise, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final completer = Completer<dynamic>();

    try {
      if (jsPromise == null) {
        completer.completeError(Exception('Promise is null'));
        return completer.future;
      }

      // Create a wrapper function that will be called when promise resolves
      void resolveFunc(dynamic result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }

      // Create a wrapper function that will be called when promise rejects
      void rejectFunc(dynamic error) {
        if (!completer.isCompleted) {
          final errorMsg = error?.toString() ?? 'Unknown JavaScript error';
          completer.completeError(Exception(errorMsg));
        }
      }

      // Attach .then() and .catch() handlers to the promise
      // Try to call .then() with resolve and reject callbacks
      try {
        // Use JavaScript interop to call then() on the promise
        (jsPromise as dynamic).then(resolveFunc, rejectFunc);
      } catch (e) {
        // If standard .then() fails, try alternative approach
        completer.completeError(Exception('Failed to attach promise handlers: $e'));
      }

      // Apply timeout
      return completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Agora operation timeout after ${timeout.inSeconds}s',
        ),
      );
    } catch (e) {
      debugPrint('[BRIDGE] Error converting promise: $e');
      return Future.error(Exception('Failed to convert promise: $e'));
    }
  }
}

// ========== COMPATIBILITY ALIAS ==========
// Keep old name for backward compatibility
typedef AgoraWebBridgeV2 = AgoraWebBridgeV3;
