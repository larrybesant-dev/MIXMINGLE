import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LiveRoomMediaPhase {
  idle,
  connecting,
  ready,
  reconnecting,
  failed,
}

class LiveRoomMediaState {
  const LiveRoomMediaState({
    this.phase = LiveRoomMediaPhase.idle,
    this.connectPhase = 'idle',
    this.isMicMuted = false,
    this.isVideoEnabled = false,
    this.isSharingSystemAudio = false,
    this.isMicActionInFlight = false,
    this.isVideoActionInFlight = false,
    this.isSystemAudioActionInFlight = false,
    this.cameraStatus,
    this.callError,
    this.currentRtcUid,
    this.claimedSlotId,
    this.appliedMediaRole,
    this.requestedHighQualityRemoteUids = const <int>{},
    this.requestedLowQualityRemoteUids = const <int>{},
    this.localViewEpoch = 0,
  });

  final LiveRoomMediaPhase phase;
  final String connectPhase;
  final bool isMicMuted;
  final bool isVideoEnabled;
  final bool isSharingSystemAudio;
  final bool isMicActionInFlight;
  final bool isVideoActionInFlight;
  final bool isSystemAudioActionInFlight;
  final String? cameraStatus;
  final String? callError;
  final int? currentRtcUid;
  final String? claimedSlotId;
  final String? appliedMediaRole;
  final Set<int> requestedHighQualityRemoteUids;
  final Set<int> requestedLowQualityRemoteUids;
  final int localViewEpoch;

  bool get isCallConnecting =>
      phase == LiveRoomMediaPhase.connecting ||
      phase == LiveRoomMediaPhase.reconnecting;

  bool get isCallReady => phase == LiveRoomMediaPhase.ready;

  LiveRoomMediaState copyWith({
    LiveRoomMediaPhase? phase,
    String? connectPhase,
    bool? isMicMuted,
    bool? isVideoEnabled,
    bool? isSharingSystemAudio,
    bool? isMicActionInFlight,
    bool? isVideoActionInFlight,
    bool? isSystemAudioActionInFlight,
    Object? cameraStatus = _unset,
    Object? callError = _unset,
    Object? currentRtcUid = _unset,
    Object? claimedSlotId = _unset,
    Object? appliedMediaRole = _unset,
    Set<int>? requestedHighQualityRemoteUids,
    Set<int>? requestedLowQualityRemoteUids,
    int? localViewEpoch,
  }) {
    return LiveRoomMediaState(
      phase: phase ?? this.phase,
      connectPhase: connectPhase ?? this.connectPhase,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSharingSystemAudio: isSharingSystemAudio ?? this.isSharingSystemAudio,
      isMicActionInFlight:
          isMicActionInFlight ?? this.isMicActionInFlight,
      isVideoActionInFlight:
          isVideoActionInFlight ?? this.isVideoActionInFlight,
      isSystemAudioActionInFlight:
          isSystemAudioActionInFlight ?? this.isSystemAudioActionInFlight,
      cameraStatus: identical(cameraStatus, _unset)
          ? this.cameraStatus
          : cameraStatus as String?,
      callError: identical(callError, _unset)
          ? this.callError
          : callError as String?,
      currentRtcUid: identical(currentRtcUid, _unset)
          ? this.currentRtcUid
          : currentRtcUid as int?,
      claimedSlotId: identical(claimedSlotId, _unset)
          ? this.claimedSlotId
          : claimedSlotId as String?,
      appliedMediaRole: identical(appliedMediaRole, _unset)
          ? this.appliedMediaRole
          : appliedMediaRole as String?,
      requestedHighQualityRemoteUids:
          requestedHighQualityRemoteUids ?? this.requestedHighQualityRemoteUids,
      requestedLowQualityRemoteUids:
          requestedLowQualityRemoteUids ?? this.requestedLowQualityRemoteUids,
      localViewEpoch: localViewEpoch ?? this.localViewEpoch,
    );
  }
}

const Object _unset = Object();

final liveRoomMediaControllerProvider = NotifierProvider.family
    .autoDispose<LiveRoomMediaController, LiveRoomMediaState, String>(
  LiveRoomMediaController.new,
);

class LiveRoomMediaController
    extends AutoDisposeFamilyNotifier<LiveRoomMediaState, String> {
  @override
  LiveRoomMediaState build(String arg) => const LiveRoomMediaState();

  void setConnectPhase(String phase) {
    state = state.copyWith(connectPhase: phase);
  }

  void setCameraStatus(String? status) {
    state = state.copyWith(cameraStatus: status);
  }

  void setCallError(String? error) {
    state = state.copyWith(callError: error);
  }

  void beginConnecting() {
    state = state.copyWith(
      phase: LiveRoomMediaPhase.connecting,
      connectPhase: 'starting',
      callError: null,
    );
  }

  void markRetryingInitialization() {
    state = state.copyWith(
      phase: LiveRoomMediaPhase.connecting,
      connectPhase: 'retrying-init',
      cameraStatus: 'Retrying media engine initialization...',
    );
  }

  void markReady({
    required int rtcUid,
    required String cameraStatus,
    bool isMicMuted = true,
    bool isVideoEnabled = false,
  }) {
    state = state.copyWith(
      phase: LiveRoomMediaPhase.ready,
      connectPhase: 'ready',
      callError: null,
      currentRtcUid: rtcUid,
      isMicMuted: isMicMuted,
      isVideoEnabled: isVideoEnabled,
      cameraStatus: cameraStatus,
      localViewEpoch: state.localViewEpoch + 1,
    );
  }

  void markConnectionFailed({
    required String callError,
    required String cameraStatus,
  }) {
    state = state.copyWith(
      phase: LiveRoomMediaPhase.failed,
      connectPhase: 'failed',
      callError: callError,
      cameraStatus: cameraStatus,
      currentRtcUid: null,
      isVideoEnabled: false,
    );
  }

  void markReconnecting(String cameraStatus) {
    state = state.copyWith(
      phase: LiveRoomMediaPhase.reconnecting,
      cameraStatus: cameraStatus,
      callError: null,
    );
  }

  void syncFromService({
    required bool isVideoEnabled,
    required bool isMicMuted,
    required bool isSharingSystemAudio,
  }) {
    if (state.isVideoEnabled == isVideoEnabled &&
        state.isMicMuted == isMicMuted &&
        state.isSharingSystemAudio == isSharingSystemAudio) {
      return;
    }
    state = state.copyWith(
      isVideoEnabled: isVideoEnabled,
      isMicMuted: isMicMuted,
      isSharingSystemAudio: isSharingSystemAudio,
    );
  }

  void beginMicAction() {
    state = state.copyWith(isMicActionInFlight: true);
  }

  void finishMicAction({required bool isMuted}) {
    state = state.copyWith(
      isMicMuted: isMuted,
      isMicActionInFlight: false,
    );
  }

  void endMicAction() {
    state = state.copyWith(isMicActionInFlight: false);
  }

  void setMicMuted(bool isMuted) {
    state = state.copyWith(isMicMuted: isMuted);
  }

  void beginSystemAudioAction() {
    state = state.copyWith(isSystemAudioActionInFlight: true);
  }

  void finishSystemAudioAction({required bool isSharing}) {
    state = state.copyWith(
      isSharingSystemAudio: isSharing,
      isSystemAudioActionInFlight: false,
    );
  }

  void endSystemAudioAction() {
    state = state.copyWith(isSystemAudioActionInFlight: false);
  }

  void markSystemAudioStopped() {
    state = state.copyWith(isSharingSystemAudio: false);
  }

  void beginVideoAction(String status) {
    state = state.copyWith(
      isVideoActionInFlight: true,
      cameraStatus: status,
    );
  }

  void blockVideoAction(String status) {
    state = state.copyWith(cameraStatus: status);
  }

  void setClaimedSlotId(String? slotId) {
    state = state.copyWith(claimedSlotId: slotId);
  }

  void setAppliedMediaRole(String? role) {
    state = state.copyWith(appliedMediaRole: role);
  }

  void finishVideoAction({
    required bool isVideoEnabled,
    required String cameraStatus,
    String? claimedSlotId,
    String? appliedMediaRole,
  }) {
    state = state.copyWith(
      isVideoEnabled: isVideoEnabled,
      cameraStatus: cameraStatus,
      claimedSlotId: isVideoEnabled ? claimedSlotId ?? state.claimedSlotId : null,
      appliedMediaRole: appliedMediaRole ?? state.appliedMediaRole,
      isVideoActionInFlight: false,
    );
  }

  void failVideoAction(String status) {
    state = state.copyWith(
      cameraStatus: status,
      isVideoActionInFlight: false,
    );
  }

  void endVideoAction() {
    state = state.copyWith(isVideoActionInFlight: false);
  }

  void updateRequestedRemoteQualities({
    required Set<int> highQualityUids,
    required Set<int> lowQualityUids,
  }) {
    state = state.copyWith(
      requestedHighQualityRemoteUids: Set<int>.unmodifiable(highQualityUids),
      requestedLowQualityRemoteUids: Set<int>.unmodifiable(lowQualityUids),
    );
  }

  void restoreBroadcastAfterReconnect({
    required String slotId,
    required bool wasMicMuted,
    required String role,
  }) {
    state = state.copyWith(
      phase: LiveRoomMediaPhase.ready,
      connectPhase: 'ready',
      claimedSlotId: slotId,
      isVideoEnabled: true,
      isMicMuted: wasMicMuted,
      appliedMediaRole: role,
      cameraStatus: 'Camera restored after reconnect.',
      callError: null,
    );
  }

  void resetDisconnected() {
    state = const LiveRoomMediaState();
  }
}
