// Agora Web Bridge v3 - Production Ready (WASM-safe)
// Interfaces with agora_web_v5_production.js
<<<<<<< HEAD
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
=======
// Replaces dart:js with dart:js_interop for WASM compatibility.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
>>>>>>> origin/develop
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../core/utils/app_logger.dart';

// ── External JS declarations ─────────────────────────────────────────────
// Each @JS annotation captures a nullable handle to a window property so
// we can check availability before calling.

@JS('agoraWebInit')
external JSAny? get _jsAgoraWebInit;

@JS('agoraWebJoinChannel')
external JSAny? get _jsAgoraWebJoinChannel;

@JS('agoraWebLeaveChannel')
external JSAny? get _jsAgoraWebLeaveChannel;

@JS('agoraWebSetMicMuted')
external JSAny? get _jsAgoraWebSetMicMuted;

@JS('agoraWebSetVideoMuted')
external JSAny? get _jsAgoraWebSetVideoMuted;

@JS('agoraWebGetState')
external JSAny? get _jsAgoraWebGetState;

@JS('agoraWebDebug')
external JSAny? get _jsAgoraWebDebug;

@JS('agoraWebRenewToken')
external JSAny? get _jsAgoraWebRenewToken;

// ── Helper: call a nullable JS function and await its Promise<bool> ───────

Future<bool> _callPromise(JSAny? fn, [
  JSAny? a1,
  JSAny? a2,
  JSAny? a3,
  JSAny? a4,
]) async {
  if (fn == null) throw Exception('JS function not found on window');
  final raw = (fn as JSFunction).callAsFunction(null, a1, a2, a3, a4);
  if (raw == null) return false;
  final result = await (raw as JSPromise<JSBoolean?>).toDart;
  return result?.toDart ?? false;
}

// ── Bridge class (public API unchanged) ───────────────────────────────────

class AgoraWebBridgeV3 {
  static bool get isAvailable {
    if (!kIsWeb) return false;
    try {
<<<<<<< HEAD
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
=======
      return _jsAgoraWebInit != null && _jsAgoraWebJoinChannel != null;
    } catch (_) {
>>>>>>> origin/develop
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
<<<<<<< HEAD
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
=======
      debugPrint('[BRIDGE] Initializing...');
      AppLogger.info('Initializing Agora Web SDK v5...');
      final ok = await _callPromise(_jsAgoraWebInit, appId.toJS);
      if (ok) AppLogger.info('Agora Web SDK v5 initialized');
      return ok;
>>>>>>> origin/develop
    } catch (e) {
      AppLogger.error('Agora init failed: $e');
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
<<<<<<< HEAD
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
=======
      debugPrint('[BRIDGE] Joining channel: $channelName, uid: $uid');
      AppLogger.info('Joining Agora channel: $channelName...');
      final ok = await _callPromise(
        _jsAgoraWebJoinChannel,
        appId.toJS,
        channelName.toJS,
        token.toJS,
        uid.toJS,
      );
      if (ok) AppLogger.info('Successfully joined channel: $channelName');
      return ok;
>>>>>>> origin/develop
    } catch (e) {
      AppLogger.error('Failed to join channel: $e');
      debugPrint('[BRIDGE] joinChannel error: $e');
      return false;
    }
  }

  /// Leave the current channel
  static Future<bool> leaveChannel() async {
    if (!kIsWeb) return false;
    try {
<<<<<<< HEAD
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
=======
      final ok = await _callPromise(_jsAgoraWebLeaveChannel);
      if (ok) AppLogger.info('Left channel');
      return ok;
>>>>>>> origin/develop
    } catch (e) {
      AppLogger.error('Failed to leave channel: $e');
      return false;
    }
  }

  /// Set microphone muted state
  static Future<bool> setMicMuted(bool muted) async {
    if (!kIsWeb) return false;
    try {
<<<<<<< HEAD
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
=======
      final ok = await _callPromise(_jsAgoraWebSetMicMuted, muted.toJS);
      if (ok) AppLogger.info('Microphone ${muted ? "muted" : "unmuted"}');
      return ok;
>>>>>>> origin/develop
    } catch (e) {
      AppLogger.error('Failed to set mic mute: $e');
      return false;
    }
  }

  /// Set video muted state
  static Future<bool> setVideoMuted(bool muted) async {
    if (!kIsWeb) return false;
    try {
<<<<<<< HEAD
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
=======
      final ok = await _callPromise(_jsAgoraWebSetVideoMuted, muted.toJS);
      if (ok) AppLogger.info('Video ${muted ? "disabled" : "enabled"}');
      return ok;
>>>>>>> origin/develop
    } catch (e) {
      AppLogger.error('Failed to set video mute: $e');
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
<<<<<<< HEAD
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
=======
      final fn = _jsAgoraWebGetState;
      if (fn == null) return {'error': 'agoraWebGetState not found'};
      (fn as JSFunction).callAsFunction(null);
      return {'available': true};
>>>>>>> origin/develop
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Enable debug mode
  static void enableDebugLogging() {
    if (!kIsWeb) return;
    try {
      (_jsAgoraWebDebug as JSFunction?)?.callAsFunction(null);
    } catch (_) {}
  }

  /// Print debug info to console
  static void printDebugInfo() {
    if (!kIsWeb) return;
    try {
<<<<<<< HEAD
      if (js.context['agoraDebug'] != null) {
        js.context.callMethod('agoraDebug');
      } else if (js.context['agoraWebDebug'] != null) {
        js.context.callMethod('agoraWebDebug');
      }
=======
      (_jsAgoraWebDebug as JSFunction?)?.callAsFunction(null);
>>>>>>> origin/develop
    } catch (e) {
      debugPrint('[BRIDGE] Error: $e');
    }
  }

<<<<<<< HEAD
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
=======
  /// Renew the Agora token for the current session (synchronous JS call).
  /// Call this when the privilege expiry callback fires or on a ~23h timer.
  static bool renewToken(String newToken) {
    if (!kIsWeb) return false;
    try {
      final fn = _jsAgoraWebRenewToken;
      if (fn == null) return false;
      final result = (fn as JSFunction).callAsFunction(null, newToken.toJS);
      if (result == null) return false;
      final dartValue = (result as JSBoolean).toDart;
      return dartValue;
>>>>>>> origin/develop
    } catch (e) {
      debugPrint('[BRIDGE] renewToken error: $e');
      return false;
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

// ── Compatibility alias ───────────────────────────────────────────────────
typedef AgoraWebBridgeV2 = AgoraWebBridgeV3;
