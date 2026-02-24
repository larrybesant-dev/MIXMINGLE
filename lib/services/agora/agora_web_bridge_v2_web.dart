// Agora Web bridge implementation
// Calls the JavaScript bridge defined in web/index.html
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../core/utils/app_logger.dart';

class AgoraWebBridgeV2 {
  static bool get isAvailable {
    if (!kIsWeb) return false;
    try {
      final bridge = js.context['agoraWeb'];
      return bridge != null;
    } catch (e) {
      debugPrint('[BRIDGE] Error checking isAvailable: $e');
      return false;
    }
  }

  static Future<bool> init(String appId) async {
    if (!kIsWeb) {
      debugPrint('[BRIDGE] Not on web, returning false');
      return false;
    }

    try {
      debugPrint('[BRIDGE] Step 1: Accessing js.context');
      final bridge = js.context['agoraWeb'];
      debugPrint('[BRIDGE] Step 2: Bridge object = $bridge');

      if (bridge == null) {
        AppLogger.error('âŒ Bridge agoraWeb not available - is null');
        debugPrint('[BRIDGE] Step 3: Bridge is NULL - window.agoraWeb not defined in HTML');
        return false;
      }

      debugPrint('[BRIDGE] Step 4: Bridge exists, accessing init function');
      final initFn = bridge['init'];
      debugPrint('[BRIDGE] Step 5: init function = $initFn');

      if (initFn == null) {
        AppLogger.error('âŒ Bridge init function not found');
        debugPrint('[BRIDGE] Step 6: initFn is NULL');
        return false;
      }

      debugPrint('[BRIDGE] Step 7: Calling JS init($appId)');
      final promiseObj = initFn.apply([appId]);
      debugPrint('[BRIDGE] Step 8: JS init() returned Promise: $promiseObj');

      // Convert Promise to Dart Future
      debugPrint('[BRIDGE] Step 9: Converting Promise to Future');
      final result = await _promiseToFuture(promiseObj);
      debugPrint('[BRIDGE] Step 10: Promise resolved with result: $result');

      return result == true;
    } catch (e) {
      AppLogger.error('âŒ init error: $e');
      debugPrint('[BRIDGE] ERROR: $e');
      return false;
    }
  }

  static Future<bool> joinChannel({
    required String channelName,
    required String token,
    required String uid,
  }) async {
    if (!kIsWeb) return false;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) {
        AppLogger.error('âŒ Bridge agoraWeb not available');
        return false;
      }

      debugPrint('[BRIDGE] Calling JS joinChannel($channelName, uid=$uid)');

      // Get the joinChannel function and call it (new API: token, channelName, uid)
      final joinFn = bridge['joinChannel'];
      final promiseObj = joinFn.apply([token, channelName, uid]);

      // Convert Promise to Dart Future
      final result = await _promiseToFuture(promiseObj);

      debugPrint('[BRIDGE] joinChannel result: $result');
      return result == true;
    } catch (e) {
      AppLogger.error('âŒ joinChannel error: $e');
      debugPrint('[BRIDGE] Dart joinChannel error: $e');
      return false;
    }
  }

  static Future<bool> leaveChannel() async {
    if (!kIsWeb) return false;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return false;

      debugPrint('[BRIDGE] Calling JS leaveChannel()');

      final leaveFn = bridge['leaveChannel'];
      final promiseObj = leaveFn.apply([]);

      final result = await _promiseToFuture(promiseObj);
      return result == true;
    } catch (e) {
      AppLogger.error('âŒ leaveChannel error: $e');
      return false;
    }
  }

  static Future<bool> enableLocalTracks({required bool enableAudio, required bool enableVideo}) async {
    if (!kIsWeb) return false;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return false;

      debugPrint('[BRIDGE] Calling JS enableLocalTracks(audio=$enableAudio, video=$enableVideo)');

      final enableTracksFn = bridge['enableLocalTracks'];
      final promiseObj = enableTracksFn.apply([enableAudio, enableVideo]);

      final result = await _promiseToFuture(promiseObj);
      debugPrint('[BRIDGE] enableLocalTracks result: $result');
      return result == true;
    } catch (e) {
      AppLogger.error('âŒ enableLocalTracks error: $e');
      return false;
    }
  }

  static Future<bool> setAudioMuted(bool muted) async {
    if (!kIsWeb) return false;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return false;

      debugPrint('[BRIDGE] Calling JS setAudioMuted($muted)');

      final setAudioFn = bridge['setAudioMuted'];
      final promiseObj = setAudioFn.apply([muted]);

      final result = await _promiseToFuture(promiseObj);
      return result == true;
    } catch (e) {
      AppLogger.error('âŒ setAudioMuted error: $e');
      return false;
    }
  }

  static Future<bool> setVideoMuted(bool muted) async {
    if (!kIsWeb) return false;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return false;

      debugPrint('[BRIDGE] Calling JS setVideoMuted($muted)');

      final setVideoFn = bridge['setVideoMuted'];
      final promiseObj = setVideoFn.apply([muted]);

      final result = await _promiseToFuture(promiseObj);
      return result == true;
    } catch (e) {
      AppLogger.error('âŒ setVideoMuted error: $e');
      return false;
    }
  }

  /// Mute/unmute remote user's audio (Sprint 2: Host controls)
  static Future<bool> muteRemoteAudio(int remoteUid, bool muted) async {
    if (!kIsWeb) return false;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return false;

      debugPrint('[BRIDGE] Calling JS muteRemoteAudio(uid=$remoteUid, muted=$muted)');

      final muteRemoteFn = bridge['muteRemoteAudio'];
      if (muteRemoteFn == null) {
        debugPrint('[BRIDGE] muteRemoteAudio not available on web bridge');
        return false;
      }

      final promiseObj = muteRemoteFn.apply([remoteUid, muted]);
      final result = await _promiseToFuture(promiseObj);
      return result == true;
    } catch (e) {
      AppLogger.error('âŒ muteRemoteAudio error: $e');
      return false;
    }
  }

  // Deprecated: Use setAudioMuted instead
  static Future<bool> setMicMuted(bool muted) => setAudioMuted(muted);

  // Get current client state for diagnostics
  static Map<String, bool>? getClientState() {
    if (!kIsWeb) return null;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return null;

      final getStateFn = bridge['getClientState'];
      final state = getStateFn.apply([]);

      return {
        'hasClient': state['hasClient'] == true,
        'hasAudioTrack': state['hasAudioTrack'] == true,
        'hasVideoTrack': state['hasVideoTrack'] == true,
      };
    } catch (e) {
      debugPrint('[BRIDGE] Error getting client state: $e');
      return null;
    }
  }

  /// Set callback for remote user published event
  /// Called when a remote user publishes video or audio
  static void setOnRemoteUserPublished(void Function(Map<String, dynamic> event)? callback) {
    if (!kIsWeb) return;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return;

      if (callback == null) {
        bridge['onRemoteUserPublished'] = null;
        debugPrint('[BRIDGE] onRemoteUserPublished callback cleared');
        return;
      }

      // Create a JS-compatible wrapper
      bridge['onRemoteUserPublished'] = (dynamic event) {
        try {
          final eventMap = <String, dynamic>{};
          if (event != null) {
            eventMap['uid'] = event['uid'];
            eventMap['mediaType'] = event['mediaType'];
            eventMap['hasVideo'] = event['hasVideo'] ?? false;
            eventMap['hasAudio'] = event['hasAudio'] ?? false;
          }
          callback(eventMap);
        } catch (e) {
          debugPrint('[BRIDGE] Error in onRemoteUserPublished: $e');
        }
      };

      debugPrint('[BRIDGE] onRemoteUserPublished callback registered');
    } catch (e) {
      debugPrint('[BRIDGE] Error setting onRemoteUserPublished: $e');
    }
  }

  /// Set callback for remote user unpublished event
  /// Called when a remote user unpublishes video or audio
  static void setOnRemoteUserUnpublished(void Function(Map<String, dynamic> event)? callback) {
    if (!kIsWeb) return;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return;

      if (callback == null) {
        bridge['onRemoteUserUnpublished'] = null;
        debugPrint('[BRIDGE] onRemoteUserUnpublished callback cleared');
        return;
      }

      // Create a JS-compatible wrapper
      bridge['onRemoteUserUnpublished'] = (dynamic event) {
        try {
          final eventMap = <String, dynamic>{};
          if (event != null) {
            eventMap['uid'] = event['uid'];
            eventMap['mediaType'] = event['mediaType'];
          }
          callback(eventMap);
        } catch (e) {
          debugPrint('[BRIDGE] Error in onRemoteUserUnpublished: $e');
        }
      };

      debugPrint('[BRIDGE] onRemoteUserUnpublished callback registered');
    } catch (e) {
      debugPrint('[BRIDGE] Error setting onRemoteUserUnpublished: $e');
    }
  }

  /// Set callback for remote user left event
  /// Called when a remote user completely leaves the channel
  static void setOnRemoteUserLeft(void Function(Map<String, dynamic> event)? callback) {
    if (!kIsWeb) return;

    try {
      final bridge = js.context['agoraWeb'];
      if (bridge == null) return;

      if (callback == null) {
        bridge['onRemoteUserLeft'] = null;
        debugPrint('[BRIDGE] onRemoteUserLeft callback cleared');
        return;
      }

      // Create a JS-compatible wrapper
      bridge['onRemoteUserLeft'] = (dynamic event) {
        try {
          final eventMap = <String, dynamic>{};
          if (event != null) {
            eventMap['uid'] = event['uid'];
          }
          callback(eventMap);
        } catch (e) {
          debugPrint('[BRIDGE] Error in onRemoteUserLeft: $e');
        }
      };

      debugPrint('[BRIDGE] onRemoteUserLeft callback registered');
    } catch (e) {
      debugPrint('[BRIDGE] Error setting onRemoteUserLeft: $e');
    }
  }

  // Helper: Convert JavaScript Promise to Dart Future
  // This is needed because JS functions return Promises which aren't natively compatible with Dart's async/await
  static Future<dynamic> _promiseToFuture(dynamic jsPromise) {
    final completer = Completer<dynamic>();

    // Create callbacks for Promise resolution
    // dart:js handles the Dart->JS function conversion automatically
    void onSuccess(dynamic result) {
      if (!completer.isCompleted) {
        debugPrint('[BRIDGE] Promise resolved with: $result');
        completer.complete(result);
      }
    }

    void onError(dynamic error) {
      if (!completer.isCompleted) {
        debugPrint('[BRIDGE] Promise rejected with: $error');
        completer.completeError(error ?? 'Unknown error');
      }
    }

    // Chain the Promise callbacks using callMethod to ensure proper JS interop
    try {
      debugPrint('[BRIDGE] Calling promise.then() with callbacks...');
      // Use callMethod to invoke the .then() method on the Promise object
      jsPromise.callMethod('then', [onSuccess, onError]);
      debugPrint('[BRIDGE] Callbacks registered successfully');
    } catch (e) {
      debugPrint('[BRIDGE] Error registering callbacks: $e');
      completer.completeError(e);
    }

    return completer.future;
  }
}
