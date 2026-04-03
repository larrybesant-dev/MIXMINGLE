// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'agora_service.dart' show AgoraServiceException;
import 'rtc_room_service.dart';

/// Browser-native WebRTC room service using Firestore for signaling.
///
/// Replaces [AgoraService] on web to eliminate the Agora WASM cold-start
/// (which can time out on Chrome). Uses [RTCPeerConnection] from the
/// browser's built-in WebRTC engine — no external SDK download required.
///
/// ### P2P Architecture
/// Every room member creates a **receive-only** [RTCPeerConnection] to each
/// active broadcaster. Broadcasters respond with an answer that sends their
/// camera/mic stream through those connections.
///
/// ```
/// Viewer V  ──offer(recvonly)──►  Broadcaster B
///              ◄──answer(sendonly)──
///              ◄══stream══════════
/// ```
///
/// Broadcaster-to-broadcaster is the same pattern: each broadcaster creates
/// a receive-only connection to every *other* broadcaster, so they all see
/// each other's cameras (full mesh, two one-directional edges per pair).
///
/// ### Signaling (Firestore paths)
/// ```
/// rooms/{roomId}/webrtc_peers/{userId}
///   { isBroadcasting, uid, joinedAt }
///
/// rooms/{roomId}/webrtc_calls/{viewerId}_{broadcasterId}
///   { viewerId, broadcasterId, viewerUid, broadcasterUid,
///     offer: {sdp, type}, answer: {sdp, type}, createdAt }
///   /viewer_ice/{docId}   { candidate, sdpMid, sdpMLineIndex }
///   /broadcaster_ice/{docId}  { … }
/// ```
class WebRtcRoomService implements RtcRoomService {
  WebRtcRoomService({
    required FirebaseFirestore firestore,
    required String localUserId,
  })  : _firestore = firestore,
        _localUserId = localUserId;

  final FirebaseFirestore _firestore;
  final String _localUserId;

  // ──────────────────────────────────────────────────────────────────────────
  // State
  // ──────────────────────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _isJoined = false;
  bool _broadcasterMode = false;
  bool _localVideoCapturing = false;
  String? _roomId;
  int? _localUid;

  // ──────────────────────────────────────────────────────────────────────────
  // Local media
  // ──────────────────────────────────────────────────────────────────────────
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _localRendererReady = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Remote peers  (keyed by remote broadcaster's userId)
  // ──────────────────────────────────────────────────────────────────────────
  final Map<String, _PeerEntry> _peers = {};

  // Two-way UID↔userId maps so the screen can use int UIDs
  final Map<int, String> _uidToUserId = {};
  final Map<String, int> _userIdToUid = {};

  // ──────────────────────────────────────────────────────────────────────────
  // Firestore listeners
  // ──────────────────────────────────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _presenceSub;
  StreamSubscription<QuerySnapshot>? _incomingCallsSub;
  // Track which call docs we have already *answered* to avoid double-processing
  final Set<String> _answeredCalls = {};

  // ──────────────────────────────────────────────────────────────────────────
  // RtcRoomService callbacks
  // ──────────────────────────────────────────────────────────────────────────
  @override VoidCallback? onRemoteUserJoined;
  @override VoidCallback? onRemoteUserLeft;
  @override VoidCallback? onSpeakerActivityChanged;
  @override VoidCallback? onLocalVideoCaptureChanged;
  @override VoidCallback? onTokenWillExpire;
  @override VoidCallback? onConnectionLost;

  // ──────────────────────────────────────────────────────────────────────────
  // RtcRoomService: state getters
  // ──────────────────────────────────────────────────────────────────────────
  @override
  List<int> get remoteUids => _uidToUserId.keys.toList();

  @override
  bool get localSpeaking => false; // TODO: Web AudioContext VAD

  @override
  bool get canRenderLocalView =>
      _initialized && _isJoined && _broadcasterMode && _localVideoCapturing;

  @override
  bool get isBroadcaster => _broadcasterMode;

  @override
  bool get isJoinedChannel => _isJoined;

  @override
  bool get isLocalVideoCapturing => _localVideoCapturing;

  @override
  bool isRemoteSpeaking(int uid) => false; // TODO: Web AudioContext VAD

  // ──────────────────────────────────────────────────────────────────────────
  // RtcRoomService: video views
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget getLocalView() {
    if (!canRenderLocalView || !_localRendererReady) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.videocam_off, size: 36)),
      );
    }
    return RTCVideoView(_localRenderer, mirror: true);
  }

  @override
  Widget getRemoteView(int uid, String channelId) {
    final userId = _uidToUserId[uid];
    if (userId == null) {
      return const ColoredBox(color: Colors.black12);
    }
    final peer = _peers[userId];
    if (peer == null || !peer.rendererReady || peer.remoteStream == null) {
      return const ColoredBox(color: Colors.black12);
    }
    return RTCVideoView(peer.renderer);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RtcRoomService: lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// No WASM to load — initialises the local video renderer instantly.
  @override
  Future<void> initialize(String appId) async {
    if (!_localRendererReady) {
      await _localRenderer.initialize();
      _localRendererReady = true;
    }
    _initialized = true;
    _log('initialized (native WebRTC, no WASM)');
  }

  /// Joins the WebRTC mesh for [channelName] (= roomId).
  /// [token] is ignored; Firestore handles signaling.
  /// [uid] is stored as the local integer UID for API compatibility.
  @override
  Future<void> joinRoom(
    String token,
    String channelName,
    int uid, {
    bool publishCameraTrackOnJoin = false,
    bool publishMicrophoneTrackOnJoin = false,
  }) async {
    if (!_initialized) throw StateError('WebRtcRoomService not initialized');
    _roomId = channelName;
    _localUid = uid;
    _uidToUserId[uid] = _localUserId;
    _userIdToUid[_localUserId] = uid;
    _isJoined = true;

    // Announce presence (not broadcasting yet)
    await _peersCol.doc(_localUserId).set({
      'uid': uid,
      'isBroadcasting': false,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Watch who is broadcasting — create/close viewer connections as needed
    _presenceSub = _peersCol
        .where('isBroadcasting', isEqualTo: true)
        .snapshots()
        .listen(_onPresenceChanged, onError: _onListenerError);

    // Watch for viewers creating offers addressed to us; answer them
    _incomingCallsSub = _callsCol
        .where('broadcasterId', isEqualTo: _localUserId)
        .snapshots()
        .listen(_onIncomingCalls, onError: _onListenerError);

    _log('joined roomId=$channelName uid=$uid');
  }

  @override
  Future<void> enableVideo(
    bool enabled, {
    bool publishMicrophoneTrack = true,
  }) async {
    if (!_initialized || !_isJoined) return;

    if (enabled) {
      if (_broadcasterMode && _localVideoCapturing) return;

      try {
        final stream = await navigator.mediaDevices.getUserMedia({
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 640},
            'height': {'ideal': 480},
          },
          // Always acquire audio alongside video so the mic toggle works
          // without a separate getUserMedia call. The track starts muted
          // if the user's mic is currently off.
          'audio': true,
        });

        // Mute audio immediately if mic is off — track exists but silent
        if (!publishMicrophoneTrack) {
          for (final track in stream.getAudioTracks()) {
            track.enabled = false;
          }
        }

        _localStream = stream;
        _localRenderer.srcObject = stream;
        _broadcasterMode = true;
        _localVideoCapturing = true;

        // Announce that we are now broadcasting
        await _updatePresence(isBroadcasting: true);

        // Process any offers from viewers that arrived before we went live
        await _processExistingIncomingCalls();

        onLocalVideoCaptureChanged?.call();
        _log('camera enabled — broadcasting (audio track muted=${ !publishMicrophoneTrack})');
      } catch (error) {
        _localVideoCapturing = false;
        _broadcasterMode = false;
        _throwMapped(error, 'enable camera');
      }
    } else {
      await _stopLocalStream();
      _localVideoCapturing = false;
      _broadcasterMode = false;
      await _updatePresence(isBroadcasting: false);
      onLocalVideoCaptureChanged?.call();
      _log('camera disabled');
    }
  }

  @override
  Future<void> mute(bool muted) async {
    final stream = _localStream;
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
    _log('mute=$muted');
  }

  @override
  Future<void> setBroadcaster(bool enabled) async {
    // Called when user enables mic while camera is still off.
    if (enabled && _isJoined) {
      if (_localStream == null) {
        // Mic-only: acquire an audio-only stream so mute/publish work.
        try {
          final audioStream = await navigator.mediaDevices.getUserMedia({
            'video': false,
            'audio': true,
          });
          _localStream = audioStream;
          _log('setBroadcaster: acquired audio-only stream');
        } catch (error) {
          _throwMapped(error, 'access microphone');
        }
      }
      if (!_broadcasterMode) {
        _broadcasterMode = true;
        await _updatePresence(isBroadcasting: true);
        // Answer any pending viewer offers now that we have a stream.
        await _processExistingIncomingCalls();
      }
    } else if (!enabled) {
      _broadcasterMode = false;
      await _updatePresence(isBroadcasting: false);
    }
  }

  @override
  Future<void> publishLocalVideoStream(bool enabled) async {
    for (final track in (_localStream?.getVideoTracks() ?? [])) {
      track.enabled = enabled;
    }
  }

  @override
  Future<void> publishLocalAudioStream(bool enabled) async {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    if (audioTracks.isEmpty && enabled && _localStream != null) {
      // Stream exists (video-only) but has no audio track — add one.
      try {
        final audioStream = await navigator.mediaDevices.getUserMedia({
          'video': false,
          'audio': true,
        });
        for (final track in audioStream.getAudioTracks()) {
          await _localStream!.addTrack(track);
          // Also add to all active broadcaster peer connections.
          for (final peer in _peers.values) {
            try { await peer.pc.addTrack(track, _localStream!); } catch (_) {}
          }
        }
        _log('publishLocalAudioStream: injected audio track into existing stream');
      } catch (error) {
        _throwMapped(error, 'access microphone');
      }
    } else {
      for (final track in audioTracks) {
        track.enabled = enabled;
      }
    }
  }

  @override
  Future<void> setRemoteVideoSubscription(
    int uid, {
    required bool subscribe,
    bool highQuality = false,
  }) async {
    final userId = _uidToUserId[uid];
    if (userId == null) return;
    final peer = _peers[userId];
    if (peer?.remoteStream == null) return;
    for (final track in peer!.remoteStream!.getVideoTracks()) {
      track.enabled = subscribe;
    }
  }

  @override
  Future<void> renewToken(String newToken) async {
    // No-op: WebRTC peer connections do not use expiring tokens.
  }

  @override
  Future<void> ensureDeviceAccess({
    required bool video,
    required bool audio,
  }) async {
    MediaStream? probe;
    try {
      probe = await navigator.mediaDevices.getUserMedia({
        'video': video,
        'audio': audio,
      });
    } catch (error) {
      _throwMapped(error, video ? 'access camera' : 'access microphone');
    } finally {
      probe?.getTracks().forEach((t) => t.stop());
    }
  }

  @override
  Future<void> dispose() async {
    await _presenceSub?.cancel();
    await _incomingCallsSub?.cancel();
    _presenceSub = null;
    _incomingCallsSub = null;

    await _stopLocalStream();

    for (final peer in _peers.values) {
      await peer.dispose();
    }
    _peers.clear();
    _uidToUserId.clear();
    _userIdToUid.clear();
    _answeredCalls.clear();

    _localRenderer.srcObject = null;
    if (_localRendererReady) {
      await _localRenderer.dispose();
      _localRendererReady = false;
    }

    // Remove our WebRTC presence
    if (_roomId != null) {
      try {
        await _peersCol.doc(_localUserId).delete();
      } catch (_) {}
    }

    _isJoined = false;
    _broadcasterMode = false;
    _localVideoCapturing = false;
    _initialized = false;
    _log('disposed');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private: Firestore helpers
  // ──────────────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _peersCol =>
      _firestore.collection('rooms').doc(_roomId).collection('webrtc_peers');

  CollectionReference<Map<String, dynamic>> get _callsCol =>
      _firestore.collection('rooms').doc(_roomId).collection('webrtc_calls');

  Future<void> _updatePresence({required bool isBroadcasting}) async {
    if (_roomId == null) return;
    try {
      await _peersCol.doc(_localUserId).update({'isBroadcasting': isBroadcasting});
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private: signaling — viewer side (this user receives from a broadcaster)
  // ──────────────────────────────────────────────────────────────────────────

  void _onPresenceChanged(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      final remoteBroadcasterId = change.doc.id;
      if (remoteBroadcasterId == _localUserId) continue; // skip self

      final data = change.doc.data() as Map<String, dynamic>?;
      final remoteUid = (data?['uid'] as num?)?.toInt() ??
          (remoteBroadcasterId.hashCode.abs() % 2147483647);

      if (change.type == DocumentChangeType.removed) {
        _closePeer(remoteBroadcasterId);
        return;
      }

      final isBroadcasting = data?['isBroadcasting'] as bool? ?? false;
      if (isBroadcasting) {
        if (!_peers.containsKey(remoteBroadcasterId)) {
          _uidToUserId[remoteUid] = remoteBroadcasterId;
          _userIdToUid[remoteBroadcasterId] = remoteUid;
          _createViewerConnection(remoteBroadcasterId, remoteUid);
        }
      } else {
        _closePeer(remoteBroadcasterId);
      }
    }
  }

  /// Creates a receive-only peer connection to [broadcasterId] and sends
  /// them an offer via Firestore.
  Future<void> _createViewerConnection(
    String broadcasterId,
    int broadcasterUid,
  ) async {
    _log('creating viewer connection → broadcaster=$broadcasterId');

    final renderer = RTCVideoRenderer();
    await renderer.initialize();

    final pc = await createPeerConnection(_iceConfig);
    final peer = _PeerEntry(
      broadcasterId: broadcasterId,
      broadcasterUid: broadcasterUid,
      pc: pc,
      renderer: renderer,
    );
    _peers[broadcasterId] = peer;

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        peer.remoteStream = event.streams.first;
        renderer.srcObject = event.streams.first;
        _log('remote stream received from broadcaster=$broadcasterId');
        onRemoteUserJoined?.call();
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      _log('connection to $broadcasterId state=$state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _closePeer(broadcasterId);
      }
    };

    // Receive-only transceivers — we only want the broadcaster's stream
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    final callId = '${_localUserId}_$broadcasterId';
    final callRef = _callsCol.doc(callId);

    // Gather ICE candidates and write them to Firestore
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate?.isNotEmpty == true) {
        callRef.collection('viewer_ice').add(candidate.toMap());
      }
    };

    // Write offer to Firestore to trigger the broadcaster
    await callRef.set({
      'viewerId': _localUserId,
      'broadcasterId': broadcasterId,
      'viewerUid': _localUid,
      'broadcasterUid': broadcasterUid,
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Wait for broadcaster's answer
    peer.answerSub = callRef.snapshots().listen((snap) async {
      if (!snap.exists) return;
      final callData = snap.data() as Map<String, dynamic>?;
      final answerMap = callData?['answer'] as Map<String, dynamic>?;
      if (answerMap == null) return;
      if (pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        try {
          await pc.setRemoteDescription(
            RTCSessionDescription(
              answerMap['sdp'] as String,
              answerMap['type'] as String,
            ),
          );
          _log('set remote answer from broadcaster=$broadcasterId');
        } catch (e) {
          _log('setRemoteDescription failed for broadcaster=$broadcasterId: $e');
        }
      }
    });

    // Receive broadcaster's ICE candidates
    peer.iceSub = callRef.collection('broadcaster_ice').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data() as Map<String, dynamic>?;
          if (d == null) continue;
          pc.addCandidate(RTCIceCandidate(
            d['candidate'] as String?,
            d['sdpMid'] as String?,
            (d['sdpMLineIndex'] as num?)?.toInt(),
          ));
        }
      }
    });

    _log('offer sent for callId=$callId');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private: signaling — broadcaster side (this user answers viewer offers)
  // ──────────────────────────────────────────────────────────────────────────

  void _onIncomingCalls(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final callId = change.doc.id;
      if (_answeredCalls.contains(callId)) continue;
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data?['offer'] == null) continue;
      if (data?['answer'] != null) continue; // already answered
      _answeredCalls.add(callId);
      _answerViewerOffer(callId, data!);
    }
  }

  /// Called when broadcaster goes live after some viewers have already created
  /// offers that were ignored (because _localStream was null at the time).
  Future<void> _processExistingIncomingCalls() async {
    if (_roomId == null) return;
    final snapshot = await _callsCol
        .where('broadcasterId', isEqualTo: _localUserId)
        .get();

    for (final doc in snapshot.docs) {
      final callId = doc.id;
      if (_answeredCalls.contains(callId)) continue;
      final data = doc.data();
      if (data['offer'] == null) continue;
      if (data['answer'] != null) continue; // already answered by another session
      _answeredCalls.add(callId);
      _answerViewerOffer(callId, data);
    }
  }

  Future<void> _answerViewerOffer(
    String callId,
    Map<String, dynamic> callData,
  ) async {
    final localStream = _localStream;
    if (localStream == null) {
      _log('ignoring offer callId=$callId — no local stream yet');
      return;
    }

    final viewerId = callData['viewerId'] as String?;
    _log('answering viewer offer callId=$callId viewer=$viewerId');

    final callRef = _callsCol.doc(callId);
    final pc = await createPeerConnection(_iceConfig);

    // Send our local tracks to this viewer
    for (final track in localStream.getTracks()) {
      await pc.addTrack(track, localStream);
    }

    // Gather broadcaster ICE candidates
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate?.isNotEmpty == true) {
        callRef.collection('broadcaster_ice').add(candidate.toMap());
      }
    };

    final offerMap = callData['offer'] as Map<String, dynamic>;
    await pc.setRemoteDescription(
      RTCSessionDescription(
        offerMap['sdp'] as String,
        offerMap['type'] as String,
      ),
    );

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await callRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
    });

    // Read viewer's ICE candidates
    callRef.collection('viewer_ice').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data() as Map<String, dynamic>?;
          if (d == null) continue;
          pc.addCandidate(RTCIceCandidate(
            d['candidate'] as String?,
            d['sdpMid'] as String?,
            (d['sdpMLineIndex'] as num?)?.toInt(),
          ));
        }
      }
    });

    _log('answer written for callId=$callId');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private: helpers
  // ──────────────────────────────────────────────────────────────────────────

  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
  };

  void _closePeer(String broadcasterId) {
    final peer = _peers.remove(broadcasterId);
    if (peer == null) return;
    _uidToUserId.remove(peer.broadcasterUid);
    _userIdToUid.remove(broadcasterId);
    peer.dispose();
    onRemoteUserLeft?.call();
    _log('closed connection to broadcaster=$broadcasterId');
  }

  Future<void> _stopLocalStream() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      _localRenderer.srcObject = null;
      _localStream = null;
    }
  }

  void _onListenerError(Object error) {
    _log('Firestore listener error: $error');
    onConnectionLost?.call();
  }

  void _log(String message) {
    developer.log(message, name: 'WebRTC');
    if (kDebugMode) debugPrint('[WebRTC] $message');
  }

  Never _throwMapped(Object error, String operation) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('notallowederror') || raw.contains('permission denied')) {
      throw AgoraServiceException(
        code: 'permission-denied',
        message: 'Camera/microphone permission was denied. Allow access and retry.',
        cause: error,
      );
    }
    if (raw.contains('notfounderror') ||
        raw.contains('requested device not found') ||
        raw.contains('no audio') ||
        raw.contains('no video') ||
        raw.contains('devicesnotfound')) {
      throw AgoraServiceException(
        code: 'no-media-devices',
        message: 'No working camera or microphone was found on this device.',
        cause: error,
      );
    }
    if (raw.contains('notreadableerror') ||
        raw.contains('track is already in use') ||
        raw.contains('device in use')) {
      throw AgoraServiceException(
        code: 'device-in-use',
        message: 'Camera or microphone is in use by another app or tab.',
        cause: error,
      );
    }
    throw AgoraServiceException(
      code: 'webrtc-$operation-failed',
      message: 'Failed to $operation.',
      cause: error,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Internal helper: holds a peer connection + renderer for one remote broadcaster
// ──────────────────────────────────────────────────────────────────────────────
class _PeerEntry {
  _PeerEntry({
    required this.broadcasterId,
    required this.broadcasterUid,
    required this.pc,
    required this.renderer,
  });

  final String broadcasterId;
  final int broadcasterUid;
  final RTCPeerConnection pc;
  final RTCVideoRenderer renderer;
  MediaStream? remoteStream;
  bool get rendererReady => true; // renderer.initialize() is called in create

  StreamSubscription? answerSub;
  StreamSubscription? iceSub;

  Future<void> dispose() async {
    await answerSub?.cancel();
    await iceSub?.cancel();
    answerSub = null;
    iceSub = null;
    remoteStream?.getTracks().forEach((t) => t.stop());
    remoteStream = null;
    renderer.srcObject = null;
    try { await renderer.dispose(); } catch (_) {}
    try { await pc.close(); } catch (_) {}
  }
}
