import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  late RtcEngine _engine;

  /// Initialize Agora engine with your App ID
  Future<void> initialize(String appId) async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.enableVideo();
  }

  /// Join a video channel
  Future<void> joinChannel(String token, String channelName, int uid) async {
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  /// Mute/unmute local audio
  Future<void> mute(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }

  /// Enable/disable video
  Future<void> enableVideo(bool enabled) async {
    if (enabled) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
  }
}
