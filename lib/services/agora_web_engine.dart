import 'dart:async';
import '../models/remote_user.dart';
import 'video_engine_interface.dart';
import 'package:flutter/foundation.dart';

class AgoraWebEngine implements IVideoEngine {
  bool _initialized = false;
  final Map<int, RemoteUser> _remoteUsersMap = {};
  final StreamController<List<RemoteUser>> _remoteUsersController = StreamController.broadcast();

  @override
  Stream<List<RemoteUser>> get remoteUsersStream => _remoteUsersController.stream;

  @override
  Future<void> init(String appId, {String? token}) async {
    if (_initialized) return;
    try {
      // Call the JS function via dart:js_interop
      // This is a test/mock implementation - for real Agora SDK, implement actual native calls
      debugPrint('✅ Agora Web Engine initialized with App ID: $appId');
      _initialized = true;

      debugPrint('✅ Agora Web Engine initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Agora Web Engine: $e');
      rethrow;
    }
  }

  @override
  Future<void> joinChannel({required String channel, required int uid, required String token}) async {
    try {
      debugPrint('✅ Joined channel: $channel with UID: $uid');

      // Simulate a remote user joining after 2 seconds (for testing)
      Future.delayed(const Duration(seconds: 2), () {
        _addRemoteUser(1234);
      });
    } catch (e) {
      debugPrint('❌ Error joining channel: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveChannel() async {
    try {
      Future.delayed(const Duration(milliseconds: 500), () {
        _removeRemoteUser(1234);
      });

      _remoteUsersMap.clear();
      _remoteUsersController.add([]);
      debugPrint('✅ Left channel');
    } catch (e) {
      debugPrint('❌ Error leaving channel: $e');
      rethrow;
    }
  }

  @override
  Future<void> enableLocalTracks({bool enableAudio = true, bool enableVideo = true}) async {
    try {
      debugPrint('✅ Local tracks enabled - Audio: $enableAudio, Video: $enableVideo');
    } catch (e) {
      debugPrint('❌ Error enabling local tracks: $e');
      rethrow;
    }
  }

  @override
  Future<void> setAudioMuted(bool muted) async {
    try {
      debugPrint('✅ Audio ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('❌ Error setting audio mute: $e');
      rethrow;
    }
  }

  @override
  Future<void> setVideoMuted(bool muted) async {
    try {
      debugPrint('✅ Video ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('❌ Error setting video mute: $e');
      rethrow;
    }
  }

  void _addRemoteUser(int uid) {
    debugPrint('🎥 Remote user joined: $uid');
    _remoteUsersMap[uid] = RemoteUser(uid: uid);
    _remoteUsersController.add(_remoteUsersMap.values.toList());
  }

  void _removeRemoteUser(int uid) {
    debugPrint('⛔ Remote user left: $uid');
    _remoteUsersMap.remove(uid);
    _remoteUsersController.add(_remoteUsersMap.values.toList());
  }
}
