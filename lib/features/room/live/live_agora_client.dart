import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'live_room_schema.dart';
import '../../../core/platform/web_platform_view_helper.dart';
import '../../../services/agora/agora_platform_service.dart';
import '../../../services/agora/agora_stub.dart'
  if (dart.library.io) '../../../services/agora/agora_native.dart';

// Web stub for AgoraWebBridgeV3
// ignore: camel_case_types, non_constant_identifier_names
class AgoraWebBridgeV3 {
  static Future<void> startAudioMixing(String url, bool looping) async {}
  static Future<void> stopAudioMixing() async {}
  static Future<void> pauseAudioMixing() async {}
  static Future<void> resumeAudioMixing() async {}
  static Future<void> setAudioMixingVolume(int volume) async {}
}

// ── Events emitted to the controller ──────────────────────────────────────

sealed class VideoEngineEvent {
  const VideoEngineEvent();
}

final class EngineJoinedEvent extends VideoEngineEvent {
  final int localUid;
  const EngineJoinedEvent(this.localUid);
}

final class EngineLeftEvent extends VideoEngineEvent {
  const EngineLeftEvent();
}

final class RemoteUserJoinedEvent extends VideoEngineEvent {
  final int remoteUid;
  const RemoteUserJoinedEvent(this.remoteUid);
}

final class RemoteUserLeftEvent extends VideoEngineEvent {
  final int remoteUid;
  const RemoteUserLeftEvent(this.remoteUid);
}

final class RemoteVideoToggleEvent extends VideoEngineEvent {
  final int remoteUid;
  final bool hasVideo;
  const RemoteVideoToggleEvent(this.remoteUid, this.hasVideo);
}

final class ActiveSpeakerEvent extends VideoEngineEvent {
  final int? speakerUid;
  const ActiveSpeakerEvent(this.speakerUid);
}

final class EngineErrorEvent extends VideoEngineEvent {
  final String message;
  const EngineErrorEvent(this.message);
}

final class EngineConnectionStateEvent extends VideoEngineEvent {
  final ConnectionStateType state;
  final ConnectionChangedReasonType reason;
  const EngineConnectionStateEvent(this.state, this.reason);
}

final class AudioMixingStateEvent extends VideoEngineEvent {
  final AudioMixingStateType mixingState;
  final AudioMixingReasonType reason;
  const AudioMixingStateEvent(this.mixingState, this.reason);
}

// ── Client ─────────────────────────────────────────────────────────────────

class LiveAgoraClient {
  LiveAgoraClient({required this.roomType});

  final String roomType;

  // ── State ─────────────────────────────────────────────────────────────────
  RtcEngine? _engine;
  bool    _initialized      = false;
  bool    _inChannel        = false;
  String? _channelId;
  int?    _localUid;
  bool    _publishingVideo  = false;
  bool    _publishingAudio  = false;

  /// Uids currently in the video channel (not necessarily subscribed).
  final Set<int> _channelUids    = {};
  /// Uids we are actively receiving video from.
  final Set<int> _subscribedUids = {};

  /// Hard cap: subscribe to at most this many tiles simultaneously.
  static const int _maxTileSubscriptions = 8;

  final _events = StreamController<VideoEngineEvent>.broadcast();

  // ── Public getters ────────────────────────────────────────────────────────

  Stream<VideoEngineEvent> get events        => _events.stream;
  bool       get isInitialized  => _initialized;
  bool       get isInChannel    => _inChannel;
  int?       get localUid       => _localUid;
  String?    get channelId      => _channelId;
  Set<int>   get channelUids    => Set.unmodifiable(_channelUids);
  Set<int>   get subscribedUids => Set.unmodifiable(_subscribedUids);
  /// Exposes the underlying engine for video rendering widgets.
  RtcEngine? get engine         => kIsWeb ? null : _engine;

  // ── Initialize ────────────────────────────────────────────────────────────

  /// Loads App ID from Firestore, initialises native engine and encoder config.
  /// Returns the Agora App ID for reference.
  Future<String> initialize() async {
    if (_initialized) return _loadAppId();

    final appId = await _loadAppId();

    if (!kIsWeb) {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Low-bitrate video encoder profile for group rooms
      await _engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: _dimensions(),
          frameRate:  15,
          bitrate:    _bitrate(),
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainFramerate,
        ),
      );

      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
      );

      // Speaking detection — 500 ms interval
      await _engine!.enableAudioVolumeIndication(
        interval: 500,
        smooth: 3,
        reportVad: false,
      );

      _registerEventHandlers();
    }

    _initialized = true;
    return appId;
  }

  // ── Join channel ──────────────────────────────────────────────────────────

  Future<void> joinChannel({
    required String channelId,
    required String userId,
    required bool   isBroadcaster,
  }) async {
    if (!_initialized) throw StateError('Call initialize() first.');
    if (_inChannel) return;

    final auth = await _fetchToken(channelId: channelId, userId: userId);
    final token = auth.token;
    final agoraUid = auth.uid;
    _channelId = channelId;

    if (kIsWeb) {
      // Web path: actually initialize+join via the platform bridge.
      debugPrint('[VIDEO_ENGINE] Web join — using web bridge');
      final appId = await _loadAppId();

      final webInitialized = await AgoraPlatformService.initializeWeb(appId);
      if (!webInitialized) {
        final bridgeState = AgoraPlatformService.getWebBridgeState();
        throw Exception('Web bridge failed to initialize. state=$bridgeState');
      }

      final joined = await AgoraPlatformService.joinChannel(
        appId: appId,
        channelName: channelId,
        token: token,
        uid: agoraUid.toString(),
      );
      if (!joined) {
        final bridgeState = AgoraPlatformService.getWebBridgeState();
        throw Exception(
          'Web bridge failed to join channel. channel=$channelId uid=$agoraUid state=$bridgeState',
        );
      }
      _inChannel = true;
      _localUid = agoraUid;
      debugPrint('[VIDEO_ENGINE-WEB] joinChannel done: agoraUid=$agoraUid \u2014 emitting EngineJoinedEvent (triggers Firestore agoraUid write)');
      _emit(EngineJoinedEvent(agoraUid));

      // Register JS→Dart callback for remote user publish events (diagnostic)
      _registerWebRemoteUserCallback();
      return;
    }

    final role = isBroadcaster
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: role);

    // Start with local media disabled — only enable on explicit request
    await _engine!.enableLocalVideo(false);
    await _engine!.enableLocalAudio(false);

    await _engine!.joinChannel(
      token:     token,
      channelId: channelId,
      uid:       agoraUid,
      options:   ChannelMediaOptions(
        channelProfile:       ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType:       role,
        publishCameraTrack:    false,
        publishMicrophoneTrack: false,
        autoSubscribeVideo:   false, // ← never auto-subscribe
        autoSubscribeAudio:   false, // ← never auto-subscribe
        enableAudioRecordingOrPlayout: true,
      ),
    );
    // _inChannel set to true inside onJoinChannelSuccess
  }

  // ── Leave channel ─────────────────────────────────────────────────────────

  Future<void> leaveChannel() async {
    if (!_inChannel) return;
    if (kIsWeb) {
      await AgoraPlatformService.leaveChannel();
      _inChannel = false;
      _localUid = null;
      _channelUids.clear();
      _subscribedUids.clear();
      _publishingVideo = false;
      _publishingAudio = false;
      _emit(const EngineLeftEvent());
      return;
    }
    await _engine?.leaveChannel();
  }

  // ── Visibility-based subscription ─────────────────────────────────────────

  /// Primary subscription API — call whenever the set of visible tiles changes
  /// (scroll, layout change, backgrounding/foregrounding, etc.).
  ///
  /// Subscribes to newly visible uids, unsubscribes from off-screen ones.
  /// Hard-capped at [_maxTileSubscriptions].
  Future<void> setVisibleUids(List<int> visibleUids) async {
    if (!_inChannel || kIsWeb) return;

    final target       = visibleUids.take(_maxTileSubscriptions).toSet();
    final toSubscribe   = target.difference(_subscribedUids);
    final toUnsubscribe = _subscribedUids.difference(target);

    for (final uid in toUnsubscribe) {
      await _muteRemoteVideo(uid, mute: true);
      await _muteRemoteAudio(uid, mute: true);
      _subscribedUids.remove(uid);
    }

    for (final uid in toSubscribe) {
      if (_channelUids.contains(uid)) {
        await _muteRemoteVideo(uid, mute: false);
        await _muteRemoteAudio(uid, mute: false);
        _subscribedUids.add(uid);
      }
    }
  }

  /// Drop every active subscription without leaving the channel.
  /// Used when the app is backgrounded.
  Future<void> dropAllSubscriptions() async {
    if (!_inChannel || kIsWeb) return;
    for (final uid in List<int>.from(_subscribedUids)) {
      await _muteRemoteVideo(uid, mute: true);
      await _muteRemoteAudio(uid, mute: true);
    }
    _subscribedUids.clear();
  }

  // ── Publishing ─────────────────────────────────────────────────────────────

  Future<void> startPublishingVideo() async {
    if (_publishingVideo || !_inChannel) return;
    if (kIsWeb) {
      debugPrint('[VIDEO_ENGINE-WEB] startPublishingVideo: calling AgoraPlatformService.setVideoMuted(false)');
      final appId = await _loadAppId();
      final webInitialized = await AgoraPlatformService.initializeWeb(appId);
      if (!webInitialized) {
        final bridgeState = AgoraPlatformService.getWebBridgeState();
        throw Exception('Web bridge failed to initialize before video publish. state=$bridgeState');
      }
      final videoEnabled = await AgoraPlatformService.setVideoMuted(false);
      debugPrint('[VIDEO_ENGINE-WEB] startPublishingVideo: setVideoMuted(false) → $videoEnabled');
      if (!videoEnabled) {
        final bridgeState = AgoraPlatformService.getWebBridgeState();
        throw Exception(
          'Web camera permission denied or unavailable. Please allow camera access in the browser and retry. state=$bridgeState',
        );
      }
      _publishingVideo = true;
      debugPrint('[VIDEO_ENGINE-WEB] startPublishingVideo: done, _publishingVideo=true');
      return;
    }
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.enableLocalVideo(true);
    await _engine?.muteLocalVideoStream(false);
    await _engine?.updateChannelMediaOptions(
      const ChannelMediaOptions(publishCameraTrack: true),
    );
    _publishingVideo = true;
  }

  Future<void> stopPublishingVideo() async {
    if (!_publishingVideo) return;
    if (kIsWeb) {
      await AgoraPlatformService.setVideoMuted(true);
      _publishingVideo = false;
      return;
    }
    await _engine?.muteLocalVideoStream(true);
    await _engine?.enableLocalVideo(false);
    await _engine?.updateChannelMediaOptions(
      const ChannelMediaOptions(publishCameraTrack: false),
    );
    _publishingVideo = false;
    if (!_publishingAudio) {
      await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
  }

  Future<void> startPublishingAudio() async {
    if (_publishingAudio || !_inChannel) return;
    if (kIsWeb) {
      final micEnabled = await AgoraPlatformService.setMicMuted(false);
      if (!micEnabled) {
        final bridgeState = AgoraPlatformService.getWebBridgeState();
        throw Exception(
          'Web microphone permission denied or unavailable. Please allow microphone access in the browser and retry. state=$bridgeState',
        );
      }
      _publishingAudio = true;
      return;
    }
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.enableLocalAudio(true);
    await _engine?.muteLocalAudioStream(false);
    await _engine?.updateChannelMediaOptions(
      const ChannelMediaOptions(publishMicrophoneTrack: true),
    );
    _publishingAudio = true;
  }

  Future<void> stopPublishingAudio() async {
    if (!_publishingAudio) return;
    if (kIsWeb) {
      await AgoraPlatformService.setMicMuted(true);
      _publishingAudio = false;
      return;
    }
    await _engine?.muteLocalAudioStream(true);
    await _engine?.enableLocalAudio(false);
    await _engine?.updateChannelMediaOptions(
      const ChannelMediaOptions(publishMicrophoneTrack: false),
    );
    _publishingAudio = false;
    if (!_publishingVideo) {
      await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
  }

  /// Drop all publishing without leaving the channel (background state).
  Future<void> dropPublishing() async {
    await stopPublishingVideo();
    await stopPublishingAudio();
  }

  // ── DJ Audio Mixing ──────────────────────────────────────────────────

  Future<void> startAudioMixing(String url, {bool looping = false}) async {
    if (kIsWeb) {
      await AgoraWebBridgeV3.startAudioMixing(url, looping);
      return;
    }
    if (_engine == null) return;
    await _engine!.startAudioMixing(
      filePath: url,
      loopback: false,
      cycle: looping ? -1 : 1,
      startPos: 0,
    );
  }

  Future<void> stopAudioMixing() async {
    if (kIsWeb) { await AgoraWebBridgeV3.stopAudioMixing(); return; }
    if (_engine == null) return;
    await _engine!.stopAudioMixing();
  }

  Future<void> pauseAudioMixing() async {
    if (kIsWeb) { await AgoraWebBridgeV3.pauseAudioMixing(); return; }
    if (_engine == null) return;
    await _engine!.pauseAudioMixing();
  }

  Future<void> resumeAudioMixing() async {
    if (kIsWeb) { await AgoraWebBridgeV3.resumeAudioMixing(); return; }
    if (_engine == null) return;
    await _engine!.resumeAudioMixing();
  }

  Future<void> setAudioMixingVolume(int volume) async {
    if (kIsWeb) { await AgoraWebBridgeV3.setAudioMixingVolume(volume); return; }
    if (_engine == null) return;
    await _engine!.adjustAudioMixingVolume(volume);
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    if (_inChannel) await leaveChannel();
    _events.close();
    if (!kIsWeb) {
      await _engine?.release();
      _engine = null;
    }
    _initialized = false;
  }

  // ── Web diagnostic callback ───────────────────────────────────────────────

  /// Registers window.agoraWeb.onRemoteUserPublished so JS can notify Dart
  /// when user-published fires.  Pure diagnostic — does not change state.
  void _registerWebRemoteUserCallback() {
    if (!kIsWeb) return;
    try {
      AgoraPlatformService.registerRemotePublishedCallback((uid, mediaType) {
        debugPrint('[VIDEO_ENGINE-WEB] ★ JS user-published callback: uid=$uid mediaType=$mediaType');
        final parsedUid = int.tryParse(uid);
        if (parsedUid != null && parsedUid != 0) {
          _channelUids.add(parsedUid);
          if (mediaType == 'video') {
            _emit(RemoteUserJoinedEvent(parsedUid));
            // ~300ms optimisation: pre-register the platform view factory as
            // soon as the Agora network delivers user-published — before Firestore
            // propagates the remote participant's agoraUid.  When
            // _WebRemoteVideoView mounts (Firestore-gated), its registerVideoViewFactory
            // call becomes a no-op and the HtmlElementView creates the element
            // instantly.  The speculative playRemoteVideo call resolves in <1
            // retry if the element already exists (Firestore was fast); otherwise
            // the widget's own retry loop picks it up within 250 ms.
            final elementId = 'mm_remote_video_el_$parsedUid';
            registerVideoViewFactory('mm_remote_video_view_$parsedUid', elementId);
            AgoraPlatformService.playRemoteVideo(uid, elementId);
          }
        }
      });
      debugPrint('[VIDEO_ENGINE-WEB] onRemoteUserPublished callback registered');
    } catch (e) {
      debugPrint('[VIDEO_ENGINE-WEB] Could not register onRemoteUserPublished: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _muteRemoteVideo(int uid, {required bool mute}) async {
    try {
      await _engine?.muteRemoteVideoStream(uid: uid, mute: mute);
    } catch (e) {
      debugPrint('[VIDEO_ENGINE] muteRemoteVideo($uid, $mute): $e');
    }
  }

  Future<void> _muteRemoteAudio(int uid, {required bool mute}) async {
    try {
      await _engine?.muteRemoteAudioStream(uid: uid, mute: mute);
    } catch (e) {
      debugPrint('[VIDEO_ENGINE] muteRemoteAudio($uid, $mute): $e');
    }
  }

  void _emit(VideoEngineEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  // ── Native event handlers ─────────────────────────────────────────────────

  void _registerEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
          _localUid  = conn.localUid;
          _inChannel = true;
          debugPrint('[VIDEO_ENGINE] Joined channel ${conn.channelId} uid=$_localUid');
          _emit(EngineJoinedEvent(_localUid!));
        },
        onLeaveChannel: (RtcConnection conn, RtcStats stats) {
          debugPrint('[VIDEO_ENGINE] Left channel');
          _inChannel       = false;
          _localUid        = null;
          _channelUids.clear();
          _subscribedUids.clear();
          _publishingVideo = false;
          _publishingAudio = false;
          _emit(const EngineLeftEvent());
        },
        onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
          debugPrint('[VIDEO_ENGINE] Remote user joined: $remoteUid');
          _channelUids.add(remoteUid);
          _emit(RemoteUserJoinedEvent(remoteUid));
          // Do NOT subscribe here — only setVisibleUids() triggers subscriptions
        },
        onUserOffline: (
          RtcConnection conn,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          debugPrint('[VIDEO_ENGINE] Remote user left: $remoteUid');
          _channelUids.remove(remoteUid);
          _subscribedUids.remove(remoteUid);
          _emit(RemoteUserLeftEvent(remoteUid));
        },
        onRemoteVideoStateChanged: (
          RtcConnection conn,
          int remoteUid,
          RemoteVideoState state,
          RemoteVideoStateReason reason,
          int elapsed,
        ) {
          final hasVideo = state == RemoteVideoState.remoteVideoStateDecoding ||
              state == RemoteVideoState.remoteVideoStateStarting;
          _emit(RemoteVideoToggleEvent(remoteUid, hasVideo));
        },
        onActiveSpeaker: (RtcConnection conn, int uid) {
          _emit(ActiveSpeakerEvent(uid == 0 ? null : uid));
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[VIDEO_ENGINE] Error $err: $msg');
          _emit(EngineErrorEvent('$err: $msg'));
        },
        onConnectionStateChanged: (
          RtcConnection conn,
          ConnectionStateType state,
          ConnectionChangedReasonType reason,
        ) {
          debugPrint('[VIDEO_ENGINE] Connection state: $state reason=$reason');
          _emit(EngineConnectionStateEvent(state, reason));
        },
        onAudioMixingStateChanged: (AudioMixingStateType state, AudioMixingReasonType reason) {
          _emit(AudioMixingStateEvent(state, reason));
        },
      ),
    );
  }

  // ── App ID / Token ────────────────────────────────────────────────────────

  String? _cachedAppId;

  Future<String> _loadAppId() async {
    if (_cachedAppId != null) return _cachedAppId!;
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('agora')
        .get();
    final id = doc.data()?['appId'] as String?;
    if (id == null || id.isEmpty) {
      throw Exception('Agora App ID not found in Firestore config/agora.');
    }
    _cachedAppId = id;
    return id;
  }

  Future<({String token, int uid})> _fetchToken({
    required String channelId,
    required String userId,
  }) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('generateAgoraToken')
            .call({'roomId': channelId, 'userId': userId});
        final payload = result.data as Map<String, dynamic>;
        final token = payload['token'] as String?;
        final uidRaw = payload['uid'];
        final normalized = token?.trim() ?? '';
        final uid = uidRaw is int
            ? uidRaw
            : uidRaw is String
                ? int.tryParse(uidRaw)
                : null;

        if (normalized.isNotEmpty && uid != null && uid > 0) {
          return (token: normalized, uid: uid);
        }

        if (attempt == 1) {
          // A short retry smooths over transient rollout/cold-start edge cases.
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        throw Exception('generateAgoraToken returned invalid token/uid after retry.');
      } on FirebaseFunctionsException catch (e) {
        final details = e.details == null ? '' : ' (${e.details})';
        throw Exception('generateAgoraToken failed [${e.code}]: ${e.message ?? 'Unknown backend error'}$details');
      }
    }

    throw Exception('generateAgoraToken failed after retry.');
  }

  // ── Encoder quality helpers ───────────────────────────────────────────────

  VideoDimensions _dimensions() {
    switch (roomType) {
      case RoomType.broadcast:
      case RoomType.concert:
        return const VideoDimensions(width: 640, height: 360);  // 360p
      default:
        return const VideoDimensions(width: 320, height: 240);  // 240p (group)
    }
  }

  int _bitrate() {
    switch (roomType) {
      case RoomType.broadcast:
      case RoomType.concert:
        return 600;   // kbps — 360p
      default:
        return 300;   // kbps — 240p, cost-optimised for group rooms
    }
  }
}
