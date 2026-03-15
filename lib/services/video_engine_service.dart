import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoEngineService {
  late RtcEngine _engine;

  Future<void> initialize(String appId) async {
    _engine = await RtcEngine.create(appId);
    await _engine.enableVideo();
    await _engine.enableAudio();
  }

  Future<void> joinChannel(String token, String channelName, int uid) async {
    await _engine.joinChannel(token, channelName, null, uid);
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  void muteLocalAudio(bool mute) {
    _engine.muteLocalAudioStream(mute);
  }

  void enableLocalVideo(bool enable) {
    _engine.enableLocalVideo(enable);
  }

  void setEventHandlers(RtcEngineEventHandler handler) {
    _engine.setEventHandler(handler);
  }
}
