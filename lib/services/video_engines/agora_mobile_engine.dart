/// Agora Mobile Engine - implements IVideoEngine for iOS/Android
///
/// Wraps native Agora SDK and provides the same interface as Web.
library;

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/models/video_engine_models.dart';
import '../../core/interfaces/video_engine_interface.dart';
import '../../core/utils/app_logger.dart';

class AgoraMobileEngine implements IVideoEngine {
  RtcEngine? _engine;
  bool _initialized = false;
  bool _connected = false;

  final _remoteUsersController = StreamController<List<RemoteUser>>.broadcast();
  final _connectionStateController = StreamController<ChannelState>.broadcast();

  final Map<int, RemoteUser> _remoteUsersMap = {};
  LocalMediaState? _localMediaState;

  AgoraMobileEngine() {
    debugPrint('[AGORA_MOBILE] Engine instance created');
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
      debugPrint('[AGORA_MOBILE] Already initialized');
      return;
    }

    try {
      debugPrint('[AGORA_MOBILE] Initializing with appId: $appId');

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: appId));

      _setupEventHandlers();
      _initialized = true;
      debugPrint('[AGORA_MOBILE] ✅ Initialization complete');
    } catch (e) {
      AppLogger.error('Mobile initialization failed: $e');
      throw VideoEngineException('Failed to initialize Agora Mobile Engine', originalError: e);
    }
  }

  @override
  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required String? token,
  }) async {
    if (!_initialized || _engine == null) {
      throw VideoEngineException('Engine not initialized. Call initialize() first.');
    }

    try {
      debugPrint('[AGORA_MOBILE] Joining channel: $channelName, uid: $uid');

      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      _connected = true;
      _connectionStateController.add(ChannelState.connected);
      _localMediaState = const LocalMediaState(
        audioEnabled: true,
        videoEnabled: true,
        cameraOn: true,
        micOn: true,
      );

      debugPrint('[AGORA_MOBILE] ✅ Joined channel');
    } catch (e) {
      AppLogger.error('Join channel failed: $e');
      _connectionStateController.add(ChannelState.disconnected);
      throw VideoEngineException('Failed to join channel', originalError: e);
    }
  }

  @override
  Future<void> leaveChannel() async {
    if (!_initialized || !_connected || _engine == null) {
      debugPrint('[AGORA_MOBILE] Not connected, skipping leave');
      return;
    }

    try {
      debugPrint('[AGORA_MOBILE] Leaving channel');
      await _engine!.leaveChannel();

      _connected = false;
      _remoteUsersMap.clear();
      _remoteUsersController.add([]);
      _localMediaState = null;
      _connectionStateController.add(ChannelState.disconnected);

      debugPrint('[AGORA_MOBILE] ✅ Left channel');
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
    if (!_initialized || _engine == null) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_MOBILE] Enabling local tracks: audio=$enableAudio, video=$enableVideo');

      if (enableAudio) {
        await _engine!.enableAudio();
      } else {
        await _engine!.disableAudio();
      }

      if (enableVideo) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }

      _localMediaState = LocalMediaState(
        audioEnabled: enableAudio,
        videoEnabled: enableVideo,
        cameraOn: enableVideo,
        micOn: enableAudio,
      );

      debugPrint('[AGORA_MOBILE] ✅ Local tracks updated');
    } catch (e) {
      AppLogger.error('Enable local tracks failed: $e');
      throw VideoEngineException('Failed to enable local tracks', originalError: e);
    }
  }

  @override
  Future<void> setAudioMuted(bool muted) async {
    if (!_initialized || _engine == null) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_MOBILE] Setting audio muted: $muted');

      if (muted) {
        await _engine!.muteLocalAudioStream(true);
      } else {
        await _engine!.muteLocalAudioStream(false);
      }

      if (_localMediaState != null) {
        _localMediaState = LocalMediaState(
          audioEnabled: !muted,
          videoEnabled: _localMediaState!.videoEnabled,
          cameraOn: _localMediaState!.cameraOn,
          micOn: !muted,
        );
      }

      debugPrint('[AGORA_MOBILE] ✅ Audio mute state: $muted');
    } catch (e) {
      AppLogger.error('Set audio muted failed: $e');
      throw VideoEngineException('Failed to set audio muted', originalError: e);
    }
  }

  @override
  Future<void> setVideoMuted(bool muted) async {
    if (!_initialized || _engine == null) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_MOBILE] Setting video muted: $muted');

      if (muted) {
        await _engine!.muteLocalVideoStream(true);
      } else {
        await _engine!.muteLocalVideoStream(false);
      }

      if (_localMediaState != null) {
        _localMediaState = LocalMediaState(
          audioEnabled: _localMediaState!.audioEnabled,
          videoEnabled: !muted,
          cameraOn: !muted,
          micOn: _localMediaState!.micOn,
        );
      }

      debugPrint('[AGORA_MOBILE] ✅ Video mute state: $muted');
    } catch (e) {
      AppLogger.error('Set video muted failed: $e');
      throw VideoEngineException('Failed to set video muted', originalError: e);
    }
  }

  @override
  Future<void> muteRemoteAudio(int remoteUid, bool muted) async {
    if (!_initialized || _engine == null) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_MOBILE] Muting remote audio: uid=$remoteUid, muted=$muted');
      await _engine!.muteRemoteAudioStream(uid: remoteUid, mute: muted);

      // Update local state
      if (_remoteUsersMap.containsKey(remoteUid)) {
        _remoteUsersMap[remoteUid] = RemoteUser(
          uid: remoteUid,
          audioEnabled: !muted,
          videoEnabled: _remoteUsersMap[remoteUid]!.videoEnabled,
        );
        _remoteUsersController.add(remoteUsers);
      }

      debugPrint('[AGORA_MOBILE] ✅ Remote audio muted');
    } catch (e) {
      AppLogger.error('Mute remote audio failed: $e');
      throw VideoEngineException('Failed to mute remote audio', originalError: e);
    }
  }

  @override
  Future<void> muteRemoteVideo(int remoteUid, bool muted) async {
    if (!_initialized || _engine == null) {
      throw VideoEngineException('Engine not initialized');
    }

    try {
      debugPrint('[AGORA_MOBILE] Muting remote video: uid=$remoteUid, muted=$muted');
      await _engine!.muteRemoteVideoStream(uid: remoteUid, mute: muted);

      // Update local state
      if (_remoteUsersMap.containsKey(remoteUid)) {
        _remoteUsersMap[remoteUid] = RemoteUser(
          uid: remoteUid,
          audioEnabled: _remoteUsersMap[remoteUid]!.audioEnabled,
          videoEnabled: !muted,
        );
        _remoteUsersController.add(remoteUsers);
      }

      debugPrint('[AGORA_MOBILE] ✅ Remote video muted');
    } catch (e) {
      AppLogger.error('Mute remote video failed: $e');
      throw VideoEngineException('Failed to mute remote video', originalError: e);
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await leaveChannel();
      if (_engine != null) {
        await _engine!.release();
        _engine = null;
      }
      await _remoteUsersController.close();
      await _connectionStateController.close();
      _initialized = false;
      debugPrint('[AGORA_MOBILE] Engine disposed');
    } catch (e) {
      debugPrint('[AGORA_MOBILE] Error disposing: $e');
    }
  }

  /// Private helper: Set up native event handlers
  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint('[AGORA_MOBILE] Remote user joined: $remoteUid');
          _remoteUsersMap[remoteUid] = RemoteUser(
            uid: remoteUid,
            audioEnabled: true,
            videoEnabled: true,
          );
          _remoteUsersController.add(remoteUsers);
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint('[AGORA_MOBILE] Remote user offline: $remoteUid, reason: $reason');
          if (_remoteUsersMap.containsKey(remoteUid)) {
            _remoteUsersMap.remove(remoteUid);
            _remoteUsersController.add(remoteUsers);
          }
        },
        onRemoteAudioStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          debugPrint('[AGORA_MOBILE] Remote audio state changed: uid=$remoteUid, state=$state');
          if (_remoteUsersMap.containsKey(remoteUid)) {
            _remoteUsersMap[remoteUid] = RemoteUser(
              uid: remoteUid,
              audioEnabled: state == RemoteAudioState.remoteAudioStateStarting ||
                  state == RemoteAudioState.remoteAudioStateDecoding,
              videoEnabled: _remoteUsersMap[remoteUid]!.videoEnabled,
            );
            _remoteUsersController.add(remoteUsers);
          }
        },
        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          debugPrint('[AGORA_MOBILE] Remote video state changed: uid=$remoteUid, state=$state');
          if (_remoteUsersMap.containsKey(remoteUid)) {
            _remoteUsersMap[remoteUid] = RemoteUser(
              uid: remoteUid,
              audioEnabled: _remoteUsersMap[remoteUid]!.audioEnabled,
              videoEnabled: state == RemoteVideoState.remoteVideoStateDecoding,
            );
            _remoteUsersController.add(remoteUsers);
          }
        },
      ),
    );

    debugPrint('[AGORA_MOBILE] Event handlers registered');
  }
}
