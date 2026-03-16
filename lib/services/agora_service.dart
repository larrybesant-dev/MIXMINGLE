import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  late RtcEngine _engine;

  Future<void> initialize(String appId) async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.enableVideo();
  }

  Future<void> joinChannel(String token, String channelName, int uid) async {
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  Future<void> mute(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }

  Future<void> enableVideo(bool enabled) async {
    if (enabled) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
  }
}
