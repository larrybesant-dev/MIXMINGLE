import 'dart:developer' as developer;
import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart'; // For Widget, VoidCallback

import 'web_media_probe_stub.dart'
  if (dart.library.html) 'web_media_probe_web.dart' as web_media_probe;

class AgoraServiceException implements Exception {
  const AgoraServiceException({
    required this.code,
    required this.message,
    this.cause,
  });

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AgoraServiceException($code): $message';
}

class AgoraService {
    // List of remote user IDs
    final List<int> _remoteUids = [];
  final Set<int> _speakingUids = <int>{};
  bool _localSpeaking = false;
  bool _joinedChannel = false;
  bool _broadcasterMode = false;
  bool _localVideoCapturing = false;
  Completer<void>? _localVideoCaptureCompleter;

    // Callbacks for UI updates
    VoidCallback? onRemoteUserJoined;
    VoidCallback? onRemoteUserLeft;
  VoidCallback? onSpeakerActivityChanged;

    List<int> get remoteUids => List.unmodifiable(_remoteUids);
  bool get localSpeaking => _localSpeaking;
  bool get canRenderLocalView =>
      _initialized && _joinedChannel && _broadcasterMode && _localVideoCapturing;

  bool isRemoteSpeaking(int uid) => _speakingUids.contains(uid);

    /// Get the local video view widget
    Widget getLocalView() {
      if (!canRenderLocalView) {
        return const ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.videocam_off, size: 36)),
        );
      }
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

  Future<void> ensureDeviceAccess({required bool video, required bool audio}) async {
    try {
      await web_media_probe.ensureUserMediaAccess(video: video, audio: audio);
    } catch (error) {
      _throwMappedAgoraError(
        error,
        operation: video ? 'access camera' : 'access microphone',
      );
    }
  }

  Never _throwMappedAgoraError(Object error, {required String operation}) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('notallowederror') ||
        lower.contains('permission denied') ||
        lower.contains('permission denied by system')) {
      throw AgoraServiceException(
        code: 'permission-denied',
        message:
            'Camera/microphone permission was denied. Please allow access and retry.',
        cause: error,
      );
    }

    if (lower.contains('notfounderror') ||
        lower.contains('requested device not found') ||
        lower.contains('no audio input') ||
        lower.contains('no video input') ||
        lower.contains('devicesnotfound')) {
      throw AgoraServiceException(
        code: 'no-media-devices',
        message:
            'No working camera or microphone was found on this device.',
        cause: error,
      );
    }

    if (lower.contains('notreadableerror') ||
        lower.contains('track is already in use') ||
        lower.contains('device in use')) {
      throw AgoraServiceException(
        code: 'device-in-use',
        message:
            'Camera or microphone is currently in use by another app or tab.',
        cause: error,
      );
    }

    if (lower.contains('notsupportederror') ||
      lower.contains('unsupported browser') ||
      lower.contains('webrtc is not supported') ||
      lower.contains('not supported on this browser')) {
      throw AgoraServiceException(
        code: 'unsupported-browser',
        message:
            'This browser does not fully support required WebRTC features. Use latest Chrome or Edge.',
        cause: error,
      );
    }

    if (lower.contains('secure context') ||
        lower.contains('https') ||
        lower.contains('only secure origins')) {
      throw AgoraServiceException(
        code: 'insecure-context',
        message:
            'Camera/microphone requires HTTPS (or localhost). Open the app over a secure origin.',
        cause: error,
      );
    }

    throw AgoraServiceException(
      code: 'agora-$operation-failed',
      message: 'Failed to $operation. Please retry.',
      cause: error,
    );
  }

  AgoraServiceException _mapLocalVideoReason(LocalVideoStreamReason reason) {
    switch (reason) {
      case LocalVideoStreamReason.localVideoStreamReasonDeviceNoPermission:
        return const AgoraServiceException(
          code: 'permission-denied',
          message: 'Camera permission was denied by browser or OS settings.',
        );
      case LocalVideoStreamReason.localVideoStreamReasonDeviceBusy:
        return const AgoraServiceException(
          code: 'device-in-use',
          message: 'Camera is busy in another app or browser tab.',
        );
      case LocalVideoStreamReason.localVideoStreamReasonDeviceNotFound:
        return const AgoraServiceException(
          code: 'no-media-devices',
          message: 'No camera device was found on this computer.',
        );
      case LocalVideoStreamReason.localVideoStreamReasonCaptureFailure:
      case LocalVideoStreamReason.localVideoStreamReasonDeviceInterrupt:
      case LocalVideoStreamReason.localVideoStreamReasonDeviceFatalError:
        return const AgoraServiceException(
          code: 'camera-start-failed',
          message: 'Camera failed to start. Close other camera apps/tabs and retry.',
        );
      default:
        return const AgoraServiceException(
          code: 'camera-not-started',
          message: 'Camera did not start successfully.',
        );
    }
  }

  Future<void> _awaitLocalVideoCapturing({Duration timeout = const Duration(seconds: 4)}) async {
    if (_localVideoCapturing) {
      return;
    }
    final completer = Completer<void>();
    _localVideoCaptureCompleter = completer;
    try {
      await completer.future.timeout(
        timeout,
        onTimeout: () => throw const AgoraServiceException(
          code: 'camera-not-started',
          message: 'Camera did not start in time. Check camera permissions and device usage.',
        ),
      );
    } finally {
      if (identical(_localVideoCaptureCompleter, completer)) {
        _localVideoCaptureCompleter = null;
      }
    }
  }

  /// Initialize Agora engine with your App ID
  Future<void> initialize(String appId) async {
    final normalizedAppId = appId.trim();
    if (normalizedAppId.isEmpty) {
      throw ArgumentError('Agora appId cannot be empty.');
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(
          appId: normalizedAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
    } catch (error) {
      _throwMappedAgoraError(error, operation: 'initialize live media');
    }

    // Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!_remoteUids.contains(remoteUid)) {
            _remoteUids.add(remoteUid);
          }
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
        onError: (err, msg) {
          developer.log(
            'Agora engine error: $err $msg',
            name: 'AgoraService',
          );
        },
        onLocalVideoStateChanged: (source, state, reason) {
          if (!source.name.startsWith('videoSourceCamera')) {
            return;
          }
          developer.log(
            'Local video state: $state, reason: $reason',
            name: 'AgoraService',
          );
          if (state == LocalVideoStreamState.localVideoStreamStateCapturing ||
              state == LocalVideoStreamState.localVideoStreamStateEncoding) {
            _localVideoCapturing = true;
            final waiter = _localVideoCaptureCompleter;
            if (waiter != null && !waiter.isCompleted) {
              waiter.complete();
            }
            return;
          }

          if (state == LocalVideoStreamState.localVideoStreamStateFailed) {
            _localVideoCapturing = false;
            final waiter = _localVideoCaptureCompleter;
            if (waiter != null && !waiter.isCompleted) {
              waiter.completeError(_mapLocalVideoReason(reason));
            }
            return;
          }

          if (state == LocalVideoStreamState.localVideoStreamStateStopped) {
            _localVideoCapturing = false;
          }
        },
      ),
    );

    // Media features are best-effort on web and should not block room join.
    try {
      // On web, this can fail before channel join on some runtimes; keep it non-fatal.
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    } catch (error, stackTrace) {
      developer.log(
        'Agora setClientRole(audience) skipped during initialize',
        name: 'AgoraService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _engine.enableAudio();
    } catch (error, stackTrace) {
      developer.log(
        'Agora enableAudio failed',
        name: 'AgoraService',
        error: error,
        stackTrace: stackTrace,
      );
    }
    try {
      await _engine.enableAudioVolumeIndication(
        interval: 300,
        smooth: 3,
        reportVad: true,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Agora audio volume indication failed',
        name: 'AgoraService',
        error: error,
        stackTrace: stackTrace,
      );
    }
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

    if (asBroadcaster) {
      try {
        await _engine.enableVideo();
      } catch (error, stackTrace) {
        developer.log(
          'Agora enableVideo failed before join',
          name: 'AgoraService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    try {
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
      // Ensure local camera track state is explicitly enabled after join for web reliability.
      if (asBroadcaster) {
        await _engine.enableLocalVideo(true);
        await _engine.muteLocalVideoStream(false);
        try {
          await _engine.startPreview();
        } catch (_) {
          // Some runtimes do not require preview; ignore and continue.
        }
      }
    } catch (error) {
      _throwMappedAgoraError(error, operation: 'join room');
    }
    _joinedChannel = true;
    _broadcasterMode = asBroadcaster;
  }

  Future<void> setBroadcaster(bool enabled) async {
    if (!_initialized) return;
    try {
      await _engine.setClientRole(
        role: enabled
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );
    } catch (error) {
      _throwMappedAgoraError(error, operation: 'switch role');
    }
    _broadcasterMode = enabled;
    if (enabled) {
      try {
        await _engine.enableVideo();
      } catch (error, stackTrace) {
        developer.log(
          'Agora enableVideo failed while switching role',
          name: 'AgoraService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    if (!_initialized) return;
    if (_joinedChannel) {
      await _engine.leaveChannel();
    }
    _remoteUids.clear();
    _speakingUids.clear();
    _localSpeaking = false;
    _joinedChannel = false;
    _broadcasterMode = false;
    _localVideoCapturing = false;
  }

  /// Mute/unmute local audio
  Future<void> mute(bool muted) async {
    if (!_initialized) return;
    try {
      await _engine.muteLocalAudioStream(muted);
    } catch (error) {
      _throwMappedAgoraError(error, operation: 'toggle microphone');
    }
  }

  /// Enable/disable video
  Future<void> enableVideo(bool enabled) async {
    if (!_initialized) return;
    try {
      if (enabled) {
        if (!_broadcasterMode) {
          await _engine.setClientRole(
            role: ClientRoleType.clientRoleBroadcaster,
          );
          _broadcasterMode = true;
        }
        await _engine.enableVideo();
        await _engine.enableLocalVideo(true);
        await _engine.muteLocalVideoStream(false);
        try {
          await _engine.startPreview();
        } catch (_) {
          // Best effort on web/native combinations.
        }
        if (_joinedChannel) {
          await _engine.updateChannelMediaOptions(
            ChannelMediaOptions(
              channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
              clientRoleType: ClientRoleType.clientRoleBroadcaster,
              autoSubscribeAudio: true,
              autoSubscribeVideo: true,
              publishCameraTrack: true,
              publishMicrophoneTrack: false,
            ),
          );
        }
        await _awaitLocalVideoCapturing();
      } else {
        await _engine.muteLocalVideoStream(true);
        await _engine.enableLocalVideo(false);
        _localVideoCapturing = false;
        try {
          await _engine.stopPreview();
        } catch (_) {
          // Best effort cleanup.
        }
        if (_joinedChannel) {
          await _engine.updateChannelMediaOptions(
            ChannelMediaOptions(
              channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
              clientRoleType: ClientRoleType.clientRoleBroadcaster,
              autoSubscribeAudio: true,
              autoSubscribeVideo: true,
              publishCameraTrack: false,
              publishMicrophoneTrack: false,
            ),
          );
        }
      }
    } catch (error) {
      if (error is AgoraServiceException) {
        rethrow;
      }
      _throwMappedAgoraError(error, operation: 'toggle camera');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    if (_joinedChannel) {
      await _engine.leaveChannel();
    }
    await _engine.release();
    _remoteUids.clear();
    _speakingUids.clear();
    _localSpeaking = false;
    _joinedChannel = false;
    _broadcasterMode = false;
    _localVideoCapturing = false;
    _initialized = false;
  }
}
