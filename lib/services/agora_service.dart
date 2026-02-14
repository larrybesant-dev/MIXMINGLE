// Agora Service - Production-Ready with Device Switching
// Uses dart:js_interop for reliable JS interop
// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// External JS function declarations using dart:js_interop
/// Note: JS async functions return Promises that resolve to raw JS values
@JS('agoraWebBridge.init')
external JSPromise _jsInit(JSString appId);

@JS('agoraWebBridge.joinChannel')
external JSPromise _jsJoinChannel(JSString token, JSString channel, JSString uid);

@JS('agoraWebBridge.createCameraTrack')
external JSPromise _jsCreateCameraTrack([JSString? deviceId]);

@JS('agoraWebBridge.createMicrophoneTrack')
external JSPromise _jsCreateMicrophoneTrack([JSString? deviceId]);

@JS('agoraWebBridge.playCamera')
external void _jsPlayCamera(JSString videoElementId);

@JS('agoraWebBridge.leaveChannel')
external JSPromise _jsLeaveChannel();

@JS('agoraWebBridge.switchCamera')
external JSPromise _jsSwitchCamera(JSString deviceId);

@JS('agoraWebBridge.switchMic')
external JSPromise _jsSwitchMic(JSString deviceId);

@JS('agoraWebBridge.getDevices')
external JSPromise _jsGetDevices();

@JS('agoraWebBridge.setMicMuted')
external JSPromise _jsSetMicMuted(JSBoolean muted);

@JS('agoraWebBridge.setVideoMuted')
external JSPromise _jsSetVideoMuted(JSBoolean muted);

@JS('agoraWebBridge.getState')
external JSAny? _jsGetState();

@JS('agoraBridgeReady')
external JSAny? get _jsBridgeReady;

/// Helper to safely convert JS value to bool
bool _jsToBool(JSAny? value) {
  if (value == null) return false;
  try {
    // Use dartify to convert JS value to Dart
    final dartValue = value.dartify();
    return dartValue == true;
  } catch (e) {
    return false;
  }
}

/// Helper to safely get string property from JS object
String? _jsGetString(JSObject obj, String key) {
  try {
    final value = obj[key];
    if (value == null) return null;
    final dartValue = value.dartify();
    return dartValue?.toString();
  } catch (e) {
    return null;
  }
}

/// Helper to safely get bool property from JS object
bool _jsGetBool(JSObject obj, String key, {bool defaultValue = false}) {
  try {
    final value = obj[key];
    if (value == null) return defaultValue;
    final dartValue = value.dartify();
    return dartValue == true;
  } catch (e) {
    return defaultValue;
  }
}

/// Exception thrown when Agora operation fails
class AgoraException implements Exception {
  final String message;
  final Object? originalError;

  AgoraException(this.message, [this.originalError]);

  @override
  String toString() => 'AgoraException: $message';
}

/// Clean, production-ready Agora Service
/// Uses dart:js_interop for reliable async handling
class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  /// For legacy compatibility - creates instance with appId
  factory AgoraService.withAppId({required String appId}) {
    final instance = AgoraService._instance;
    instance._pendingAppId = appId;
    return instance;
  }

  String? _pendingAppId;
  bool _initialized = false;
  String? _appId;
  bool _inChannel = false;
  String? _currentChannelId;

  /// Check if bridge is ready
  bool get isBridgeReady {
    if (!kIsWeb) return false;
    try {
      return _jsToBool(_jsBridgeReady);
    } catch (e) {
      return false;
    }
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Whether user is currently in channel
  bool get isInChannel => _inChannel;

  /// Current channel ID
  String? get currentChannelId => _currentChannelId;

  /// Initialize Agora with App ID
  Future<bool> init(String appId) async {
    if (!kIsWeb) return false;
    if (_initialized && _appId == appId) return true;

    try {
      debugPrint('[AgoraService] Initializing with appId: ${appId.substring(0, 8)}...');

      // Call JS init and await the promise
      final result = await _jsInit(appId.toJS).toDart;
      final success = _jsToBool(result);

      debugPrint('[AgoraService] Init result: $success (raw: $result)');

      if (success) {
        _initialized = true;
        _appId = appId;
        debugPrint('[AgoraService] ✅ Initialized');
        return true;
      }
      debugPrint('[AgoraService] ⚠️ Init returned false');
      return false;
    } catch (e) {
      debugPrint('[AgoraService] ❌ Init failed: $e');
      return false;
    }
  }

  /// Legacy initialize() method for backward compatibility
  Future<void> initialize() async {
    final appId = _pendingAppId ?? _appId;
    if (appId == null || appId.isEmpty) {
      throw AgoraException('Agora App ID not provided');
    }
    final ok = await init(appId);
    if (!ok) {
      throw AgoraException('Failed to initialize Agora SDK');
    }
  }

  /// Join a channel
  Future<bool> joinChannel({
    String? token,
    required String channelId,
    required String uid,
  }) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[AgoraService] Joining channel: $channelId, uid: $uid');
      final result = await _jsJoinChannel(
        (token ?? '').toJS,
        channelId.toJS,
        uid.toJS,
      ).toDart;

      final success = _jsToBool(result);
      debugPrint('[AgoraService] Join result: $success');

      if (success) {
        _inChannel = true;
        _currentChannelId = channelId;
        debugPrint('[AgoraService] ✅ Joined channel');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AgoraService] ❌ Join failed: $e');
      return false;
    }
  }

  /// Start camera and play in element
  Future<bool> startCamera(String videoElementId, [String? deviceId]) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[AgoraService] Starting camera...');
      final result = await _jsCreateCameraTrack(deviceId?.toJS).toDart;
      final success = _jsToBool(result);

      if (success) {
        _jsPlayCamera(videoElementId.toJS);
        debugPrint('[AgoraService] ✅ Camera started');
        return true;
      }
      debugPrint('[AgoraService] ⚠️ Camera track creation failed');
      return false;
    } catch (e) {
      debugPrint('[AgoraService] ❌ Camera failed: $e');
      return false;
    }
  }

  /// Start microphone
  Future<bool> startMic([String? deviceId]) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[AgoraService] Starting mic...');
      final result = await _jsCreateMicrophoneTrack(deviceId?.toJS).toDart;
      final success = _jsToBool(result);

      if (success) {
        debugPrint('[AgoraService] ✅ Mic started');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AgoraService] ❌ Mic failed: $e');
      return false;
    }
  }

  /// Leave current channel gracefully
  Future<void> leaveChannel() async {
    if (!kIsWeb) return;
    if (!_inChannel) return;

    try {
      debugPrint('[AgoraService] Leaving channel...');
      await _jsLeaveChannel().toDart;
      _inChannel = false;
      _currentChannelId = null;
      debugPrint('[AgoraService] ✅ Left channel');
    } catch (e) {
      debugPrint('[AgoraService] ❌ Leave failed: $e');
      // Reset state anyway
      _inChannel = false;
      _currentChannelId = null;
    }
  }

  /// Switch camera device
  Future<bool> switchCamera(String deviceId) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[AgoraService] Switching camera to: $deviceId');
      final result = await _jsSwitchCamera(deviceId.toJS).toDart;
      return _jsToBool(result);
    } catch (e) {
      debugPrint('[AgoraService] ❌ Switch camera failed: $e');
      return false;
    }
  }

  /// Switch microphone device
  Future<bool> switchMic(String deviceId) async {
    if (!kIsWeb) return false;

    try {
      debugPrint('[AgoraService] Switching mic to: $deviceId');
      final result = await _jsSwitchMic(deviceId.toJS).toDart;
      return _jsToBool(result);
    } catch (e) {
      debugPrint('[AgoraService] ❌ Switch mic failed: $e');
      return false;
    }
  }

  /// Mute/unmute microphone
  Future<void> setMicrophoneMuted(bool muted) async {
    if (!kIsWeb) return;

    try {
      await _jsSetMicMuted(muted.toJS).toDart;
      debugPrint('[AgoraService] Microphone ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('[AgoraService] Mic control failed: $e');
      throw AgoraException('Failed to control microphone', e);
    }
  }

  /// Mute/unmute camera video
  Future<void> setVideoCameraMuted(bool muted) async {
    if (!kIsWeb) return;

    try {
      await _jsSetVideoMuted(muted.toJS).toDart;
      debugPrint('[AgoraService] Video ${muted ? 'disabled' : 'enabled'}');
    } catch (e) {
      debugPrint('[AgoraService] Video control failed: $e');
      throw AgoraException('Failed to control video', e);
    }
  }

  /// Get available devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    if (!kIsWeb) return [];

    try {
      final jsResult = await _jsGetDevices().toDart;
      if (jsResult == null) return [];

      final List<Map<String, dynamic>> devices = [];

      // Try to convert using dartify first
      try {
        final dartified = jsResult.dartify();
        if (dartified is List) {
          for (final item in dartified) {
            if (item is Map) {
              devices.add({
                'deviceId': item['deviceId']?.toString() ?? '',
                'label': item['label']?.toString() ?? 'Unknown Device',
                'kind': item['kind']?.toString() ?? '',
              });
            }
          }
          debugPrint('[AgoraService] Got ${devices.length} devices (dartify)');
          return devices;
        }
      } catch (e) {
        debugPrint('[AgoraService] dartify failed, using manual access: $e');
      }

      // Fallback: manual JS object access
      final jsObj = jsResult as JSObject;
      final lengthValue = jsObj['length'];
      int length = 0;

      if (lengthValue != null) {
        final dartLength = lengthValue.dartify();
        if (dartLength is int) {
          length = dartLength;
        } else if (dartLength is num) {
          length = dartLength.toInt();
        } else {
          length = int.tryParse(dartLength?.toString() ?? '0') ?? 0;
        }
      }

      for (int i = 0; i < length; i++) {
        final device = jsObj[i.toString()];
        if (device != null) {
          final deviceObj = device as JSObject;
          devices.add({
            'deviceId': _jsGetString(deviceObj, 'deviceId') ?? '',
            'label': _jsGetString(deviceObj, 'label') ?? 'Unknown Device',
            'kind': _jsGetString(deviceObj, 'kind') ?? '',
          });
        }
      }

      debugPrint('[AgoraService] Got ${devices.length} devices (manual)');
      return devices;
    } catch (e) {
      debugPrint('[AgoraService] ❌ getDevices failed: $e');
      return [];
    }
  }

  /// Get current state
  Future<Map<String, dynamic>> getState() async {
    if (!kIsWeb) return {};

    try {
      final jsState = _jsGetState();
      if (jsState == null) return {'bridgeReady': isBridgeReady};

      // Try dartify first for simpler conversion
      try {
        final dartified = jsState.dartify();
        if (dartified is Map) {
          return {
            'bridgeReady': isBridgeReady,
            'initialized': dartified['initialized'] == true,
            'sdkLoaded': dartified['sdkLoaded'] == true,
            'inChannel': dartified['inChannel'] == true,
            'currentChannel': dartified['currentChannel']?.toString(),
            'currentUid': dartified['currentUid']?.toString(),
            'hasAudio': dartified['hasAudio'] == true,
            'hasVideo': dartified['hasVideo'] == true,
            'audioMuted': dartified['audioMuted'] ?? true,
            'videoMuted': dartified['videoMuted'] ?? true,
            'currentVideoDeviceId': dartified['currentVideoDeviceId']?.toString(),
            'currentMicDeviceId': dartified['currentMicDeviceId']?.toString(),
          };
        }
      } catch (e) {
        debugPrint('[AgoraService] dartify failed, using manual access: $e');
      }

      // Fallback: manual JS object access
      final jsObj = jsState as JSObject;
      return {
        'bridgeReady': isBridgeReady,
        'initialized': _jsGetBool(jsObj, 'initialized'),
        'sdkLoaded': _jsGetBool(jsObj, 'sdkLoaded'),
        'inChannel': _jsGetBool(jsObj, 'inChannel'),
        'currentChannel': _jsGetString(jsObj, 'currentChannel'),
        'currentUid': _jsGetString(jsObj, 'currentUid'),
        'hasAudio': _jsGetBool(jsObj, 'hasAudio'),
        'hasVideo': _jsGetBool(jsObj, 'hasVideo'),
        'audioMuted': _jsGetBool(jsObj, 'audioMuted', defaultValue: true),
        'videoMuted': _jsGetBool(jsObj, 'videoMuted', defaultValue: true),
        'currentVideoDeviceId': _jsGetString(jsObj, 'currentVideoDeviceId'),
        'currentMicDeviceId': _jsGetString(jsObj, 'currentMicDeviceId'),
      };
    } catch (e) {
      debugPrint('[AgoraService] getState error: $e');
      return {'bridgeReady': isBridgeReady, 'error': e.toString()};
    }
  }

  /// Start camera with retry
  Future<bool> startCameraWithRetry(String videoElementId, {String? deviceId, int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      final success = await startCamera(videoElementId, deviceId);
      if (success) return true;
      if (i < retries - 1) {
        debugPrint('[AgoraService] Camera retry ${i + 1}/$retries');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  /// Start mic with retry
  Future<bool> startMicWithRetry({String? deviceId, int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      final success = await startMic(deviceId);
      if (success) return true;
      if (i < retries - 1) {
        debugPrint('[AgoraService] Mic retry ${i + 1}/$retries');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  /// Full join flow: init -> join -> camera -> mic
  Future<bool> joinRoomFull({
    required String appId,
    required String channel,
    String? token,
    required String uid,
    required String videoElementId,
    bool enableCamera = true,
    bool enableMic = true,
    String? cameraDeviceId,
    String? micDeviceId,
  }) async {
    if (!kIsWeb) return false;

    try {
      // Step 1: Init
      final initOk = await init(appId);
      if (!initOk) {
        debugPrint('[AgoraService] ❌ Full join failed at init');
        return false;
      }

      // Step 2: Join channel
      final joinOk = await joinChannel(channelId: channel, token: token, uid: uid);
      if (!joinOk) {
        debugPrint('[AgoraService] ❌ Full join failed at join');
        return false;
      }

      // Step 3: Start camera (with retry)
      if (enableCamera) {
        final cameraOk = await startCameraWithRetry(videoElementId, deviceId: cameraDeviceId);
        if (!cameraOk) {
          debugPrint('[AgoraService] ⚠️ Camera failed but continuing...');
        }
      }

      // Step 4: Start mic (with retry)
      if (enableMic) {
        final micOk = await startMicWithRetry(deviceId: micDeviceId);
        if (!micOk) {
          debugPrint('[AgoraService] ⚠️ Mic failed but continuing...');
        }
      }

      debugPrint('[AgoraService] ✅ Full room join complete');
      return true;
    } catch (e) {
      debugPrint('[AgoraService] ❌ Full room join failed: $e');
      return false;
    }
  }

  /// Cleanup: leave channel and reset state
  Future<void> cleanup() async {
    try {
      if (_inChannel) {
        await leaveChannel();
      }
      _initialized = false;
      _currentChannelId = null;
      debugPrint('[AgoraService] Cleaned up');
    } catch (e) {
      debugPrint('[AgoraService] Cleanup error: $e');
    }
  }
}


