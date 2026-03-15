/// Unified video engine models for Web + Mobile parity
library;

import 'package:flutter/foundation.dart';

/// Represents a remote user in the channel
@immutable
class RemoteUser {
  final int uid;
  final bool audioEnabled;
  final bool videoEnabled;
  final int? timestamp;

  const RemoteUser({
    required this.uid,
    required this.audioEnabled,
    required this.videoEnabled,
    this.timestamp,
  });

  @override
  String toString() =>
      'RemoteUser(uid=$uid, audio=$audioEnabled, video=$videoEnabled)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteUser &&
          uid == other.uid &&
          audioEnabled == other.audioEnabled &&
          videoEnabled == other.videoEnabled;

  @override
  int get hashCode => Object.hash(uid, audioEnabled, videoEnabled);
}

/// Represents local media track state
@immutable
class LocalMediaState {
  final bool audioEnabled;
  final bool videoEnabled;
  final bool cameraOn;
  final bool micOn;

  const LocalMediaState({
    required this.audioEnabled,
    required this.videoEnabled,
    required this.cameraOn,
    required this.micOn,
  });

  @override
  String toString() =>
      'LocalMediaState(audio=$audioEnabled, video=$videoEnabled, camera=$cameraOn, mic=$micOn)';
}

/// Represents channel connection state
enum ChannelState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  disconnecting,
}

/// Represents video source (camera, screen, etc)
enum VideoSource {
  camera,
  screen,
  customSource,
}

/// Exception thrown by video engine
class VideoEngineException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  VideoEngineException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'VideoEngineException: $message';
}
