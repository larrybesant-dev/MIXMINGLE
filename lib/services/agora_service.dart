import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
    // List of remote user IDs
    final List<int> _remoteUids = [];

    // Callbacks for UI updates
    VoidCallback? onRemoteUserJoined;
    VoidCallback? onRemoteUserLeft;

    List<int> get remoteUids => List.unmodifiable(_remoteUids);

    /// Get the local video view widget
    Widget getLocalView() {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    /// Get the remote video view widget for a given uid
    Widget getRemoteView(int uid) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: const RtcConnection(channelId: 'room1'), // TODO: dynamic channel
        ),
      );
    }
  late RtcEngine _engine;

  /// Initialize Agora engine with your App ID
  Future<void> initialize(String appId) async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.enableVideo();

    // Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          _remoteUids.add(remoteUid);
          if (onRemoteUserJoined != null) onRemoteUserJoined!();
        },
        onUserOffline: (connection, remoteUid, reason) {
          _remoteUids.remove(remoteUid);
          if (onRemoteUserLeft != null) onRemoteUserLeft!();
        },
      ),
    );
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
