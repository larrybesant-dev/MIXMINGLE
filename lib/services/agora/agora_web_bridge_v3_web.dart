// Agora Web Bridge v3 - Production Ready
// Interfaces with agora_web_v5_production.js
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../core/utils/app_logger.dart';

class AgoraWebBridgeV3 {
  static bool get isAvailable {
    if (!kIsWeb) return false;
    try {
      final webObj = js.context['agoraWeb'];
      final objReady = webObj is js.JsObject &&
          webObj['init'] != null &&
          webObj['joinChannel'] != null;
      final flatReady = js.context['agoraWebInit'] != null &&
          js.context['agoraWebJoinChannel'] != null;
      final jsAvailable = objReady || flatReady;
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
      AppLogger.info('ðŸŒ Initializing Agora Web SDK v5...');

      // Call JS init and convert Promise to Future.
      final promiseObj = _invokeBridgeMethod(
        objectMethod: 'init',
        flatMethod: 'agoraWebInit',
        args: [appId],
      );
      final result = await _promiseToFuture(promiseObj);

      if (_isSuccessResult(result)) {
        AppLogger.info('âœ… Agora Web SDK v5 initialized');
        debugPrint('[BRIDGE] Init successful');
        return true;
      } else {
        AppLogger.error('âŒ Init returned false');
        return false;
      }
    } catch (e) {
      AppLogger.error('âŒ Agora init failed: $e');
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
      AppLogger.info('ðŸ”— Joining Agora channel: $channelName...');

      // Call JS joinChannel(appId, channelName, token, uid)
      final promiseObj = _invokeBridgeMethod(
        objectMethod: 'joinChannel',
        flatMethod: 'agoraWebJoinChannel',
        args: [appId, channelName, token, uid],
      );
      final result = await _promiseToFuture(promiseObj, timeout: const Duration(seconds: 35));

      if (_isSuccessResult(result)) {
        AppLogger.info('âœ… Successfully joined channel: $channelName');
        debugPrint('[BRIDGE] joinChannel successful');
        return true;
      } else {
        AppLogger.error('âŒ joinChannel returned false');
        return false;
      }
    } catch (e) {
      AppLogger.error('âŒ Failed to join channel: $e');
      debugPrint('[BRIDGE] joinChannel error: $e');
      return false;
    }
  }

  /// Leave the current channel
  static Future<bool> leaveChannel() async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Leaving channel...');
      AppLogger.info('ðŸ‘‹ Leaving channel...');

      final promiseObj = _invokeBridgeMethod(
        objectMethod: 'leaveChannel',
        flatMethod: 'agoraWebLeaveChannel',
      );
      final result = await _promiseToFuture(promiseObj);

      if (_isSuccessResult(result)) {
        AppLogger.info('âœ… Left channel');
        return true;
      } else {
        AppLogger.warning('âš ï¸ Leave returned false');
        return false;
      }
    } catch (e) {
      AppLogger.error('âŒ Failed to leave channel: $e');
      debugPrint('[BRIDGE] leaveChannel error: $e');
      return false;
    }
  }

  /// Set microphone muted state
  static Future<bool> setMicMuted(bool muted) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Setting mic muted: $muted');
      final promiseObj = _invokeBridgeMethod(
        objectMethod: 'setMicMuted',
        flatMethod: 'agoraWebSetMicMuted',
        args: [muted],
      );
      final result = await _promiseToFuture(promiseObj);

      if (_isSuccessResult(result)) {
        AppLogger.info('ðŸŽ¤ Microphone ${muted ? 'muted' : 'unmuted'}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('âŒ Failed to set mic mute: $e');
      return false;
    }
  }

  /// Set video muted state
  static Future<bool> setVideoMuted(bool muted) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[BRIDGE] Setting video muted: $muted');
      final promiseObj = _invokeBridgeMethod(
        objectMethod: 'setVideoMuted',
        flatMethod: 'agoraWebSetVideoMuted',
        args: [muted],
      );
      final result = await _promiseToFuture(promiseObj);

      if (_isSuccessResult(result)) {
        AppLogger.info('ðŸ“¹ Video ${muted ? 'disabled' : 'enabled'}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('âŒ Failed to set video mute: $e');
      return false;
    }
  }

  static Future<bool> playCamera(String videoElementId) async {
    if (!kIsWeb) return false;

    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'playCamera',
          flatMethod: 'agoraWebPlayCamera',
          args: [videoElementId],
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] playCamera error: $e');
      return false;
    }
  }

  /// Attach a remote user's video track to a DOM element by UID and element ID.
  static Future<bool> playRemoteVideo(String uid, String elementId) async {
    if (!kIsWeb) return false;

    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'playRemoteVideo',
          flatMethod: 'agoraWebPlayRemoteVideo',
          args: [uid, elementId],
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] playRemoteVideo error: $e');
      return false;
    }
  }

  /// Push a freshly-fetched Agora token to the JS bridge so it can renew.
  /// Call this from Dart after `generateAgoraToken` returns a new token.
  static Future<bool> renewToken(String newToken) async {
    if (!kIsWeb) return false;
    try {
      final promiseObj = _invokeBridgeMethod(
        objectMethod: 'renewToken',
        flatMethod: 'agoraWebRenewToken',
        args: [newToken],
      );
      final result = await _promiseToFuture(promiseObj);
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] renewToken error: $e');
      return false;
    }
  }

  /// Register a Dart callback that fires when the JS bridge receives
  /// token-privilege-will-expire or token-privilege-did-expire.
  /// The callback receives (channelName, uid) and should fetch a fresh token
  /// then call [renewToken].
  static void registerTokenWillExpireCallback(
      void Function(String channelName, String uid) callback) {
    if (!kIsWeb) return;
    try {
      final agoraWeb = js.context['agoraWeb'];
      if (agoraWeb is js.JsObject) {
        agoraWeb['onTokenWillExpire'] =
            js_util.allowInterop((String channelName, String uid) {
          callback(channelName, uid);
        });
        debugPrint('[BRIDGE] onTokenWillExpire callback registered');
      }
    } catch (e) {
      debugPrint('[BRIDGE] registerTokenWillExpireCallback error: $e');
    }
  }

  /// Get current Agora Web state (for debugging)
  static Map<String, dynamic> getState() {
    if (!kIsWeb) return {};

    try {
      final stateObj = _invokeBridgeMethod(
        objectMethod: 'getState',
        flatMethod: 'agoraWebGetState',
      );
      final dartified = js_util.dartify(stateObj);
      if (dartified is Map) {
        return Map<String, dynamic>.from(dartified);
      }

      // Fallback for bridge variants that return JS objects not directly dartified.
      if (stateObj is js.JsObject) {
        return {
          'initialized': stateObj['initialized'] == true,
          'sdkLoaded': stateObj['sdkLoaded'] == true,
          'inChannel': stateObj['inChannel'] == true,
          'currentChannel': stateObj['currentChannel'],
          'currentUid': stateObj['currentUid'],
          'hasAudio': stateObj['hasAudio'] == true,
          'hasVideo': stateObj['hasVideo'] == true,
          'audioMuted': stateObj['audioMuted'] == true,
          'videoMuted': stateObj['videoMuted'] == true,
          'lastError': stateObj['lastError'],
        };
      }

      return {
        'error': 'agoraWebGetState returned non-map state',
        'type': stateObj.runtimeType.toString(),
      };
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
      AppLogger.info('ðŸ” Agora debug logging enabled');
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
      if (js.context['agoraDebug'] != null) {
        js.context.callMethod('agoraDebug');
      } else if (js.context['agoraWebDebug'] != null) {
        js.context.callMethod('agoraWebDebug');
      }
    } catch (e) {
      debugPrint('[BRIDGE] Error printing debug info: $e');
    }
  }

  /// Register a Dart callback that fires when JS user-published fires.
  /// Sets window.agoraWeb.onRemoteUserPublished so the JS bridge can call it.
  static void registerRemotePublishedCallback(
      void Function(String uid, String mediaType) callback) {
    if (!kIsWeb) return;
    try {
      final agoraWeb = js.context['agoraWeb'];
      if (agoraWeb is js.JsObject) {
        agoraWeb['onRemoteUserPublished'] =
            js_util.allowInterop((String uid, String mediaType) {
          callback(uid, mediaType);
        });
        debugPrint('[BRIDGE] onRemoteUserPublished callback registered on window.agoraWeb');
      } else {
        debugPrint('[BRIDGE] registerRemotePublishedCallback: window.agoraWeb not available');
      }
    } catch (e) {
      debugPrint('[BRIDGE] registerRemotePublishedCallback error: $e');
    }
  }

  // ── Audio mixing ───────────────────────────────────────────────────────────

  /// Start playing an audio file into the channel mix.
  /// [url] must be an HTTP(S) URL reachable from the browser.
  /// [looping] — true to loop indefinitely.
  static Future<bool> startAudioMixing(String url, bool looping) async {
    if (!kIsWeb) return false;
    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'startAudioMixing',
          flatMethod:   'agoraWebStartAudioMixing',
          args: [url, looping],
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] startAudioMixing error: $e');
      return false;
    }
  }

  static Future<bool> stopAudioMixing() async {
    if (!kIsWeb) return false;
    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'stopAudioMixing',
          flatMethod:   'agoraWebStopAudioMixing',
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] stopAudioMixing error: $e');
      return false;
    }
  }

  static Future<bool> pauseAudioMixing() async {
    if (!kIsWeb) return false;
    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'pauseAudioMixing',
          flatMethod:   'agoraWebPauseAudioMixing',
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] pauseAudioMixing error: $e');
      return false;
    }
  }

  static Future<bool> resumeAudioMixing() async {
    if (!kIsWeb) return false;
    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'resumeAudioMixing',
          flatMethod:   'agoraWebResumeAudioMixing',
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] resumeAudioMixing error: $e');
      return false;
    }
  }

  static Future<bool> setAudioMixingVolume(int volume) async {
    if (!kIsWeb) return false;
    try {
      final result = await _promiseToFuture(
        _invokeBridgeMethod(
          objectMethod: 'setAudioMixingVolume',
          flatMethod:   'agoraWebSetAudioMixingVolume',
          args: [volume],
        ),
      );
      return _isSuccessResult(result);
    } catch (e) {
      debugPrint('[BRIDGE] setAudioMixingVolume error: $e');
      return false;
    }
  }

  // ========== INTERNAL UTILITIES ==========

  /// Convert JavaScript Promise to Dart Future
  static Future<dynamic> _promiseToFuture(
    dynamic jsPromise, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    try {
      if (jsPromise == null) {
        return Future.error(Exception('Promise is null'));
      }

      // Some bridge functions may return an immediate bool instead of a Promise.
      final immediate = jsPromise is bool || jsPromise is num || jsPromise is String;
      if (immediate) {
        return Future.value(jsPromise);
      }

      try {
        return js_util.promiseToFuture<dynamic>(jsPromise).timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Agora operation timeout after ${timeout.inSeconds}s',
          ),
        );
      } catch (promiseErr) {
        // `dart:js` can wrap Promise objects such that promiseToFuture fails on `.then`.
        // Resolve then-able JsObjects manually before considering immediate fallback.
        if (jsPromise is js.JsObject) {
          final thenFn = jsPromise['then'];
          if (thenFn is js.JsFunction) {
            final completer = Completer<dynamic>();

            thenFn.apply(
              [
                js_util.allowInterop((dynamic value) {
                  if (!completer.isCompleted) completer.complete(value);
                }),
                js_util.allowInterop((dynamic error) {
                  if (!completer.isCompleted) {
                    completer.completeError(Exception(error?.toString() ?? 'Promise rejected'));
                  }
                }),
              ],
              thisArg: jsPromise,
            );

            return completer.future.timeout(
              timeout,
              onTimeout: () => throw TimeoutException(
                'Agora operation timeout after ${timeout.inSeconds}s',
              ),
            );
          }
        }

        // If it is not a real Promise (no callable .then), treat it as an immediate value.
        final msg = promiseErr.toString();
        if (msg.contains('then') && msg.contains('non-function')) {
          debugPrint('[BRIDGE] Non-promise result detected, converting immediate value');
          try {
            return Future.value(js_util.dartify(jsPromise));
          } catch (_) {
            return Future.value(jsPromise?.toString());
          }
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('[BRIDGE] Error converting promise: $e');
      return Future.error(Exception('Failed to convert promise: $e'));
    }
  }

  /// Invoke Agora bridge method from `window.agoraWeb` first, with flat API fallback.
  static dynamic _invokeBridgeMethod({
    required String objectMethod,
    required String flatMethod,
    List<dynamic> args = const [],
  }) {
    // Prefer object-based API (window.agoraWeb.method) to keep bridge state scoped.
    final webObj = js.context['agoraWeb'];
    if (webObj is js.JsObject) {
      final objectFn = webObj[objectMethod];
      if (objectFn is js.JsFunction) {
        return objectFn.apply(args, thisArg: webObj);
      }

      if (objectFn != null) {
        debugPrint(
          '[BRIDGE] Non-callable object method: agoraWeb.$objectMethod '
          '(${objectFn.runtimeType})',
        );
      }
    }

    // Backward-compatible fallback for older flat global functions.
    final flatFn = js.context[flatMethod];
    if (flatFn is js.JsFunction) {
      return flatFn.apply(args);
    }

    if (flatFn != null) {
      debugPrint(
        '[BRIDGE] Non-callable flat method: $flatMethod '
        '(${flatFn.runtimeType})',
      );
    }

    throw Exception(
      'Agora bridge method unavailable or non-callable: '
      'object=agoraWeb.$objectMethod flat=$flatMethod',
    );
  }

  /// Promise resolutions can arrive as wrapped JS values; normalize to bool.
  static bool _isSuccessResult(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'ok' || normalized == 'success';
    }

    try {
      final dartified = js_util.dartify(value);
      if (dartified is bool) return dartified;
      if (dartified is num) return dartified != 0;
      if (dartified is String) {
        final normalized = dartified.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'ok' || normalized == 'success';
      }
    } catch (_) {
      // Ignore conversion failures and fall through.
    }

    return value?.toString() == 'true';
  }
}

// ========== COMPATIBILITY ALIAS ==========
// Keep old name for backward compatibility
typedef AgoraWebBridgeV2 = AgoraWebBridgeV3;
