import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/remote_user.dart';
import 'video_engine_interface.dart';
import 'dart:async';

class AgoraMobileEngine implements IVideoEngine {
  late final RtcEngine _engine;
  final Map<int, RemoteUser> _remoteUsersMap = {};
  final StreamController<List<RemoteUser>> _remoteUsersController = StreamController.broadcast();

  @override
  Stream<List<RemoteUser>> get remoteUsersStream => _remoteUsersController.stream;

  @override
  Future<void> init(String appId, {String? token}) async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: appId));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint('ðŸŽ¥ Remote user joined: $remoteUid');
          _remoteUsersMap[remoteUid] = RemoteUser(uid: remoteUid);
          _remoteUsersController.add(_remoteUsersMap.values.toList());
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint('â›” Remote user left: $remoteUid (reason: $reason)');
          _remoteUsersMap.remove(remoteUid);
          _remoteUsersController.add(_remoteUsersMap.values.toList());
        },
      ));

      debugPrint('âœ… Agora Mobile Engine initialized');
    } catch (e) {
      debugPrint('âŒ Error initializing Agora Mobile Engine: $e');
      rethrow;
    }
  }

  @override
  Future<void> joinChannel({required String channel, required int uid, required String token}) async {
    try {
      await _engine.joinChannel(
        token: token,
        channelId: channel,
        uid: uid,
        options: const ChannelMediaOptions(),
      );
      debugPrint('âœ… Joined channel: $channel with UID: $uid');
    } catch (e) {
      debugPrint('âŒ Error joining channel: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveChannel() async {
    try {
      await _engine.leaveChannel();
      _remoteUsersMap.clear();
      _remoteUsersController.add([]);
      debugPrint('âœ… Left channel');
    } catch (e) {
      debugPrint('âŒ Error leaving channel: $e');
      rethrow;
    }
  }

  @override
  Future<void> enableLocalTracks({bool enableAudio = true, bool enableVideo = true}) async {
    try {
      await _engine.enableLocalAudio(enableAudio);
      await _engine.enableLocalVideo(enableVideo);
      debugPrint('âœ… Local tracks enabled - Audio: $enableAudio, Video: $enableVideo');
    } catch (e) {
      debugPrint('âŒ Error enabling local tracks: $e');
      rethrow;
    }
  }

  @override
  Future<void> setAudioMuted(bool muted) async {
    try {
      await _engine.muteLocalAudioStream(muted);
      debugPrint('âœ… Audio ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('âŒ Error setting audio mute: $e');
      rethrow;
    }
  }

  @override
  Future<void> setVideoMuted(bool muted) async {
    try {
      await _engine.muteLocalVideoStream(muted);
      debugPrint('âœ… Video ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('âŒ Error setting video mute: $e');
      rethrow;
    }
  }
}
