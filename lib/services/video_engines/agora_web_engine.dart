/// Agora Web Bridge - implements IVideoEngine for Web platform
///
/// This is the single source of truth for Web video functionality.
/// All calls to JS are wrapped here and Stream-ified for Riverpod compatibility.
library;

// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/models/video_engine_models.dart';
import '../../core/interfaces/video_engine_interface.dart';
import '../../core/utils/app_logger.dart';

class AgoraWebEngine implements IVideoEngine {
  bool _initialized = false;
  bool _connected = false;

  final _remoteUsersController = StreamController<List<RemoteUser>>.broadcast();
  final _connectionStateController = StreamController<ChannelState>.broadcast();

  final Map<int, RemoteUser> _remoteUsersMap = {};
  LocalMediaState? _localMediaState;

  AgoraWebEngine() {
    debugPrint('[AGORA_WEB] Engine instance created');
  }

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isConnected => _connected;

  @override
  List<RemoteUser> get remoteUsers => _remoteUsersMap.values.toList();

  @override
  Stream<List<RemoteUser>> get remoteUsersStream => _remoteUsersController.stream;

  @override
  Stream<ChannelState> get connectionStateStream => _connectionStateController.stream;

  @override
  LocalMediaState? get localMediaState => _localMediaState;

  @override
  Future<void> initialize(String appId) async {
    if (_initialized) {
      debugPrint('[AGORA_WEB] Already initialized');
      return;
    }

    try {
      debugPrint('[AGORA_WEB] Initializing with appId: $appId');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException(
          'JavaScript bridge not available',
          originalError: 'window.agoraWeb is null',
        );
      }

      final initFn = bridge['init'] as JSFunction?;
      if (initFn == null) {
        throw VideoEngineException(
          'init function not found on bridge',
          originalError: 'bridge.init is null',
        );
      }

      final promiseObj = initFn.callAsFunction(null, appId.toJS) as JSPromise;
      final result = (await promiseObj.toDart as JSBoolean?)?.toDart ?? false;

      if (result != true) {
        throw VideoEngineException('init returned false', originalError: result);
      }

      _initialized = true;
      _setupEventCallbacks();
      debugPrint('[AGORA_WEB] âœ… Initialization complete');
    } catch (e) {
      AppLogger.error('Initialization failed: $e');
      throw VideoEngineException('Failed to initialize Agora Web Engine', originalError: e);
    }
  }

  @override
  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required String? token,
  }) async {
    if (!_initialized) {
      throw VideoEngineException('Engine not initialized. Call initialize() first.');
    }

    try {
      debugPrint('[AGORA_WEB] Joining channel: $channelName, uid: $uid');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException('Bridge became unavailable');
      }

      final joinFn = bridge['joinChannel'] as JSFunction?;
      if (joinFn == null) {
        throw VideoEngineException('joinChannel function not found');
      }

      final promiseObj = joinFn.callAsFunction(null, (token ?? '').toJS, channelName.toJS, uid.toString().toJS) as JSPromise;
      final result = (await promiseObj.toDart as JSBoolean?)?.toDart ?? false;

      if (result != true) {
        throw VideoEngineException('joinChannel returned false', originalError: result);
      }

      _connected = true;
      _connectionStateController.add(ChannelState.connected);
      _localMediaState = const LocalMediaState(
        audioEnabled: true,
        videoEnabled: true,
        cameraOn: true,
        micOn: true,
      );

      debugPrint('[AGORA_WEB] âœ… Joined channel');
    } catch (e) {
      AppLogger.error('Join channel failed: $e');
      _connectionStateController.add(ChannelState.disconnected);
      throw VideoEngineException('Failed to join channel', originalError: e);
    }
  }

  @override
  Future<void> leaveChannel() async {
    if (!_initialized || !_connected) {
      debugPrint('[AGORA_WEB] Not connected, skipping leave');
      return;
    }

    try {
      debugPrint('[AGORA_WEB] Leaving channel');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge != null) {
        final leaveFn = bridge['leaveChannel'] as JSFunction?;
        if (leaveFn != null) {
          final promiseObj = leaveFn.callAsFunction(null) as JSPromise;
          await promiseObj.toDart;
        }
      }

      _connected = false;
      _remoteUsersMap.clear();
      _remoteUsersController.add([]);
      _localMediaState = null;
      _connectionStateController.add(ChannelState.disconnected);

      debugPrint('[AGORA_WEB] âœ… Left channel');
    } catch (e) {
      AppLogger.error('Leave channel failed: $e');
      throw VideoEngineException('Failed to leave channel', originalError: e);
    }
  }

  @override
  Future<void> enableLocalTracks({
    required bool enableAudio,
    required bool enableVideo,
  }) async {
    if (!_initialized) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_WEB] Enabling local tracks: audio=$enableAudio, video=$enableVideo');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException('Bridge unavailable');
      }

      final enableFn = bridge['enableLocalTracks'] as JSFunction?;
      if (enableFn == null) {
        throw VideoEngineException('enableLocalTracks function not found');
      }

      final promiseObj = enableFn.callAsFunction(null, enableAudio.toJS, enableVideo.toJS) as JSPromise;
      await promiseObj.toDart;

      _localMediaState = LocalMediaState(
        audioEnabled: enableAudio,
        videoEnabled: enableVideo,
        cameraOn: enableVideo,
        micOn: enableAudio,
      );

      debugPrint('[AGORA_WEB] âœ… Local tracks updated');
    } catch (e) {
      AppLogger.error('Enable local tracks failed: $e');
      throw VideoEngineException('Failed to enable local tracks', originalError: e);
    }
  }

  @override
  Future<void> setAudioMuted(bool muted) async {
    if (!_initialized) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_WEB] Setting audio muted: $muted');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException('Bridge unavailable');
      }

      final setAudioFn = bridge['setAudioMuted'] as JSFunction?;
      if (setAudioFn == null) {
        throw VideoEngineException('setAudioMuted function not found');
      }

      final promiseObj = setAudioFn.callAsFunction(null, muted.toJS) as JSPromise;
      await promiseObj.toDart;

      if (_localMediaState != null) {
        _localMediaState = LocalMediaState(
          audioEnabled: !muted,
          videoEnabled: _localMediaState!.videoEnabled,
          cameraOn: _localMediaState!.cameraOn,
          micOn: !muted,
        );
      }

      debugPrint('[AGORA_WEB] âœ… Audio mute state: $muted');
    } catch (e) {
      AppLogger.error('Set audio muted failed: $e');
      throw VideoEngineException('Failed to set audio muted', originalError: e);
    }
  }

  @override
  Future<void> setVideoMuted(bool muted) async {
    if (!_initialized) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_WEB] Setting video muted: $muted');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException('Bridge unavailable');
      }

      final setVideoFn = bridge['setVideoMuted'] as JSFunction?;
      if (setVideoFn == null) {
        throw VideoEngineException('setVideoMuted function not found');
      }

      final promiseObj = setVideoFn.callAsFunction(null, muted.toJS) as JSPromise;
      await promiseObj.toDart;

      if (_localMediaState != null) {
        _localMediaState = LocalMediaState(
          audioEnabled: _localMediaState!.audioEnabled,
          videoEnabled: !muted,
          cameraOn: !muted,
          micOn: _localMediaState!.micOn,
        );
      }

      debugPrint('[AGORA_WEB] âœ… Video mute state: $muted');
    } catch (e) {
      AppLogger.error('Set video muted failed: $e');
      throw VideoEngineException('Failed to set video muted', originalError: e);
    }
  }

  @override
  Future<void> muteRemoteAudio(int remoteUid, bool muted) async {
    if (!_initialized) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_WEB] Muting remote audio: uid=$remoteUid, muted=$muted');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException('Bridge unavailable');
      }

      final muteRemoteFn = bridge['muteRemoteAudio'] as JSFunction?;
      if (muteRemoteFn == null) {
        throw VideoEngineException('muteRemoteAudio not supported on web');
      }

      final promiseObj = muteRemoteFn.callAsFunction(null, remoteUid.toJS, muted.toJS) as JSPromise;
      await promiseObj.toDart;

      // Update local state
      if (_remoteUsersMap.containsKey(remoteUid)) {
        _remoteUsersMap[remoteUid] = RemoteUser(
          uid: remoteUid,
          audioEnabled: !muted,
          videoEnabled: _remoteUsersMap[remoteUid]!.videoEnabled,
        );
        _remoteUsersController.add(remoteUsers);
      }

      debugPrint('[AGORA_WEB] âœ… Remote audio muted');
    } catch (e) {
      AppLogger.error('Mute remote audio failed: $e');
      throw VideoEngineException('Failed to mute remote audio', originalError: e);
    }
  }

  @override
  Future<void> muteRemoteVideo(int remoteUid, bool muted) async {
    if (!_initialized) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_WEB] Muting remote video: uid=$remoteUid, muted=$muted');
      final bridge = globalContext['agoraWeb'] as JSObject?;

      if (bridge == null) {
        throw VideoEngineException('Bridge unavailable');
      }

      final muteRemoteVideoFn = bridge['muteRemoteVideo'] as JSFunction?;
      if (muteRemoteVideoFn == null) {
        throw VideoEngineException('muteRemoteVideo not supported on web');
      }

      final promiseObj = muteRemoteVideoFn.callAsFunction(null, remoteUid.toJS, muted.toJS) as JSPromise;
      await promiseObj.toDart;

      // Update local state
      if (_remoteUsersMap.containsKey(remoteUid)) {
        _remoteUsersMap[remoteUid] = RemoteUser(
          uid: remoteUid,
          audioEnabled: _remoteUsersMap[remoteUid]!.audioEnabled,
          videoEnabled: !muted,
        );
        _remoteUsersController.add(remoteUsers);
      }

      debugPrint('[AGORA_WEB] âœ… Remote video muted');
    } catch (e) {
      AppLogger.error('Mute remote video failed: $e');
      throw VideoEngineException('Failed to mute remote video', originalError: e);
    }
  }

  @override
  Future<void> dispose() async {
    await leaveChannel();
    await _remoteUsersController.close();
    await _connectionStateController.close();
    _initialized = false;
    debugPrint('[AGORA_WEB] Engine disposed');
  }

  /// Private helper: Set up event callbacks from JavaScript bridge
  void _setupEventCallbacks() {
    try {
      final bridge = globalContext['agoraWeb'] as JSObject?;
      if (bridge == null) return;

      // Remote user published (joins with audio/video)
      bridge.setProperty(
        'onRemoteUserPublished'.toJS,
        ((JSAny event) {
          try {
            final eventObj = event as JSObject;
            final uid = (eventObj['uid'] as JSNumber?)?.toDartInt;
            if (uid != null) {
              _remoteUsersMap[uid] = RemoteUser(
                uid: uid,
                audioEnabled: (eventObj['hasAudio'] as JSBoolean?)?.toDart ?? false,
                videoEnabled: (eventObj['hasVideo'] as JSBoolean?)?.toDart ?? false,
              );
              _remoteUsersController.add(remoteUsers);
              debugPrint('[AGORA_WEB] Remote user published: $uid');
            }
          } catch (e) {
            debugPrint('[AGORA_WEB] Error in onRemoteUserPublished: $e');
          }
        }).toJS,
      );

      // Remote user unpublished (leaves or turns off tracks)
      bridge.setProperty(
        'onRemoteUserUnpublished'.toJS,
        ((JSAny event) {
          try {
            final eventObj = event as JSObject;
            final uid = (eventObj['uid'] as JSNumber?)?.toDartInt;
            if (uid != null && _remoteUsersMap.containsKey(uid)) {
              _remoteUsersMap.remove(uid);
              _remoteUsersController.add(remoteUsers);
              debugPrint('[AGORA_WEB] Remote user unpublished: $uid');
            }
          } catch (e) {
            debugPrint('[AGORA_WEB] Error in onRemoteUserUnpublished: $e');
          }
        }).toJS,
      );

      debugPrint('[AGORA_WEB] Event callbacks registered');
    } catch (e) {
      debugPrint('[AGORA_WEB] Error setting up callbacks: $e');
    }
  }
}
