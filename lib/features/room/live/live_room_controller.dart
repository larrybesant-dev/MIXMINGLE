// lib/features/room/live/live_room_controller.dart
//
// Central orchestrator for the cost-optimized multi-user video room.
//
// Owns and coordinates:
//   • LiveRoomPresence  — Firebase layer (always active)
//   • LiveAgoraClient   — Video engine (active only when screen is open)
//   • LiveRoomAudioManager — Enforces mic limits
//
// Architecture rules enforced:
//   1.  Presence = Firestore only, never paused.
//   2.  Video = only when screen is in foreground.
//   3.  Never auto-subscribe — only setVisibleEngineUids() drives subscription.
//   4.  Background → drop subs + publishing; keep presence + channel.
//   5.  Publishing requires: foregrounded + cam on + ≥1 subscriber.
//   6.  Mic toggle enforces the 1–4 active mic rule per room type.
//   7.  Rooms exist 24/7; videoChannelLive flips only when ≥1 user is in room view.
// ───────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/agora/agora_platform_service.dart';
import '../../../services/chat/messaging_service.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/messaging_providers.dart';
import '../../../utils/window_sync_service.dart';
import 'live_room_schema.dart';
import 'live_room_state.dart';
import 'live_room_presence.dart';
import 'live_agora_client.dart';
import 'live_room_audio.dart';

// ── Provider args ─────────────────────────────────────────────────────────

class LiveRoomArgs {
  const LiveRoomArgs({
    required this.roomId,
    required this.displayName,
    this.avatarUrl,
  });
  final String roomId;
  final String displayName;
  final String? avatarUrl;
}

// ── Provider ──────────────────────────────────────────────────────────────

final liveRoomControllerProvider =
    NotifierProvider<LiveRoomController, LiveRoomState>(
  LiveRoomController.new,
);

// ── Controller ────────────────────────────────────────────────────────────

class LiveRoomController extends Notifier<LiveRoomState> {
  // ── Room args (set in enterRoom) ──────────────────────────────────────────
  LiveRoomArgs? _args;

  // ── Subsystems ────────────────────────────────────────────────────────────
  late LiveRoomPresence _presence;
  late LiveAgoraClient _video;
  late LiveRoomAudioManager _audio;

  // ── Stream subscriptions ──────────────────────────────────────────────────
  StreamSubscription<List<RoomParticipant>>? _participantSub;
  StreamSubscription<VideoEngineEvent>? _videoEventSub;
  StreamSubscription<DocumentSnapshot>? _roomMetaSub;

  bool _isSuspending = false;
  bool _isResuming = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  // ── Count-sync ────────────────────────────────────────────────────────────
  // The host debounces a Firestore write that sets viewerCount / participantCount
  // to the real heartbeat-filtered participant count.  This repairs drift caused
  // by users who crash or close the tab without a clean leave().
  Timer? _countSyncTimer;

  // Chat input controller is owned by the active room controller instance.
  final TextEditingController chatTextController = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Exposes the underlying Agora engine for use in video rendering widgets.
  /// Returns null on web (web uses JS bridge separately).
  RtcEngine? get videoEngine {
    try {
      return _video.engine;
    } catch (_) {
      return null;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  LiveRoomState build() {
    ref.onDispose(_cleanup);
    return LiveRoomState(roomId: '', localUserId: _uid);
  }

  // ── Entry point ───────────────────────────────────────────────────────────

  /// Call once when the room screen mounts (after authentication is confirmed).
  Future<void> enterRoom(LiveRoomArgs args) async {
    if (state.isJoining || state.isLeaving) return;
    if (_uid.isEmpty) {
      state = state.copyWith(
        phase: LiveRoomPhase.error,
        error: 'You must be signed in to join this room.',
      );
      return;
    }

    // Allow clean re-entry after a prior leave/error by resetting to idle first.
    if (state.isLeft || state.hasError) {
      state = LiveRoomState(roomId: '', localUserId: _uid);
    }

    // If a stale active/suspended state remains, force a best-effort leave first.
    if (state.isActive || state.isSuspended) {
      try {
        await leaveRoom();
      } catch (_) {}
      state = LiveRoomState(roomId: '', localUserId: _uid);
    }

    _args = args;

    // Reset state with the correct roomId now that args are known
    state = LiveRoomState(
      roomId: args.roomId,
      localUserId: _uid,
      phase: LiveRoomPhase.joiningRoom,
      statusMessage: 'Joining room…',
    );

    try {
      // ── 1. Load room metadata ─────────────────────────────────────────
      final roomSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(_args!.roomId)
          .get();

      if (!roomSnap.exists) {
        state = state.copyWith(
          phase: LiveRoomPhase.error,
          error: 'Room not found.',
        );
        return;
      }

      final meta = RoomMeta.fromFirestore(roomSnap);

      // ── 2. Assign local role ──────────────────────────────────────────
<<<<<<< HEAD
        final isHost = meta.ownerId == _uid || meta.hostId == _uid;
        final isModerator = meta.moderators.contains(_uid);
        final isSpeaker = meta.speakers.contains(_uid);
        final role = isHost
          ? ParticipantRole.host
          : (isModerator || isSpeaker)
            ? ParticipantRole.broadcaster
            : ParticipantRole.audience;
      final gridPos  = role == ParticipantRole.host ? 0 : -1;
=======
      debugPrint('[ROOM_CTRL] ownerId="${meta.ownerId}" localUid="$_uid" match=${meta.ownerId == _uid}');
      final role = meta.ownerId == _uid
          ? ParticipantRole.host
          : ParticipantRole.audience;
      final gridPos = role == ParticipantRole.host ? 0 : -1;
>>>>>>> origin/develop

      state = state.copyWith(
        roomMeta: meta,
        localRole: role,
        statusMessage: 'Registering presence…',
      );

      // ── 3. Create subsystems ──────────────────────────────────────────
      _audio = LiveRoomAudioManager.forRoomType(meta.type);

      _presence = LiveRoomPresence(
        roomId: _args!.roomId,
        roomType: meta.type,
        initialDisplayName: _args!.displayName,
        initialAvatarUrl: _args!.avatarUrl,
      );

      _video = LiveAgoraClient(roomType: meta.type);

      // ── 4. Join Firestore presence ────────────────────────────────────
      await _presence.join(role: role, gridPosition: gridPos);

      // ── 5. Subscribe to participant changes ───────────────────────────
      _participantSub = _presence.participantsStream.listen(
        _onParticipantsUpdated,
        onError: (e) => debugPrint('[ROOM_CTRL] participant stream error: $e'),
      );

      // ── 6. Watch room metadata changes ────────────────────────────────
      _roomMetaSub = FirebaseFirestore.instance
          .collection('rooms')
          .doc(_args!.roomId)
          .snapshots()
          .listen(_onRoomMetaUpdated);

      // ── 7. Initialise and join video channel ──────────────────────────
      state = state.copyWith(
        phase: LiveRoomPhase.connectingVideo,
        statusMessage: 'Connecting video…',
      );

      await _video.initialize();

      _videoEventSub = _video.events.listen(
        _onVideoEvent,
        onError: (e) => debugPrint('[ROOM_CTRL] video event error: $e'),
      );

      await _video.joinChannel(
<<<<<<< HEAD
        channelId:     _args!.roomId,
        userId:        _uid,
        isBroadcaster: role == ParticipantRole.host || role == ParticipantRole.broadcaster,
=======
        channelId: _args!.roomId,
        userId: _uid,
        isBroadcaster: role == ParticipantRole.host,
>>>>>>> origin/develop
      );

      // Flip videoChannelLive = true on the room doc (first user in)
      await _presence.setVideoChannelLive(true);

      // Hosts auto-enable cam
      if (role == ParticipantRole.host) {
        await _presence.setCamOn(true);
        state = state.copyWith(isCamOn: true);
      }

      state = state.copyWith(
        phase: LiveRoomPhase.active,
        clearError: true,
        clearStatus: true,
      );

      // Enforce publish rules immediately: the host auto-cam path sets
      // isCamOn=true in state but never calls _enforcePublishRules(), so the
      // Agora video track is never created and never published.  Without this
      // call, remote browsers receive user-published(audio) but NOT
      // user-published(video) — making the host's tile permanently blank.
      if (state.isCamOn) {
        debugPrint('[ROOM_CTRL] enterRoom: isCamOn=true → enforcing publish rules');
        await _enforcePublishRules();
      }

      WindowSyncService.send('room.joined', {
        'roomId': _args!.roomId,
        'userId': _uid,
      });
    } catch (e, st) {
      debugPrint('[ROOM_CTRL] enterRoom error: $e\n$st');
      state = state.copyWith(
        phase: LiveRoomPhase.error,
        error: 'Could not join room: $e',
      );
    }
  }

  // ── Visibility-based subscription ─────────────────────────────────────────

  /// Called by the tile grid widget whenever the visible tile set changes.
  /// This is the sole mechanism that drives video subscriptions.
  Future<void> setVisibleEngineUids(List<int> uids) async {
    if (!state.isActive) return;

    // Only approved broadcasters/host can be subscribed as remote video sources.
    final approvedRemoteUids = state.participants
        .where((p) =>
            p.agoraUid != null &&
            p.isGridVisible &&
            (p.role == ParticipantRole.host || p.role == ParticipantRole.broadcaster))
        .map((p) => p.agoraUid!)
        .toSet();

    final filteredUids = uids.where(approvedRemoteUids.contains).toList();

    state = state.copyWith(visibleEngineUids: filteredUids);
    await _video.setVisibleUids(filteredUids);
    state = state.copyWith(
      subscribedEngineUids: _video.subscribedUids.toList(),
    );
    await _enforcePublishRules();
  }

  // ── Cam toggle ────────────────────────────────────────────────────────────

  /// Returns null on success, or a user-facing error string on failure.
  Future<String?> toggleCam() async {
    if (!state.isActive) return 'Not in an active room.';
    final meta = state.roomMeta;
    if (meta == null) return 'Room data not loaded.';

    final wantOn = !state.isCamOn;

    if (wantOn) {
      // If audience toggles cam on, move them into an available broadcaster slot.
      if (!state.isBroadcaster) {
        final occupied = state.participants
            .where((p) => p.gridPosition >= 0)
            .map((p) => p.gridPosition)
            .toSet();

        int? freeSlot;
        for (int i = 1; i < meta.maxBroadcasters; i++) {
          if (!occupied.contains(i)) {
            freeSlot = i;
            break;
          }
        }

        if (freeSlot == null) {
          return 'All ${meta.maxBroadcasters} camera slot(s) are taken.';
        }

        await _presence.promoteParticipant(
          _uid,
          gridPosition: freeSlot,
          role: ParticipantRole.broadcaster,
        );

        state = state.copyWith(localRole: ParticipantRole.broadcaster);
      }

      final decision = _audio.canTurnCamOn(
        userId: _uid,
        currentCamCount: state.onCamCount,
        maxCams: meta.maxBroadcasters,
      );
      if (!decision.allowed) return decision.reason;
    }

    try {
      await _presence.setCamOn(wantOn);
      state = state.copyWith(isCamOn: wantOn);
      await _enforcePublishRules();

      WindowSyncService.send('room.camToggled', {
        'roomId': state.roomId,
        'userId': _uid,
        'isCamOn': wantOn,
      });
      return null;
    } catch (e) {
      debugPrint('[ROOM_CTRL] toggleCam failed: $e');

      if (wantOn) {
        try {
          await _presence.setCamOn(false);
        } catch (_) {}
        state = state.copyWith(isCamOn: false, isPublishingVideo: false);
      }

      return _friendlyMediaError(e, media: 'camera');
    }
  }

  // ── Mic toggle ────────────────────────────────────────────────────────────

  /// Returns null on success, or a user-facing error string on failure.
  Future<String?> toggleMic() async {
    if (!state.isActive) return 'Not in an active room.';

    final wantOn = !state.isMicOn;

    if (wantOn) {
      final decision = _audio.canUnmute(_uid);
      if (!decision.allowed) return decision.reason;
    }

    try {
      await _presence.setMicActive(wantOn);
      state = state.copyWith(isMicOn: wantOn);

      if (wantOn) {
        await _video.startPublishingAudio();
        _audio.markMicActive(_uid);
        state = state.copyWith(isPublishingAudio: true);
      } else {
        await _video.stopPublishingAudio();
        _audio.markMicInactive(_uid);
        state = state.copyWith(isPublishingAudio: false);
      }

      WindowSyncService.send('room.micToggled', {
        'roomId': state.roomId,
        'userId': _uid,
        'isMicOn': wantOn,
      });
      return null;
    } catch (e) {
      debugPrint('[ROOM_CTRL] toggleMic failed: $e');

      if (wantOn) {
        try {
          await _presence.setMicActive(false);
        } catch (_) {}
        _audio.markMicInactive(_uid);
        state = state.copyWith(isMicOn: false, isPublishingAudio: false);
      }

      return _friendlyMediaError(e, media: 'microphone');
    }
  }

  String _friendlyMediaError(Object error, {required String media}) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('permission denied') ||
        raw.contains('permission') && raw.contains('denied') ||
        raw.contains('notallowederror')) {
      return 'Browser $media permission denied. Allow access in the address bar and try again.';
    }
    if (raw.contains('unavailable') || raw.contains('not found')) {
      return 'No $media device is available. Connect a device and try again.';
    }
    return 'Could not enable $media right now. Please try again.';
  }

  // ── Cam request (audience ↔ broadcaster promotion) ──────────────────────

  /// Audience member signals they want a cam slot.
  Future<String?> requestCam() async {
    if (!state.isActive) return 'Not in an active room.';
    if (state.isBroadcaster) return null; // already on cam
    final meta = state.roomMeta;
    if (meta == null) return 'Room data not loaded.';
    if (state.onCamCount >= meta.maxBroadcasters) {
      return 'All cam slots are taken (${meta.maxBroadcasters} max).';
    }
    await _presence.setCamRequestPending(true);
    return null;
  }

  /// Cancel a pending cam request.
  Future<void> cancelCamRequest() async {
    if (!state.isActive) return;
    await _presence.setCamRequestPending(false);
  }

  /// Host approves a cam request — promotes the user to the next free grid slot.
  Future<String?> approveRequest(String userId) async {
    if (!state.isHost) return 'Only the host can approve requests.';
    final meta = state.roomMeta;
    if (meta == null) return 'Room data not loaded.';

    // Find the next free guest slot (0 = host, 1..maxBroadcasters-1 = guests)
    final occupied = state.participants
        .where((p) => p.gridPosition >= 0)
        .map((p) => p.gridPosition)
        .toSet();
    int? freeSlot;
    for (int i = 1; i < meta.maxBroadcasters; i++) {
      if (!occupied.contains(i)) {
        freeSlot = i;
        break;
      }
    }
    if (freeSlot == null) {
      return 'All cam slots are full \u2014 remove someone first.';
    }

    await _presence.promoteParticipant(
      userId,
      gridPosition: freeSlot,
      role: ParticipantRole.broadcaster,
    );
    return null;
  }

  /// Host denies a cam request — clears the pending flag.
  Future<void> denyRequest(String userId) async {
    if (!state.isHost) return;
    await _presence.denyParticipantRequest(userId);
  }

  /// Host removes a broadcaster from their cam slot (demotion).
  /// The demoted user is moved back to the audience row.
  Future<String?> demoteParticipant(String userId) async {
    if (!state.isHost) return 'Only the host can remove broadcasters.';
    if (userId == _uid) return 'Cannot demote yourself.';
    await _presence.demoteParticipant(userId);
    return null;
  }

  // ── Chat send ─────────────────────────────────────────────────────────────

  Future<void> sendMessage(String rawText, {String? roomId}) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    try {
      final providerUser = ref.read(currentUserProvider).value;
      final authUser = FirebaseAuth.instance.currentUser;

      // Firestore rules require senderId == request.auth.uid.
      final senderId = authUser?.uid ?? providerUser?.id ?? _uid;
      if (senderId.isEmpty) return;

      final profileDisplayName = providerUser?.displayName?.trim() ?? '';
      final profileUsername = providerUser?.username.trim() ?? '';
      final argsDisplayName = _args?.displayName.trim() ?? '';
      final senderName = profileDisplayName.isNotEmpty
          ? profileDisplayName
          : profileUsername.isNotEmpty
              ? profileUsername
              : argsDisplayName.isNotEmpty
                  ? argsDisplayName
                  : 'Guest';

      final senderAvatar = providerUser?.avatarUrl ?? authUser?.photoURL ?? '';

      final targetRoomId = (roomId ?? '').trim().isNotEmpty
          ? roomId!.trim()
          : state.roomId;
      if (targetRoomId.isEmpty) {
        debugPrint('[ROOM_CTRL] sendMessage skipped: roomId is empty');
        return;
      }

      await ref.read(messagingServiceProvider).sendRoomMessage(
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatar,
        roomId: targetRoomId,
        content: text,
      );

      if (chatTextController.text.trim() == text) {
        chatTextController.clear();
      }

      WindowSyncService.send('room.messageSent', {
        'roomId': targetRoomId,
        'senderId': senderId,
        'content': text,
      });
    } catch (e) {
      debugPrint('[ROOM_CTRL] sendMessage error: $e');
      state = state.copyWith(error: 'Failed to send message: $e');
      rethrow;
    }
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────
  /// Call when the app is backgrounded / minimised / screen switches away.
  Future<void> onSuspended() async {
    if (_isSuspending) return;
    if (!state.isActive && !state.isSuspended) return;
<<<<<<< HEAD
    _isSuspending = true;
    try {
      state = state.copyWith(isForegrounded: false, phase: LiveRoomPhase.suspended);
=======
    state =
        state.copyWith(isForegrounded: false, phase: LiveRoomPhase.suspended);
>>>>>>> origin/develop

      // Drop video subscriptions (stay in channel, just stop receiving)
      await _video.dropAllSubscriptions();
      // Stop publishing (save bandwidth + battery)
      await _video.dropPublishing();
      // Notify Firestore
      await _presence.setStreaming(false);
      await _presence.setForegrounded(false);

<<<<<<< HEAD
      state = state.copyWith(
        isPublishingVideo:    false,
        isPublishingAudio:    false,
        subscribedEngineUids: [],
      );

      WindowSyncService.send('room.suspended', {
        'roomId': state.roomId,
        'userId': _uid,
      });
    } finally {
      _isSuspending = false;
    }
=======
    state = state.copyWith(
      isPublishingVideo: false,
      isPublishingAudio: false,
      subscribedEngineUids: [],
    );
>>>>>>> origin/develop
  }

  /// Call when the app returns to the foreground.
  Future<void> onResumed() async {
    if (_isResuming) return;
    if (!state.isSuspended) return;
    _isResuming = true;
    try {
      state = state.copyWith(isForegrounded: true, phase: LiveRoomPhase.active);
      await _presence.setForegrounded(true);

      // Restore subscriptions for currently visible tiles
      await _video.setVisibleUids(state.visibleEngineUids);
      state = state.copyWith(
        subscribedEngineUids: _video.subscribedUids.toList(),
      );
      await _enforcePublishRules();

      WindowSyncService.send('room.resumed', {
        'roomId': state.roomId,
        'userId': _uid,
      });
    } finally {
      _isResuming = false;
    }
  }

  // ── Leave room ────────────────────────────────────────────────────────────

  Future<void> leaveRoom() async {
    if (state.isLeaving || state.isLeft) return;
    state =
        state.copyWith(phase: LiveRoomPhase.leaving, statusMessage: 'Leaving…');

    String? leaveError;
    try {
      // Stop video first
      await _video.dropPublishing();
      await _video.leaveChannel();

      // Flip videoChannelLive = false if this was the last participant
      await _presence.deactivateVideoChannelIfLast();

      // Remove Firestore presence
      await _presence.leave();
    } catch (e) {
      leaveError = 'Leave encountered an error: $e';
      debugPrint('[ROOM_CTRL] leaveRoom error: $e');
    }

    state = state.copyWith(
      phase: LiveRoomPhase.left,
      clearStatus: true,
      error:       leaveError,
      clearError:  leaveError == null,
    );

    WindowSyncService.send('room.left', {
      'roomId': _args?.roomId ?? state.roomId,
      'userId': _uid,
    });
  }

  // ── Publish rule enforcement ──────────────────────────────────────────────

  /// Re-evaluates whether video publishing should be active.
  /// Rule: publish only when foregrounded + cam on + ≥1 subscriber.
  Future<void> _enforcePublishRules() async {
    if (!state.isActive) return;

    final shouldPublish = state.isForegrounded && state.isCamOn;

    debugPrint('[ROOM_CTRL] _enforcePublishRules: '
        'isForegrounded=${state.isForegrounded} '
        'isCamOn=${state.isCamOn} '
        'isPublishingVideo=${state.isPublishingVideo} '
        'shouldPublish=$shouldPublish');

    if (shouldPublish && !state.isPublishingVideo) {
      debugPrint('[ROOM_CTRL] _enforcePublishRules: STARTING video publish');
      await _video.startPublishingVideo();
      await _presence.setStreaming(true);
      state = state.copyWith(isPublishingVideo: true);
      debugPrint('[ROOM_CTRL] _enforcePublishRules: video publish DONE, isPublishingVideo=true');
    } else if (!shouldPublish && state.isPublishingVideo) {
      debugPrint('[ROOM_CTRL] _enforcePublishRules: STOPPING video publish (shouldPublish=false)');
      await _video.stopPublishingVideo();
      await _presence.setStreaming(false);
      state = state.copyWith(isPublishingVideo: false);
    } else {
      debugPrint('[ROOM_CTRL] _enforcePublishRules: no-op (shouldPublish=$shouldPublish isPublishingVideo=${state.isPublishingVideo})');
    }
  }

  // ── Firestore event handlers ──────────────────────────────────────────────

  void _onParticipantsUpdated(List<RoomParticipant> participants) {
    _audio.syncFromParticipants(participants);

    final gridCount = participants.where((p) => p.isGridVisible).length;
    debugPrint('[ROOM_CTRL] _onParticipantsUpdated: total=${participants.length} inGrid=$gridCount '
        'uids=${participants.where((p) => p.isGridVisible).map((p) => "${p.userId.substring(0, 6)}:uid=${p.agoraUid}:onCam=${p.isOnCam}").join(", ")}');

    // Read the Agora bridge viewer count for reference only — it is stored in
    // state but the viewerCount getter in LiveRoomState now always returns
    // participants.length (the heartbeat-filtered Firestore fact), because
    // activeAgoraUsers in the JS bridge only tracks broadcasters publishing
    // tracks, NOT pure-audience listeners, which caused an under-count.
    int agoraCount = 0;
    if (kIsWeb) {
      try {
        final bridgeState = AgoraPlatformService.getWebBridgeState();
        final raw = bridgeState['viewerCount'];
        if (raw is int && raw > 0) agoraCount = raw;
      } catch (_) {}
    }

    // Detect whether the local user's role or cam state changed in Firestore
    // (e.g. host promoted this user while they were audience).
    final localP = participants.where((p) => p.userId == _uid).firstOrNull;

    var updated = state.copyWith(participants: participants, agoraViewerCount: agoraCount);

    // Host: debounce-sync the accurate participant count back to Firestore so
    // home-page cards don't show stale inflated counts from ghost users.
    final isHostUser = _uid == (state.roomMeta?.ownerId ?? '') ||
        _uid == (state.roomMeta?.hostId ?? '');
    if (isHostUser && updated.isActive) {
      _scheduleCountSync(participants.length);
    }

    if (localP != null) {
      final roleChanged = localP.role != state.localRole;
      final camChanged = localP.isOnCam != state.isCamOn;

      if (roleChanged) updated = updated.copyWith(localRole: localP.role);
      if (camChanged) updated = updated.copyWith(isCamOn: localP.isOnCam);

      state = updated;

      // Enforce publish rules on role change (audience→broadcaster) AND on
      // cam change (isOnCam flipped via Firestore).  Previously only
      // roleChanged triggered this, so any cam-on transition driven by an
      // external Firestore write — including the host auto-cam in enterRoom —
      // silently left the video track unpublished.
      if (roleChanged || camChanged) _enforcePublishRules();
    } else {
      state = updated;
    }
  }

  void _onRoomMetaUpdated(DocumentSnapshot snap) {
    if (!snap.exists) {
      // Room document was deleted — gracefully leave
      debugPrint('[ROOM_CTRL] Room deleted while active — leaving.');
      state = state.copyWith(error: 'This room has been deleted.');
      leaveRoom();
      return;
    }
    final meta = RoomMeta.fromFirestore(snap);
    state = state.copyWith(roomMeta: meta);

    if (!meta.isActive && (state.isActive || state.isSuspended)) {
      // Room was closed by host/admin
      debugPrint('[ROOM_CTRL] Room deactivated — leaving.');
      state = state.copyWith(error: 'This room has been closed by the host.');
      leaveRoom();
    }
  }

  // ── Video engine event handler ────────────────────────────────────────────

  void _onVideoEvent(VideoEngineEvent event) {
    switch (event) {
      case EngineJoinedEvent(:final localUid):
        if (localUid != 0) {
          debugPrint('[ROOM_CTRL] EngineJoinedEvent: localUid=$localUid — writing agoraUid to Firestore');
          state = state.copyWith(localEngineUid: localUid);
          _presence.setVideoEngineUid(localUid);
        } else {
          debugPrint('[ROOM_CTRL] EngineJoinedEvent: localUid=0 — skipping Firestore agoraUid write');
        }

      case EngineLeftEvent():
        break;

      case RemoteUserJoinedEvent():
        // Subscription driven by setVisibleEngineUids — nothing to do here
        break;

      case RemoteUserLeftEvent(:final remoteUid):
        final updated = List<int>.from(state.subscribedEngineUids)
          ..remove(remoteUid);
        state = state.copyWith(subscribedEngineUids: updated);

      case RemoteVideoToggleEvent():
        break; // UI reacts via participant stream when needed

      case ActiveSpeakerEvent(:final speakerUid):
        state = state.copyWith(
          activeSpeakerUid: speakerUid,
          clearActiveSpeaker: speakerUid == null,
        );

      case EngineConnectionStateEvent(:final state, :final reason):
        final shouldReconnect =
            state == ConnectionStateType.connectionStateReconnecting ||
            (state == ConnectionStateType.connectionStateFailed &&
                reason != ConnectionChangedReasonType.connectionChangedLeaveChannel);
        if (shouldReconnect && this.state.isActive) {
          _attemptReconnect();
        }

      case EngineErrorEvent(:final message):
        debugPrint('[ROOM_CTRL] Video engine error: $message');
        // Non-fatal — log and surface to UI but don't kill the room
        state = state.copyWith(error: 'Video: $message');

      case AudioMixingStateEvent(:final mixingState):
        switch (mixingState) {
          case AudioMixingStateType.audioMixingStatePlaying:
            state = state.copyWith(djIsPlaying: true, djIsPaused: false);
          case AudioMixingStateType.audioMixingStatePaused:
            state = state.copyWith(djIsPlaying: false, djIsPaused: true);
          case AudioMixingStateType.audioMixingStateStopped:
            if (!state.djIsLooping) state = state.copyWith(clearDj: true);
          case AudioMixingStateType.audioMixingStateFailed:
            state = state.copyWith(djIsPlaying: false, djIsPaused: false);
        }
    }
  }

  // ── DJ controls ───────────────────────────────────────────────────────

  /// Returns an error string on failure, null on success.
  Future<String?> djPlay(String url, String title) async {
    if (!state.isActive) return 'Not in an active room.';
    if (!state.isHost && !state.isBroadcaster) {
      return 'Only hosts and broadcasters can use DJ.';
    }
    try {
      await _video.startAudioMixing(url, looping: state.djIsLooping);
      final uid = _uid;
      state = state.copyWith(
        djTrackTitle: title,
        djIsPlaying:  true,
        djIsPaused:   false,
        djUserId:     uid,
      );
      // Sync music state to Firestore so all participants see the banner.
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(state.roomId)
          .update({
            RoomFields.isMusicPlaying:  true,
            RoomFields.currentTrackUrl: url,
            RoomFields.djUserId:        uid,
            RoomFields.updatedAt:       FieldValue.serverTimestamp(),
          }).catchError((Object e) {
            debugPrint('[ROOM_CTRL] djPlay Firestore sync error: $e');
          });
      return null;
    } catch (e) {
      return 'Could not play track: $e';
    }
  }

  Future<void> djStop() async {
    if (!state.isActive) return;
    try {
      await _video.stopAudioMixing();
      state = state.copyWith(clearDj: true);
      // Clear music state from Firestore.
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(state.roomId)
          .update({
            RoomFields.isMusicPlaying:  false,
            RoomFields.currentTrackUrl: null,
            RoomFields.djUserId:        null,
            RoomFields.updatedAt:       FieldValue.serverTimestamp(),
          }).catchError((Object e) {
            debugPrint('[ROOM_CTRL] djStop Firestore sync error: $e');
          });
    } catch (_) {}
  }

  Future<void> djTogglePause() async {
    if (!state.isActive) return;
    try {
      if (state.djIsPlaying) {
        await _video.pauseAudioMixing();
      } else if (state.djIsPaused) {
        await _video.resumeAudioMixing();
      }
    } catch (_) {}
  }

  Future<void> djSetVolume(int volume) async {
    if (!state.isActive) return;
    final v = volume.clamp(0, 100);
    try {
      await _video.setAudioMixingVolume(v);
      state = state.copyWith(djVolume: v);
    } catch (_) {}
  }

  void djSetLooping(bool v) => state = state.copyWith(djIsLooping: v);

  // ── Cleanup ───────────────────────────────────────────────────────────

  void _cleanup() {
    _countSyncTimer?.cancel();
    _participantSub?.cancel();
    _videoEventSub?.cancel();
    _roomMetaSub?.cancel();
<<<<<<< HEAD
    chatTextController.dispose();
    try { _presence.dispose(); } catch (_) {}
    try { _video.dispose();    } catch (_) {}
=======
    try {
      _presence.dispose();
    } catch (_) {}
    try {
      _video.dispose();
    } catch (_) {}
>>>>>>> origin/develop
  }

  /// Debounced write that keeps Firestore viewerCount accurate.
  /// Only the host calls this — runs 5 s after the last participant change.
  void _scheduleCountSync(int accurateCount) {
    _countSyncTimer?.cancel();
    _countSyncTimer = Timer(const Duration(seconds: 5), () {
      if (_args == null) return;
      FirebaseFirestore.instance.collection('rooms').doc(_args!.roomId).update({
        'viewerCount':               accurateCount,
        RoomFields.participantCount: accurateCount,
        RoomFields.updatedAt:        FieldValue.serverTimestamp(),
      }).catchError((Object e) {
        debugPrint('[ROOM_CTRL] countSync error: $e');
      });
    });
  }

  Future<void> _attemptReconnect() async {
    if (_isReconnecting || _args == null || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts += 1;

    try {
      await _video.leaveChannel();
      await Future<void>.delayed(Duration(milliseconds: 600 * _reconnectAttempts));
      await _video.joinChannel(
        channelId: _args!.roomId,
        userId: _uid,
        isBroadcaster: state.isBroadcaster,
      );
      await _video.setVisibleUids(state.visibleEngineUids);
      state = state.copyWith(subscribedEngineUids: _video.subscribedUids.toList());
      await _enforcePublishRules();
      // Refresh presence heartbeat immediately — prevents ghost classification
      // during the reconnect window when the heartbeat timer may have missed beats.
      _presence.forceHeartbeat();
      _reconnectAttempts = 0;
    } catch (e) {
      debugPrint('[ROOM_CTRL] reconnect failed attempt=$_reconnectAttempts error=$e');
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        state = state.copyWith(
          error: 'Video reconnection failed. Please leave and rejoin.',
        );
      }
    } finally {
      _isReconnecting = false;
    }
  }
}
