import '../shared/models/remote_user.dart';
import 'dart:async';

abstract class IVideoEngine {
  Future<void> init(String appId, {String? token});
  Future<void> joinChannel({required String channel, required int uid, required String token});
  Future<void> leaveChannel();
  Future<void> enableLocalTracks({bool enableAudio, bool enableVideo});
  Future<void> setAudioMuted(bool muted);
  Future<void> setVideoMuted(bool muted);
  Stream<List<RemoteUser>> get remoteUsersStream;
}


