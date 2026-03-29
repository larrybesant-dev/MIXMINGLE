import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart'; // For Widget, VoidCallback

class AgoraService {
    // List of remote user IDs
    final List<int> _remoteUids = [];
  final Set<int> _speakingUids = <int>{};
  bool _localSpeaking = false;

    // Callbacks for UI updates
    VoidCallback? onRemoteUserJoined;
    VoidCallback? onRemoteUserLeft;
  VoidCallback? onSpeakerActivityChanged;

    List<int> get remoteUids => List.unmodifiable(_remoteUids);
  bool get localSpeaking => _localSpeaking;

  bool isRemoteSpeaking(int uid) => _speakingUids.contains(uid);

    /// Get the local video view widget
    Widget getLocalView() {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    /// Get the remote video view widget for a given uid and channel
    Widget getRemoteView(int uid, String channelId) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: channelId),
        ),
      );
    }
  late RtcEngine _engine;
  bool _initialized = false;

  /// Initialize Agora engine with your App ID
  Future<void> initialize(String appId) async {
    final normalizedAppId = appId.trim();
    if (normalizedAppId.isEmpty) {
      throw ArgumentError('Agora appId cannot be empty.');
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: normalizedAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine.enableVideo();
    await _engine.enableAudio();
    await _engine.enableAudioVolumeIndication(
      interval: 300,
      smooth: 3,
      reportVad: true,
    );

    // Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          _remoteUids.add(remoteUid);
          if (onRemoteUserJoined != null) onRemoteUserJoined!();
        },
        onUserOffline: (connection, remoteUid, reason) {
          _remoteUids.remove(remoteUid);
          _speakingUids.remove(remoteUid);
          if (onRemoteUserLeft != null) onRemoteUserLeft!();
        },
        onAudioVolumeIndication: (
          connection,
          speakers,
          speakerNumber,
          totalVolume,
        ) {
          final nextSpeakingUids = <int>{};
          var nextLocalSpeaking = false;
          for (final speaker in speakers) {
            final uid = speaker.uid ?? 0;
            final volume = speaker.volume ?? 0;
            if (volume <= 10) {
              continue;
            }
            if (uid == 0) {
              nextLocalSpeaking = true;
            } else {
              nextSpeakingUids.add(uid);
            }
          }

          final changed =
              nextLocalSpeaking != _localSpeaking ||
              nextSpeakingUids.length != _speakingUids.length ||
              !nextSpeakingUids.containsAll(_speakingUids);
          if (!changed) {
            return;
          }

          _localSpeaking = nextLocalSpeaking;
          _speakingUids
            ..clear()
            ..addAll(nextSpeakingUids);
          if (onSpeakerActivityChanged != null) {
            onSpeakerActivityChanged!();
          }
        },
      ),
    );
    _initialized = true;
  }

  /// Join a video channel
  Future<void> joinChannel(
    String token,
    String channelName,
    int uid, {
    required bool asBroadcaster,
  }) async {
    if (!_initialized) {
      throw StateError('Agora engine must be initialized before joining a channel.');
    }

    final normalizedToken = token.trim();
    final normalizedChannelName = channelName.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError('Agora token cannot be empty.');
    }
    if (normalizedChannelName.isEmpty) {
      throw ArgumentError('Agora channelName cannot be empty.');
    }

    final role = asBroadcaster
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    await _engine.joinChannel(
      token: normalizedToken,
      channelId: normalizedChannelName,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: role,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: asBroadcaster,
        publishMicrophoneTrack: asBroadcaster,
      ),
    );
  }

  Future<void> setBroadcaster(bool enabled) async {
    if (!_initialized) return;
    await _engine.setClientRole(
      role: enabled
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    if (!_initialized) return;
    await _engine.leaveChannel();
  }

  /// Mute/unmute local audio
  Future<void> mute(bool muted) async {
    if (!_initialized) return;
    await _engine.muteLocalAudioStream(muted);
  }

  /// Enable/disable video
  Future<void> enableVideo(bool enabled) async {
    if (!_initialized) return;
    if (enabled) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await _engine.leaveChannel();
    await _engine.release();
    _speakingUids.clear();
    _localSpeaking = false;
    _initialized = false;
  }
}
