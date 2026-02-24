/// Abstract interface for video engine - implemented by both Web and Mobile
///
/// This interface ensures Web and Mobile implementations are interchangeable.
/// UI code should ONLY use this interface, never concrete implementations.
library;

import '../models/video_engine_models.dart';

abstract class IVideoEngine {
  /// Initialize the video engine with app credentials
  ///
  /// Must be called before any other method.
  /// Throws [VideoEngineException] if initialization fails.
  Future<void> initialize(String appId);

  /// Join a room/channel
  ///
  /// Returns stream of remote users in the room
  /// Throws [VideoEngineException] if join fails
  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required String? token,
  });

  /// Leave the current channel/room
  ///
  /// Cleans up all local and remote tracks
  /// Throws [VideoEngineException] if leave fails
  Future<void> leaveChannel();

  /// Enable/disable local audio and/or video
  ///
  /// Call this after joining to control local tracks
  /// Throws [VideoEngineException] if operation fails
  Future<void> enableLocalTracks({
    required bool enableAudio,
    required bool enableVideo,
  });

  /// Mute/unmute the local microphone
  ///
  /// Convenience method - equivalent to enableLocalTracks(enableAudio: !muted)
  /// Throws [VideoEngineException] if operation fails
  Future<void> setAudioMuted(bool muted);

  /// Mute/unmute the local camera
  ///
  /// Convenience method - equivalent to enableLocalTracks(enableVideo: !muted)
  /// Throws [VideoEngineException] if operation fails
  Future<void> setVideoMuted(bool muted);

  /// Mute/unmute a remote user's audio (host control)
  ///
  /// Only the host can mute remote users.
  /// This mutes the local playback of the remote user.
  /// Throws [VideoEngineException] if operation fails or user is not host
  Future<void> muteRemoteAudio(int remoteUid, bool muted);

  /// Mute/unmute a remote user's video (host control)
  ///
  /// Only the host can mute remote users' video.
  /// Throws [VideoEngineException] if operation fails or user is not host
  Future<void> muteRemoteVideo(int remoteUid, bool muted);

  /// Get current state of remote users in the channel
  List<RemoteUser> get remoteUsers;

  /// Stream of remote user changes
  ///
  /// Emits whenever:
  /// - A remote user joins
  /// - A remote user leaves
  /// - A remote user's audio/video state changes
  /// - A remote user's properties change
  Stream<List<RemoteUser>> get remoteUsersStream;

  /// Stream of channel connection state changes
  Stream<ChannelState> get connectionStateStream;

  /// Get local media state
  LocalMediaState? get localMediaState;

  /// Whether the engine is initialized
  bool get isInitialized;

  /// Whether currently connected to a channel
  bool get isConnected;

  /// Dispose resources when done
  Future<void> dispose();
}


