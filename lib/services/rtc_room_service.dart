import 'package:flutter/material.dart';

/// Abstract interface shared by [AgoraService] (native/web Agora SDK) and
/// [WebRtcRoomService] (browser-native WebRTC with Firestore signaling).
///
/// The live_room_screen uses this type so it can transparently swap between
/// implementations without changing any call sites.
abstract class RtcRoomService {
  // ──────────────────────────────────────────────────────────────────────────
  // Callbacks – concrete subclasses declare matching fields.
  // ──────────────────────────────────────────────────────────────────────────

  VoidCallback? onRemoteUserJoined;
  VoidCallback? onRemoteUserLeft;
  VoidCallback? onSpeakerActivityChanged;
  VoidCallback? onLocalVideoCaptureChanged;
  VoidCallback? onTokenWillExpire;
  VoidCallback? onConnectionLost;

  // ──────────────────────────────────────────────────────────────────────────
  // State getters
  // ──────────────────────────────────────────────────────────────────────────

  List<int> get remoteUids;
  bool get localSpeaking;
  bool get canRenderLocalView;
  bool get isBroadcaster;
  bool get isJoinedChannel;
  bool get isLocalVideoCapturing;

  bool isRemoteSpeaking(int uid);

  /// Returns the Firestore userId for a remote [uid] if the service has an
  /// explicit mapping (WebRTC), or null if the caller must fall back to the
  /// hash-based lookup (Agora).
  String? userIdForUid(int uid) => null;

  // ──────────────────────────────────────────────────────────────────────────
  // Video views
  // ──────────────────────────────────────────────────────────────────────────

  Widget getLocalView();
  Widget getRemoteView(int uid, String channelId);

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> initialize(String appId);

  Future<void> joinRoom(
    String token,
    String channelName,
    int uid, {
    bool publishCameraTrackOnJoin = false,
    bool publishMicrophoneTrackOnJoin = false,
  });

  Future<void> enableVideo(bool enabled, {bool publishMicrophoneTrack = true});

  Future<void> mute(bool muted);

  Future<void> setBroadcaster(bool enabled);

  Future<void> publishLocalVideoStream(bool enabled);

  Future<void> publishLocalAudioStream(bool enabled);

  Future<void> setRemoteVideoSubscription(
    int uid, {
    required bool subscribe,
    bool highQuality = false,
  });

  Future<void> renewToken(String newToken);

  Future<void> dispose();

  Future<void> ensureDeviceAccess({
    required bool video,
    required bool audio,
  });
}
