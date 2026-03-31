import 'dart:developer' as developer;
import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For Widget, VoidCallback

import 'web_media_probe_stub.dart'
    if (dart.library.html) 'web_media_probe_web.dart'
    as web_media_probe;

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
  bool _enableVideoInFlight =
      false; // Track if we're actively enabling/disabling video
  Completer<void>? _localVideoCaptureCompleter;

  // Callbacks for UI updates
  VoidCallback? onRemoteUserJoined;
  VoidCallback? onRemoteUserLeft;
  VoidCallback? onSpeakerActivityChanged;

  List<int> get remoteUids => List.unmodifiable(_remoteUids);
  bool get localSpeaking => _localSpeaking;
  bool get canRenderLocalView =>
      _initialized &&
      _joinedChannel &&
      _broadcasterMode &&
      (_localVideoCapturing || kIsWeb);
  bool get isBroadcaster => _broadcasterMode;
  bool get isJoinedChannel => _joinedChannel;
  bool get isLocalVideoCapturing => _localVideoCapturing;

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

  Future<void> publishLocalVideoStream(bool enabled) async {
    if (!_initialized || !_joinedChannel) {
      return;
    }
    await _engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: _broadcasterMode
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: enabled,
        publishMicrophoneTrack: _broadcasterMode,
      ),
    );
  }

  Future<void> publishLocalAudioStream(bool enabled) async {
    if (!_initialized || !_joinedChannel) {
      return;
    }
    await _engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: _broadcasterMode
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: _localVideoCapturing,
        publishMicrophoneTrack: enabled,
      ),
    );
  }

  Future<void> _startCameraCaptureAfterRoleUpgrade() async {
    try {
      await _engine.startCameraCapture(
        sourceType: VideoSourceType.videoSourceCameraPrimary,
        config: const CameraCapturerConfiguration(),
      );
      developer.log(
        'startCameraCapture called after role upgrade',
        name: 'AgoraService',
      );
    } catch (error, stackTrace) {
      // Some platforms (notably web) can rely on enableVideo/startPreview instead.
      developer.log(
        'startCameraCapture skipped: $error',
        name: 'AgoraService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _ensurePublishPipelineAfterRoleUpgrade({
    required bool publishAudio,
  }) async {
    await publishLocalVideoStream(true);
    await publishLocalAudioStream(publishAudio);
    await _startCameraCaptureAfterRoleUpgrade();
    await _engine.enableLocalVideo(true);
    await _engine.muteLocalVideoStream(false);
    await _engine.muteLocalAudioStream(!publishAudio);
    try {
      await _engine.startPreview();
    } catch (_) {
      // Best effort preview start.
    }
  }

  Future<void> setRemoteVideoSubscription(
    int uid, {
    required bool subscribe,
  }) async {
    if (!_initialized || !_joinedChannel) {
      return;
    }
    await _engine.muteRemoteVideoStream(uid: uid, mute: !subscribe);
  }

  Future<void> ensureDeviceAccess({
    required bool video,
    required bool audio,
  }) async {
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
    final operationCode = operation
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

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
        message: 'No working camera or microphone was found on this device.',
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
        lower.contains('only secure origins') ||
        lower.contains('insecure context')) {
      throw AgoraServiceException(
        code: 'insecure-context',
        message:
            'Camera/microphone requires HTTPS (or localhost). Open the app over a secure origin.',
        cause: error,
      );
    }

    if (lower.contains('v8breakiterator') ||
        lower.contains('segmenter') ||
        lower.contains('webassembly') ||
        lower.contains('wasm')) {
      throw AgoraServiceException(
        code: 'unsupported-browser',
        message:
            'Browser runtime compatibility issue detected. Update browser and reload the page.',
        cause: error,
      );
    }

    throw AgoraServiceException(
      code: 'agora-$operationCode-failed',
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
          message:
              'Camera failed to start. Close other camera apps/tabs and retry.',
        );
      default:
        return const AgoraServiceException(
          code: 'camera-not-started',
          message: 'Camera did not start successfully.',
        );
    }
  }

  Future<void> _awaitLocalVideoCapturing({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_localVideoCapturing) {
      developer.log('Video already capturing', name: 'AgoraService');
      return;
    }
    final completer = Completer<void>();
    _localVideoCaptureCompleter = completer;
    developer.log(
      'Waiting for local video capturing with ${timeout.inSeconds}s timeout...',
      name: 'AgoraService',
    );
    try {
      await completer.future.timeout(
        timeout,
        onTimeout: () {
          developer.log(
            'Local video capturing timeout after ${timeout.inSeconds}s - permitting on web (state event may not fire reliably)',
            name: 'AgoraService',
            level: 701, // INFO level
          );
          // On web, the video state event may not fire reliably from Agora SDK.
          // Since ensureDeviceAccess (preflight) already confirmed camera access,
          // we complete successfully to avoid blocking the UI.
        },
      );
      developer.log(
        'Local video stream is ready (capturing started or timeout occurred)',
        name: 'AgoraService',
      );
    } catch (e) {
      developer.log(
        'Local video capturing failed: $e',
        name: 'AgoraService',
        error: e,
      );
      rethrow;
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

    final maxAttempts = kIsWeb ? 2 : 1;
    Object? lastInitError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _engine = createAgoraRtcEngine();
        await _engine.initialize(
          RtcEngineContext(
            appId: normalizedAppId,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          ),
        );
        lastInitError = null;
        break;
      } catch (error, stackTrace) {
        lastInitError = error;
        developer.log(
          'Agora initialize attempt $attempt/$maxAttempts failed: $error',
          name: 'AgoraService',
          error: error,
          stackTrace: stackTrace,
        );
        try {
          await _engine.release();
        } catch (_) {
          // Ignore cleanup failures between attempts.
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
    }

    if (lastInitError != null) {
      _throwMappedAgoraError(lastInitError, operation: 'initialize live media');
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
        onAudioVolumeIndication:
            (connection, speakers, speakerNumber, totalVolume) {
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
          developer.log('Agora engine error: $err $msg', name: 'AgoraService');
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

          // Ignore STOPPED events while we're actively enabling/disabling video
          // to avoid race conditions where the callback fires before the operation completes.
          if (state == LocalVideoStreamState.localVideoStreamStateStopped) {
            if (!_enableVideoInFlight) {
              _localVideoCapturing = false;
            } else {
              developer.log(
                'Ignoring STOPPED state before enableVideo operation completes',
                name: 'AgoraService',
              );
            }
          }
        },
      ),
    );

    // Profile/role are enforced as broadcaster for this app model.
    try {
      await _engine.setChannelProfile(
        ChannelProfileType.channelProfileLiveBroadcasting,
      );
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      developer.log(
        'AGORA ROLE: broadcaster (we always join as broadcaster)',
        name: 'AgoraService',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Agora channelProfile/clientRole setup skipped during initialize',
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
  Future<void> joinRoom(
    String token,
    String channelName,
    int uid, {
    bool publishCameraTrackOnJoin = true,
    bool publishMicrophoneTrackOnJoin = true,
  }) async {
    if (!_initialized) {
      throw StateError(
        'Agora engine must be initialized before joining a channel.',
      );
    }

    final normalizedToken = token.trim();
    final normalizedChannelName = channelName.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError('Agora token cannot be empty.');
    }
    if (normalizedChannelName.isEmpty) {
      throw ArgumentError('Agora channelName cannot be empty.');
    }

    final shouldPublishCamera = publishCameraTrackOnJoin;
    final shouldPublishMicrophone = publishMicrophoneTrackOnJoin;

    try {
      await _engine.setChannelProfile(
        ChannelProfileType.channelProfileLiveBroadcasting,
      );
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      developer.log(
        'AGORA ROLE: broadcaster (we always join as broadcaster)',
        name: 'AgoraService',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Agora channelProfile/clientRole before join failed',
        name: 'AgoraService',
        error: error,
        stackTrace: stackTrace,
      );
      _throwMappedAgoraError(error, operation: 'set client role');
    }

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

    try {
      await _engine.joinChannel(
        token: normalizedToken,
        channelId: normalizedChannelName,
        uid: uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: shouldPublishCamera,
          publishMicrophoneTrack: shouldPublishMicrophone,
        ),
      );
      if (shouldPublishCamera) {
        await _ensurePublishPipelineAfterRoleUpgrade(
          publishAudio: shouldPublishMicrophone,
        );
      }
    } catch (error) {
      _throwMappedAgoraError(error, operation: 'join room');
    }

    _joinedChannel = true;
    _broadcasterMode = true;
  }

  /// Join a video channel
  Future<void> joinChannel(
    String token,
    String channelName,
    int uid, {
    bool publishCameraTrackOnJoin = true,
    bool publishMicrophoneTrackOnJoin = true,
  }) async {
    await joinRoom(
      token,
      channelName,
      uid,
      publishCameraTrackOnJoin: publishCameraTrackOnJoin,
      publishMicrophoneTrackOnJoin: publishMicrophoneTrackOnJoin,
    );
  }

  Future<void> setBroadcaster(bool enabled) async {
    if (!_initialized) {
      developer.log(
        'setBroadcaster called but service not initialized',
        name: 'AgoraService',
      );
      return;
    }
    try {
      developer.log(
        'Setting client role to ${enabled ? "broadcaster" : "audience"}',
        name: 'AgoraService',
      );
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      _broadcasterMode = true;
      developer.log('Client role changed successfully', name: 'AgoraService');
    } catch (error) {
      developer.log(
        'Error setting client role: $error',
        name: 'AgoraService',
        error: error,
      );
      _throwMappedAgoraError(error, operation: 'switch role');
    }
  }

  /// On web, role-switching alone does not reliably renegotiate the WebRTC
  /// publish track. This method leaves and rejoins the channel as broadcaster
  /// so the browser negotiates a fresh publish path.
  Future<void> rejoinAsBroadcaster(
    String token,
    String channelName,
    int uid, {
    bool publishMicrophoneTrack = false,
  }) async {
    if (!_initialized) return;
    developer.log(
      'rejoinAsBroadcaster: leaving channel to force publish track renegotiation',
      name: 'AgoraService',
    );
    // --- leave (full cleanup via existing method) ---
    try {
      await leaveChannel();
    } catch (e) {
      developer.log(
        'rejoinAsBroadcaster: leaveChannel error (ignored): $e',
        name: 'AgoraService',
      );
    }
    // Give web runtimes a short moment to fully release previous tracks.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    // --- re‑enable video engine before join ---
    try {
      await _engine.enableVideo();
    } catch (_) {}

    // --- rejoin as broadcaster ---
    try {
      developer.log(
        'AGORA ROLE: broadcaster (we always join as broadcaster)',
        name: 'AgoraService',
      );
      await _engine.setChannelProfile(
        ChannelProfileType.channelProfileLiveBroadcasting,
      );
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.joinChannel(
        token: token.trim(),
        channelId: channelName.trim(),
        uid: uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: publishMicrophoneTrack,
        ),
      );
      await _engine.enableVideo();
      await _ensurePublishPipelineAfterRoleUpgrade(
        publishAudio: publishMicrophoneTrack,
      );
      _enableVideoInFlight = true;
      try {
        await _awaitLocalVideoCapturing();
      } finally {
        _enableVideoInFlight = false;
      }
      if (!_localVideoCapturing && kIsWeb) {
        _localVideoCapturing = true;
      }
    } catch (error) {
      _throwMappedAgoraError(error, operation: 'rejoin as broadcaster');
    }

    _joinedChannel = true;
    _broadcasterMode = true;
    developer.log(
      'rejoinAsBroadcaster: successfully rejoined as broadcaster',
      name: 'AgoraService',
    );
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
    if (!_initialized) {
      developer.log(
        'enableVideo called but service not initialized',
        name: 'AgoraService',
      );
      return;
    }
    developer.log('enableVideo($enabled) - started', name: 'AgoraService');
    _enableVideoInFlight = true;
    try {
      if (enabled) {
        if (!_broadcasterMode) {
          developer.log(
            'Setting client role to broadcaster',
            name: 'AgoraService',
          );
          await _engine.setClientRole(
            role: ClientRoleType.clientRoleBroadcaster,
          );
          _broadcasterMode = true;
        }
        developer.log('Enabling video engine', name: 'AgoraService');
        await _engine.enableVideo();
        await _engine.enableLocalVideo(true);
        await _engine.muteLocalVideoStream(false);
        try {
          await _engine.startPreview();
        } catch (_) {
          // Best effort on web/native combinations.
        }
        if (_joinedChannel) {
          developer.log(
            'Updating channel media options for video publishing',
            name: 'AgoraService',
          );
          await _engine.updateChannelMediaOptions(
            ChannelMediaOptions(
              channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
              clientRoleType: ClientRoleType.clientRoleBroadcaster,
              autoSubscribeAudio: true,
              autoSubscribeVideo: true,
              publishCameraTrack: true,
              publishMicrophoneTrack: true,
            ),
          );
        }
        developer.log(
          'Awaiting local video capturing...',
          name: 'AgoraService',
        );
        await _awaitLocalVideoCapturing();
        if (!_localVideoCapturing && kIsWeb) {
          // Web runtimes may miss local video state callbacks; keep UI in sync.
          _localVideoCapturing = true;
          developer.log(
            'Applying web fallback: local video marked capturing after successful enable flow',
            name: 'AgoraService',
          );
        }
        developer.log(
          'enableVideo($enabled) - completed successfully',
          name: 'AgoraService',
        );
      } else {
        await _engine.disableVideo();
        developer.log('Disabling video', name: 'AgoraService');
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
        developer.log('enableVideo(false) - completed', name: 'AgoraService');
      }
    } catch (error) {
      developer.log(
        'enableVideo($enabled) - failed: $error',
        name: 'AgoraService',
        error: error,
      );
      if (error is AgoraServiceException) {
        rethrow;
      }
      _throwMappedAgoraError(error, operation: 'toggle camera');
    } finally {
      _enableVideoInFlight = false;
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
