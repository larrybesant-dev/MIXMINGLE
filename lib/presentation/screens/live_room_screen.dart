import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/agora_constants.dart';
import '../../core/telemetry/app_telemetry.dart';
import '../../models/moderation_model.dart';
import '../../models/message_model.dart';
import '../../models/presence_model.dart';
import '../../models/room_participant_model.dart';
import '../providers/friend_provider.dart';
import '../providers/user_provider.dart';
import '../../features/room/controllers/live_room_controller.dart';
import '../../features/room/controllers/live_room_media_controller.dart';
import '../../features/room/controllers/webrtc_controller.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/providers/presence_provider.dart';
import '../../features/room/providers/room_firestore_provider.dart';
import '../../features/room/widgets/message_bubble.dart';
import '../../features/room/widgets/camera_wall.dart';
import '../../features/room/widgets/room_control_sheets.dart';
import '../../features/room/widgets/floating_gift_overlay.dart';
import '../../widgets/user_profile_popup.dart';
import '../../widgets/floating_whisper_panel.dart';
import '../../features/room/widgets/dockable_panel.dart';
import '../../features/room/widgets/mic_queue_panel.dart';
import '../../features/room/widgets/on_mic_panel.dart';
import '../../features/room/widgets/buzz_overlay.dart';
import '../../features/room/providers/buzz_provider.dart';
import '../../features/room/widgets/cam_preview_sheet.dart';
import '../../features/room/widgets/rich_text_toolbar.dart';
import '../../features/room/widgets/floating_cam_window.dart';
import '../../features/room/widgets/room_host_control_panel.dart';
import '../../features/room/widgets/live_room_app_bar_actions.dart';
import '../../features/room/widgets/live_room_app_bar_status.dart';
import '../../features/room/widgets/live_room_media_action_strip.dart';
import '../../services/web_popout_service.dart';
import '../../services/desktop_window_service.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../features/room/providers/mic_access_provider.dart';
import '../../core/utils/network_image_url.dart';
import '../../features/feed/providers/host_controls_providers.dart';
import '../../features/feed/providers/typing_providers.dart';
import '../../features/room/providers/room_policy_provider.dart';
import '../../features/room/providers/room_gift_provider.dart';
import '../../features/room/providers/user_cam_permissions_provider.dart';
import '../../features/room/providers/cam_view_request_provider.dart';
import '../../features/room/providers/room_slot_provider.dart';
import '../../dev/room_inspector_panel.dart';
import '../../features/room/room_permissions.dart';
import '../../features/room/models/room_theme_model.dart';
import '../../features/room/widgets/background_picker_sheet.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/agora_service.dart';
import '../../services/rtc_room_service.dart';
import '../../services/webrtc_room_service_shim.dart';
import '../../services/follow_service.dart';
import '../../services/moderation_service.dart';
import '../../services/presence_repository.dart';
import '../../services/room_audio_cues.dart';
import '../../features/room/repository/room_repository.dart';
import '../../core/events/app_event.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/providers/firebase_providers.dart';
import '../../shared/widgets/beta_feedback_overlay.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../core/theme.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LiveRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

// roomParticipantHasMicAccess and roomParticipantCanBeShownAsTalking were
// removed — mic/talking authority is derived exclusively from
// state.isOnMicByAuthority() on the controller state.

const Duration _kRoomRemovalGraceWindow = Duration(seconds: 8);

bool shouldEjectJoinedUserFromRoom({
  required bool hasTrackedRoomJoin,
  bool isJoiningRoom = false,
  bool hasCurrentParticipant = false,
  bool isUserInResolvedRoomState = false,
  RoomMembershipState? membershipState,
  required DateTime? lastConfirmedMembershipAt,
  DateTime? now,
  Duration graceWindow = _kRoomRemovalGraceWindow,
}) {
  if (!hasTrackedRoomJoin) {
    return false;
  }

  final authoritativeMembership =
      membershipState?.isAuthoritativeMember ??
      (hasCurrentParticipant || isUserInResolvedRoomState);
  final shouldHoldRemoval =
      membershipState?.shouldDeferRemoval ?? isJoiningRoom;

  if (authoritativeMembership || shouldHoldRemoval) {
    return false;
  }

  final confirmedAt = lastConfirmedMembershipAt;
  if (confirmedAt == null) {
    return false;
  }

  return (now ?? DateTime.now()).difference(confirmedAt) >= graceWindow;
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  late TextEditingController messageController;
  late TextEditingController _secretMessageController;
  late FocusNode _chatInputFocusNode;
  late FocusNode _secretInputFocusNode;
  late ScrollController scrollController;
  String? _joinedUserId;
  DateTime? lastMessageTime;
  int slowModeSeconds = 0;
  bool isSending = false;
  String cooldownMessage = '';
  bool _isJoiningRoom = false;
  bool _isTearingDown = false;
  String? _roomJoinError;
  String? _lastAutoJoinAttemptUserId;
  bool _hasTrackedRoomJoin = false;
  bool _hasTrackedFirstMessage = false;
  RtcRoomService? _agoraService;

  /// Order of the three desktop columns. Valid values: 'cams', 'chat', 'users'.
  List<String> _columnOrder = const ['cams', 'chat', 'users'];
  double _chatColW = 280.0;
  static const double _kUsersColW = 260.0;

  /// Mobile tab: 0=Camera, 1=Chat, 2=People  (only used when width < 640)
  int _mobileTab = 0;

  void _moveSlot(String slot, int dir) {
    final list = List<String>.from(_columnOrder);
    final i = list.indexOf(slot);
    final j = i + dir;
    if (j >= 0 && j < list.length) {
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
      setState(() => _columnOrder = List.unmodifiable(list));
    }
  }

  // Volume controls — persisted only for the lifetime of the room session.
  double _micVolume = 1.0;
  double _speakerVolume = 1.0;
  bool _showVolumeControls = false;
  bool _showEmojiTray = false;
  bool _showRichToolbar = false;
  String? _pendingRichColorHex;

  /// Prevents re-triggering camera toggle (double-click / web event replay).
  DateTime? _videoToggleCooldownUntil;
  Set<String> _excludedUserIds = const <String>{};
  bool _isHandlingParticipantRemoval = false;
  bool _isVerifyingUnexpectedRemoval = false;
  bool _preWarmDone = false;
  DateTime? _lastConfirmedRoomMembershipAt;

  String _buildOutgoingChatMessage(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (_pendingRichColorHex == null || trimmed.contains('[color=')) {
      return trimmed;
    }
    return '[color=$_pendingRichColorHex]$trimmed[/color]';
  }

  Timer? _micLevelTimer;
  DateTime? _roomJoinedAt;
  int _lastRenderedMessageCount = 0;
  final Set<String> _recentChatters = {};
  final Map<String, Timer> _recentChatterTimers = {};
  final Set<String> _shownGiftEventIds = {};
  final List<_GiftToast> _giftToasts = [];
  Timer? _giftToastTimer;
  Timer? _typingTimer;
  bool _typingStatusActive = false;
  DateTime? _lastTypingWriteAt;
  final GlobalKey<FloatingGiftOverlayState> _floatingGiftKey =
      GlobalKey<FloatingGiftOverlayState>();
  final GlobalKey<BuzzOverlayState> _buzzKey = GlobalKey<BuzzOverlayState>();
  late final LiveRoomController _roomController;
  late final LiveRoomMediaController _liveRoomMediaNotifier;
  late final ProviderSubscription<LiveRoomMediaState> _mediaStateSubscription;
  LiveRoomMediaState _latestMediaState = const LiveRoomMediaState();
  final Set<String> _shownBuzzIds = {};
  String? _activeCamViewRequestId;
  ProviderSubscription<AsyncValue<List<RoomGiftEvent>>>?
  _giftEventsSubscription;

  // Reconnect back-off state
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Fires when the stage user's mic-play-time limit expires; auto-releases mic.
  Timer? _micExpiryTimer;
  DateTime? _scheduledMicExpiresAt;
  static const int _kMaxBackoffSeconds = 30;
  static const Duration _kTypingIdleTimeout = Duration(seconds: 3);
  static const Duration _kTypingWriteThrottle = Duration(seconds: 4);
  final Map<String, String> _senderDisplayNameById = <String, String>{};
  final Map<String, int> _senderVipLevelById = <String, int>{};

  /// GlobalKeys for remote RTCVideoViews — lets Flutter move the platform-view
  /// element atomically when a tile is detached/reattached (avoids black screen).
  final Map<int, GlobalKey> _remoteViewKeys = {};
  GlobalKey _remoteViewKey(int uid) =>
      _remoteViewKeys.putIfAbsent(uid, () => GlobalKey());
  final GlobalKey _localViewMoveKey = GlobalKey();
  final Map<String, String?> _senderAvatarUrlById = <String, String?>{};
  final Map<String, String?> _senderGenderById = <String, String?>{};
  final Set<String> _senderLookupInFlight = <String>{};
  RoomParticipantModel? _secretComposerTarget;
  bool _isSendingSecretMessage = false;
  bool _remoteLayoutSyncQueued = false;
  bool _roleMediaStatePending = false;

  /// Cached from the room stream — avoids a Firestore .get() on every cam toggle.
  int _maxBroadcasters = 4;
  static const List<String> _quickEmojis = <String>[
    '😀',
    '😂',
    '😍',
    '🔥',
    '👏',
    '🙏',
    '💯',
    '🎉',
    '❤️',
    '👍',
    '👀',
    '😎',
  ];

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  bool get _hasFirebaseApp {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  LiveRoomMediaState get _mediaState => _latestMediaState;

  LiveRoomMediaController get _mediaController => _liveRoomMediaNotifier;

  bool get _isCallConnecting => _mediaState.isCallConnecting;
  bool get _isCallReady => _mediaState.isCallReady;
  bool get _isMicMuted => _mediaState.isMicMuted;
  bool get _isVideoEnabled => _mediaState.isVideoEnabled;
  bool get _isSharingSystemAudio => _mediaState.isSharingSystemAudio;
  bool get _isSystemAudioActionInFlight =>
      _mediaState.isSystemAudioActionInFlight;
  bool get _isMicActionInFlight => _mediaState.isMicActionInFlight;
  bool get _isVideoActionInFlight => _mediaState.isVideoActionInFlight;
  String? get _cameraStatus => _mediaState.cameraStatus;
  String? get _callError => _mediaState.callError;
  int? get _currentRtcUid => _mediaState.currentRtcUid;
  String? get _claimedSlotId => _mediaState.claimedSlotId;
  String? get _appliedMediaRole => _mediaState.appliedMediaRole;
  RoomAudioState? get _appliedAudioState => _mediaState.appliedAudioState;
  Set<int> get _requestedHighQualityRemoteUids =>
      _mediaState.requestedHighQualityRemoteUids;
  Set<int> get _requestedLowQualityRemoteUids =>
      _mediaState.requestedLowQualityRemoteUids;
  int get _localViewEpoch => _mediaState.localViewEpoch;

  @override
  void initState() {
    super.initState();
    _roomController = ref.read(
      liveRoomControllerProvider(widget.roomId).notifier,
    );
    _liveRoomMediaNotifier = ref.read(
      liveRoomMediaControllerProvider(widget.roomId).notifier,
    );
    _mediaStateSubscription = ref.listenManual<LiveRoomMediaState>(
      liveRoomMediaControllerProvider(widget.roomId),
      (_, next) {
        _latestMediaState = next;
      },
      fireImmediately: true,
    );
    messageController = TextEditingController();
    _secretMessageController = TextEditingController();
    _chatInputFocusNode = FocusNode(debugLabel: 'roomChatInput');
    _secretInputFocusNode = FocusNode(debugLabel: 'roomSecretInput');
    scrollController = ScrollController();

    final user = ref.read(userProvider);
    if (user != null) {
      _joinedUserId = user.id;
      // Pre-seed the local cache immediately, but defer provider writes until
      // after the first frame so the room joins cleanly without provider churn.
      if (user.username.trim().isNotEmpty) {
        _senderDisplayNameById[user.id] = user.username.trim();
      }
      _senderAvatarUrlById[user.id] = (user.avatarUrl?.isNotEmpty == true)
          ? user.avatarUrl
          : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (user.username.trim().isNotEmpty) {
          _roomController.cacheDisplayName(
            userId: user.id,
            displayName: user.username,
          );
        }
        _lastAutoJoinAttemptUserId = user.id;
        _joinRoom(user.id);
        if (!kIsWeb && _hasFirebaseApp) {
          // Pre-warm the Agora SDK in the background (mobile only) so WASM
          // cold-start completes before the user taps the camera button.
          _preWarmAgora(user.id);
        }
      });
    }

    _giftEventsSubscription = ref.listenManual<AsyncValue<List<RoomGiftEvent>>>(
      roomGiftStreamProvider(widget.roomId),
      (previous, next) {
        next.whenData((events) {
          final joinedAt = _roomJoinedAt;
          for (final event in events) {
            if (_shownGiftEventIds.contains(event.id)) continue;
            if (joinedAt != null && event.sentAt.isBefore(joinedAt)) {
              _shownGiftEventIds.add(event.id);
              continue;
            }
            _shownGiftEventIds.add(event.id);
            _addGiftToast(event);
          }
        });
      },
    );

    // Listen for incoming buzzes and trigger the overlay.
    if (user != null) {
      ref.listenManual<AsyncValue<List<BuzzEvent>>>(
        incomingBuzzStreamProvider((
          roomId: widget.roomId,
          currentUserId: user.id,
        )),
        (_, next) {
          next.whenData((buzzes) {
            final joinedAt = _roomJoinedAt;
            for (final buzz in buzzes) {
              if (_shownBuzzIds.contains(buzz.id)) continue;
              if (joinedAt != null && buzz.sentAt.isBefore(joinedAt)) {
                _shownBuzzIds.add(buzz.id);
                continue;
              }
              _shownBuzzIds.add(buzz.id);
              final senderName =
                  _senderDisplayNameById[buzz.fromUserId] ?? buzz.fromUserId;
              RoomAudioCues.instance.playBuzz();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _buzzKey.currentState?.triggerBuzz('$senderName buzzed you! ⚡');
              });
            }
          });
        },
      );
    }

    // Listen for incoming cam-view requests directed at the current user.
    if (user != null) {
      ref.listenManual<AsyncValue<List<CamViewRequest>>>(
        pendingCamViewRequestsProvider((
          roomId: widget.roomId,
          targetId: user.id,
        )),
        (_, next) {
          next.whenData((requests) {
            if (_activeCamViewRequestId != null &&
                requests.every(
                  (request) => request.id != _activeCamViewRequestId,
                )) {
              _activeCamViewRequestId = null;
            }
            if (_activeCamViewRequestId != null || requests.isEmpty) {
              return;
            }
            final request = requests.first;
            _activeCamViewRequestId = request.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _handleIncomingCamViewRequest(request);
            });
          });
        },
      );
    }
  }

  /// Silently fetch a token + initialize the Agora engine in the background
  /// so the WASM cold-start is done before the user taps "Turn on cam".
  Future<void> _preWarmAgora(String userId) async {
    // Small delay so the room join HTTP calls get priority first.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _preWarmDone || _isCallReady || _isCallConnecting) return;
    try {
      final rtcUid = _buildRtcUid(userId);
      final credentials = await _fetchAgoraToken(
        channelName: widget.roomId,
        rtcUid: rtcUid,
      );
      if (!mounted || _preWarmDone || _isCallReady || _isCallConnecting) return;
      final warmService = AgoraService();
      await warmService.initialize(credentials.appId);
      // Don't join the channel — just getting the SDK ready.
      await warmService.dispose();
      if (mounted) {
        _preWarmDone = true;
      }
      _logLiveRoom('prewarm:done');
    } catch (e) {
      // Pre-warm is best-effort; failures are silent.
      _logLiveRoom('prewarm:failed (non-fatal)', error: e);
    }
  }

  int _buildRtcUid(String userId) {
    return userId.hashCode.abs() % 2147483647;
  }

  /// Fetches ICE servers from the `generateTurnCredentials` Cloud Function.
  /// The function calls Metered server-side so the API key is never exposed
  /// in the client bundle. Falls back to Google STUN on any error.
  Future<List<Map<String, dynamic>>> _fetchIceServers() {
    return ref.read(roomRepositoryProvider).fetchIceServers();
  }

  String? _userIdForRtcUid(int rtcUid, List<RoomParticipantModel> members) {
    // WebRTC service has an explicit uid→userId map; use it directly to avoid
    // the hash-based lookup failing when participants haven't loaded yet.
    final fromService = _agoraService?.userIdForUid(rtcUid);
    if (fromService != null) return fromService;
    // Agora fallback: match by reconstructing the uid from each participant's
    // userId hash.
    for (final member in members) {
      if (_buildRtcUid(member.userId) == rtcUid) {
        return member.userId;
      }
    }
    return null;
  }

  RoomPresenceModel? _roomPresenceForUser(
    List<RoomPresenceModel> presenceList,
    String userId,
  ) {
    for (final presence in presenceList) {
      if (presence.userId == userId) {
        return presence;
      }
    }
    return null;
  }

  void _syncTelemetryForBuild({
    required String currentUserId,
    required LiveRoomState roomState,
    required List<RoomParticipantModel> participantsInRoom,
    required RoomParticipantModel? currentParticipant,
    required List<RoomPresenceModel> presenceList,
    required PresenceModel? globalPresence,
  }) {
    final currentRoomPresence = _roomPresenceForUser(
      presenceList,
      currentUserId,
    );
    final isJoined = _joinedUserId == currentUserId;
    final globalPresenceMismatch =
        globalPresence != null &&
        (((globalPresence.isOnline ?? false) == false) ||
            globalPresence.inRoom != widget.roomId);
    final roomPresenceMismatch =
        currentRoomPresence != null &&
        currentRoomPresence.userStatus == 'offline';
    final cameraMismatch =
        isJoined && _isVideoEnabled && currentParticipant?.camOn != true;
    final authorityMicOn = roomState.isOnMicByAuthority(currentUserId);
    final micMismatch = isJoined && authorityMicOn != !_isMicMuted;

    AppTelemetry.updateRoomState(
      roomId: widget.roomId,
      joinedUserId: _joinedUserId,
      roomPhase: roomState.phase.name,
      roomError: _roomJoinError ?? roomState.errorMessage,
      participantCount: participantsInRoom.length,
      micMuted: _isMicMuted,
      videoEnabled: _isVideoEnabled,
      presenceStatus: globalPresence?.status.name,
      roomPresenceStatus:
          currentRoomPresence?.userStatus ?? currentParticipant?.userStatus,
      globalPresenceOnline: globalPresence?.isOnline,
      inRoom: globalPresence?.inRoom,
      cameraStatus: _cameraStatus,
      callError: _callError,
      currentRtcUid: _currentRtcUid,
      cameraMismatch: cameraMismatch,
      micMismatch: micMismatch,
      presenceMismatch:
          isJoined && (globalPresenceMismatch || roomPresenceMismatch),
    );
  }

  void _logLiveRoom(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'LIVE_ROOM');
    debugPrint('[LIVE_ROOM] $message');
    AppTelemetry.logAction(
      level: error == null ? 'info' : 'error',
      domain: 'room',
      action: 'live_trace',
      message: message,
      roomId: widget.roomId,
      userId: _joinedUserId,
      result: error == null ? 'ok' : 'error',
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) {
      developer.log(
        'error: $error',
        name: 'LIVE_ROOM',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[LIVE_ROOM] error: $error');
    }
  }

  bool _sameIntSet(Set<int> left, Set<int> right) {
    return left.length == right.length && left.containsAll(right);
  }

  void _scheduleRemoteVideoLayoutSync({
    required Set<int> highQualityUids,
    required Set<int> lowQualityUids,
  }) {
    final normalizedHighQuality = Set<int>.from(highQualityUids);
    final normalizedLowQuality = Set<int>.from(lowQualityUids)
      ..removeWhere(normalizedHighQuality.contains);

    if (_sameIntSet(_requestedHighQualityRemoteUids, normalizedHighQuality) &&
        _sameIntSet(_requestedLowQualityRemoteUids, normalizedLowQuality)) {
      return;
    }

    _mediaController.updateRequestedRemoteQualities(
      highQualityUids: normalizedHighQuality,
      lowQualityUids: normalizedLowQuality,
    );

    if (_remoteLayoutSyncQueued) {
      return;
    }

    _remoteLayoutSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remoteLayoutSyncQueued = false;
      final service = _agoraService;
      if (!mounted || service == null || !_isCallReady) {
        return;
      }

      final highQuality = Set<int>.from(_requestedHighQualityRemoteUids);
      final lowQuality = Set<int>.from(_requestedLowQualityRemoteUids);
      for (final uid in service.remoteUids) {
        final wantsHighQuality = highQuality.contains(uid);
        final wantsLowQuality = lowQuality.contains(uid);
        unawaited(
          service.setRemoteVideoSubscription(
            uid,
            subscribe: wantsHighQuality || wantsLowQuality,
            highQuality: wantsHighQuality,
          ),
        );
      }
    });
  }

  Future<({String token, String appId})> _fetchAgoraToken({
    required String channelName,
    required int rtcUid,
  }) {
    return ref
        .read(roomRepositoryProvider)
        .fetchAgoraToken(
          channelName: channelName,
          rtcUid: rtcUid,
          fallbackAppId: AgoraConstants.appId,
        );
  }

  Future<T> _runWithWatchdog<T>({
    required String phase,
    required Duration timeout,
    required String timeoutCode,
    required String timeoutMessage,
    required Future<T> Function() action,
  }) async {
    if (mounted) {
      _mediaController.setConnectPhase(phase);
    }
    return action().timeout(
      timeout,
      onTimeout: () => throw AgoraServiceException(
        code: timeoutCode,
        message: timeoutMessage,
      ),
    );
  }

  String _extractErrorCode(Object error) {
    if (error is AgoraServiceException) {
      return error.code;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('timeout')) {
      return 'timeout';
    }
    if (text.contains('permission')) {
      return 'permission-denied';
    }
    return 'unknown';
  }

  void _syncMediaUiFromService() {
    final service = _agoraService;
    if (!mounted || service == null) return;
    final nextVideoEnabled = service.isLocalVideoCapturing;
    final nextMicMuted = service.isLocalAudioMuted;
    final nextSystemAudio = service.isSharingSystemAudio;
    _mediaController.syncFromService(
      isVideoEnabled: nextVideoEnabled,
      isMicMuted: nextMicMuted,
      isSharingSystemAudio: nextSystemAudio,
    );
    _syncMicLevelPolling();
  }

  void _syncMicLevelPolling() {
    final shouldPoll = shouldTrackMicLevel(
      isCallReady: _isCallReady,
      hasRtcService: _agoraService != null,
      isMicMuted: _isMicMuted,
    );
    if (shouldPoll) {
      if (_micLevelTimer?.isActive != true) {
        _startMicLevelPolling();
      }
      return;
    }
    _stopMicLevelPolling();
  }

  /// Wires up the common callbacks on any [RtcRoomService] implementation.
  void _attachServiceCallbacks(RtcRoomService service) {
    service.onRemoteUserJoined = () {
      RoomAudioCues.instance.playUserJoined();
      if (mounted) {
        setState(() {});
        // Immediately resolve display names for any UIDs whose userId mapping
        // is now known but whose name hasn't been fetched yet.  This means
        // tiles show a real name the moment they appear instead of "Guest UID"
        // until the Firestore participants stream delivers the participant doc.
        final newUserIds = service.remoteUids
            .map((uid) => service.userIdForUid(uid))
            .whereType<String>()
            .where((id) => !_senderDisplayNameById.containsKey(id))
            .toList(growable: false);
        if (newUserIds.isNotEmpty) {
          _hydrateSenderDisplayNames(
            userIds: newUserIds,
            currentUserId: _joinedUserId ?? '',
          );
        }
      }
    };
    service.onRemoteUserLeft = () {
      RoomAudioCues.instance.playUserLeft();
      if (mounted) setState(() {});
    };
    service.onSpeakerActivityChanged = () {
      _syncMediaUiFromService();
      if (mounted) setState(() {});
    };
    service.onLocalVideoCaptureChanged = () {
      _syncMediaUiFromService();
      if (mounted) setState(() {});
    };
    service.onTokenWillExpire = () {
      _logLiveRoom('token_will_expire: scheduling renewal');
      _renewAgoraToken();
    };
    service.onConnectionLost = () {
      _logLiveRoom('connection_lost: scheduling reconnect');
      _handleConnectionLost();
    };
  }

  Future<void> _connectCall(String userId) async {
    if (_isCallConnecting || _isCallReady) return;

    _mediaController.beginConnecting();

    RtcRoomService? connectedService;

    try {
      _logLiveRoom('connect:start user=$userId room=${widget.roomId}');
      final rtcUid = _buildRtcUid(userId);

      final transportController = ref.read(webrtcControllerProvider);

      if (kIsWeb) {
        // ── WebRTC path (web only) ────────────────────────────────────────
        // Browser-native WebRTC. No WASM to download → initialises instantly.
        // Firestore is used for signaling (offer/answer/ICE).
        _logLiveRoom('connect:webrtc_path uid=$rtcUid');
        if (mounted) {
          _mediaController.setCameraStatus('Connecting to live room…');
        }
        final iceServers = await _fetchIceServers();
        final service = await transportController.createTransport(
          userId: userId,
          iceServers: iceServers,
        );
        _attachServiceCallbacks(service);
        await _runWithWatchdog<void>(
          phase: 'webrtc-init',
          timeout: const Duration(seconds: 5),
          timeoutCode: 'webrtc-initialize-failed',
          timeoutMessage: 'Failed to initialise WebRTC.',
          action: () => service.initialize(''),
        );
        await _runWithWatchdog<void>(
          phase: 'webrtc-join',
          timeout: const Duration(seconds: 10),
          timeoutCode: 'webrtc-join-failed',
          timeoutMessage: 'Timed out joining live media mesh.',
          action: () => service.joinRoom(
            '',
            widget.roomId,
            rtcUid,
            publishCameraTrackOnJoin: false,
            publishMicrophoneTrackOnJoin: false,
          ),
        );
        connectedService = service;
        _logLiveRoom('connect:webrtc_joined uid=$rtcUid');
      } else {
        // ── Agora path (native mobile) ────────────────────────────────────
        if (mounted) {
          _mediaController.setCameraStatus('Connecting: requesting token...');
        }
        final credentials =
            await _runWithWatchdog<({String token, String appId})>(
              phase: 'token',
              timeout: const Duration(seconds: 12),
              timeoutCode: 'agora-token-missing',
              timeoutMessage: 'Timed out fetching live media token.',
              action: () =>
                  _fetchAgoraToken(channelName: widget.roomId, rtcUid: rtcUid),
            );
        _logLiveRoom('connect:token_ok uid=$rtcUid');

        const maxConnectAttempts = 2;
        for (var attempt = 1; attempt <= maxConnectAttempts; attempt++) {
          final service = await transportController.createTransport(
            userId: userId,
          );
          _attachServiceCallbacks(service);

          try {
            if (mounted) {
              _mediaController.setCameraStatus(
                attempt == 1
                    ? 'Connecting: initializing media engine…'
                    : 'Retrying media engine initialization…',
              );
            }
            _logLiveRoom('connect:agora_init attempt=$attempt');
            await _runWithWatchdog<void>(
              phase: 'init-attempt-$attempt',
              timeout: const Duration(seconds: 30),
              timeoutCode: 'agora-initialize-live-media-failed',
              timeoutMessage: 'Timed out initializing live media engine.',
              action: () => service.initialize(credentials.appId),
            );
            _logLiveRoom('connect:agora_initialized attempt=$attempt');
            if (mounted) {
              _mediaController.setCameraStatus(
                'Connecting: joining live room...',
              );
            }
            await _runWithWatchdog<void>(
              phase: 'join-attempt-$attempt',
              timeout: const Duration(seconds: 25),
              timeoutCode: 'agora-join-room-failed',
              timeoutMessage: 'Timed out joining live media channel.',
              action: () => service.joinRoom(
                credentials.token,
                widget.roomId,
                rtcUid,
                publishCameraTrackOnJoin: false,
                publishMicrophoneTrackOnJoin: false,
              ),
            );
            connectedService = service;
            _logLiveRoom('connect:agora_joined attempt=$attempt');
            break;
          } catch (error, stackTrace) {
            _logLiveRoom(
              'connect:agora_attempt_failed attempt=$attempt',
              error: error,
              stackTrace: stackTrace,
            );
            await service.dispose();
            final errorCode = _extractErrorCode(error);
            final canRetry =
                attempt < maxConnectAttempts &&
                errorCode == 'agora-initialize-live-media-failed';
            if (canRetry) {
              if (mounted) {
                _mediaController.markRetryingInitialization();
              }
              await Future<void>.delayed(const Duration(milliseconds: 450));
              continue;
            }

            rethrow;
          }
        } // end for-loop (Agora retry)
      } // end else-Agora-path

      if (connectedService == null) {
        throw const AgoraServiceException(
          code: 'agora-initialize-live-media-failed',
          message: 'Unable to initialize live media engine.',
        );
      }

      if (!mounted) {
        await connectedService.dispose();
        return;
      }
      // Auto-sync UI when system-audio sharing stops externally (Chrome bar X).
      // Cast needed: onSystemAudioStopped is only on WebRtcRoomService.
      if (connectedService is WebRtcRoomService) {
        connectedService.onSystemAudioStopped = () {
          if (mounted) {
            _mediaController.markSystemAudioStopped();
          }
        };
      }
      setState(() {
        _agoraService = connectedService;
      });
      _mediaController.markReady(
        rtcUid: rtcUid,
        cameraStatus: 'Live media ready. Tap camera to publish.',
      );
      _syncMediaUiFromService();
    } catch (e, stackTrace) {
      _logLiveRoom('connect:failed', error: e, stackTrace: stackTrace);
      if (connectedService != null) {
        await connectedService.dispose();
      }
      if (mounted) {
        final errorCode = _extractErrorCode(e);
        final mappedError =
            errorCode == 'agora-initialize-live-media-failed' ||
                errorCode == 'webrtc-initialize-failed' ||
                errorCode == 'webrtc-join-failed'
            ? "We couldn't connect to the live room. Check your connection and try again."
            : _mapMediaError(e, canBroadcast: true);
        final debugSuffix = e is AgoraServiceException
            ? ' [${e.code}] ${e.cause ?? e.message}'
            : ' [$e]';
        final callError = '$mappedError$debugSuffix';
        _mediaController.markConnectionFailed(
          callError: callError,
          cameraStatus:
              'Live media connect failed (phase=failed code=$errorCode): $callError',
        );
      }
    }
  }

  Future<void> _toggleMic() async {
    final service = _agoraService;
    final liveRoomState = ref.read(liveRoomControllerProvider(widget.roomId));
    if (service == null || !_isCallReady || _isMicActionInFlight) return;

    final audioState = liveRoomState.audioState;
    if (audioState == RoomAudioState.requestingMic) {
      _showSnackBar('Your mic request is still pending.');
      return;
    }
    if (audioState == RoomAudioState.denied || !liveRoomState.canPublishAudio) {
      _showSnackBar('Grab Mic first to speak in the room.');
      return;
    }

    final next = !_isMicMuted;
    AppTelemetry.logAction(
      domain: 'room',
      action: 'toggle_mic',
      message: 'Mic toggle requested.',
      roomId: widget.roomId,
      userId: _joinedUserId,
      result: next ? 'enable' : 'disable',
    );
    _mediaController.beginMicAction();
    try {
      await service.syncAudio(audioState, shouldMute: next);
      if (mounted) {
        _mediaController.finishMicAction(isMuted: next);
      }
      _syncMediaUiFromService();
      final micUserId = _joinedUserId;
      if (micUserId != null) {
        unawaited(
          ref
              .read(rtdbPresenceServiceProvider)
              .setMicOn(micUserId, micOn: !next),
        );
      }
      _syncMicLevelPolling();
      AppTelemetry.logAction(
        domain: 'room',
        action: 'toggle_mic',
        message: 'Mic toggle completed.',
        roomId: widget.roomId,
        userId: _joinedUserId,
        result: next ? 'live' : 'muted',
      );
    } catch (e) {
      AppTelemetry.logAction(
        level: 'error',
        domain: 'room',
        action: 'toggle_mic',
        message: 'Mic toggle failed.',
        roomId: widget.roomId,
        userId: _joinedUserId,
        result: 'error',
        error: e,
      );
      _showSnackBar(_mapMediaError(e, canBroadcast: true));
    } finally {
      if (mounted) {
        _mediaController.endMicAction();
      }
    }
  }

  void _startMicLevelPolling() {
    _micLevelTimer?.cancel();
    _micLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_isMicMuted) setState(() {});
    });
  }

  void _stopMicLevelPolling() {
    _micLevelTimer?.cancel();
    _micLevelTimer = null;
  }

  // ── Volume helpers ─────────────────────────────────────────────────────────

  Future<void> _setMicVolume(double v) async {
    setState(() => _micVolume = v);
    await _agoraService?.setMicVolume(v);
  }

  Future<void> _setSpeakerVolume(double v) async {
    setState(() => _speakerVolume = v);
    await _agoraService?.setSpeakerVolume(v);
  }

  /// Shows a step-by-step guide telling the user how to share PC audio in
  /// Chrome/Edge before the getDisplayMedia picker is opened.
  /// Returns true when the user confirms they want to proceed.
  Future<bool> _showSystemAudioGuide() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.headset, size: 24, color: Color(0xFF7C5FFF)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Share PC audio',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(sheetCtx).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Chrome will open a screen-share picker. Follow these steps so others can hear your audio:',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              _SystemAudioStep(
                number: '1',
                text: 'Choose the tab or window you want to share audio from.',
              ),
              const SizedBox(height: 8),
              _SystemAudioStep(
                number: '2',
                icon: Icons.check_box,
                text:
                    'Check "Share system audio" (the checkbox near the bottom of the picker).',
              ),
              const SizedBox(height: 8),
              _SystemAudioStep(
                number: '3',
                text: 'Click Share — your PC audio streams to the room.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open Share Picker'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C5FFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    return confirmed == true;
  }

  Future<void> _toggleSystemAudio() async {
    final service = _agoraService;
    if (service == null || !_isCallReady || _isSystemAudioActionInFlight) {
      return;
    }

    // When starting (not stopping), show the guide so the user knows to check
    // "Share system audio" in Chrome's picker before clicking Share.
    if (!_isSharingSystemAudio) {
      final proceed = await _showSystemAudioGuide();
      if (!proceed || !mounted) return;
    }

    _mediaController.beginSystemAudioAction();
    try {
      await service.shareSystemAudio(!_isSharingSystemAudio);
      if (mounted) {
        _mediaController.finishSystemAudioAction(
          isSharing: !_isSharingSystemAudio,
        );
      }
    } catch (e) {
      _showSnackBar(_mapMediaError(e, canBroadcast: true));
    } finally {
      if (mounted) _mediaController.endSystemAudioAction();
    }
  }

  Future<void> _toggleVideo() async {
    _logLiveRoom(
      'toggle_video:start enabled=$_isVideoEnabled callReady=$_isCallReady inFlight=$_isVideoActionInFlight',
    );
    final service = _agoraService;
    _logLiveRoom(
      'toggle_video:precheck service=${service != null} callReady=$_isCallReady inFlight=$_isVideoActionInFlight',
    );

    // Prevent immediate double-fire (e.g. Flutter web button replay on rebuild).
    if (_videoToggleCooldownUntil != null &&
        DateTime.now().isBefore(_videoToggleCooldownUntil!)) {
      _logLiveRoom('toggle_video:blocked cooldown');
      return;
    }

    if (service == null || !_isCallReady || _isVideoActionInFlight) {
      if (service == null) {
        _logLiveRoom('toggle_video:blocked service_null');
        if (mounted) {
          _mediaController.blockVideoAction(
            'Camera blocked: live media service not initialized.',
          );
        }
        _showSnackBar('Agora service not initialized.');
      } else if (!_isCallReady) {
        _logLiveRoom('toggle_video:blocked call_not_ready');
        if (mounted) {
          _mediaController.blockVideoAction(
            'Camera blocked: live media not ready yet.',
          );
        }
        _showSnackBar('Call not ready. Wait a moment and retry.');
      } else {
        _logLiveRoom('toggle_video:blocked already_in_flight');
        if (mounted) {
          _mediaController.blockVideoAction(
            'Camera action already in progress...',
          );
        }
        _showSnackBar('Camera action in progress...');
      }
      return;
    }

    final next = !_isVideoEnabled;
    _logLiveRoom(
      'toggle_video:next=$next broadcaster=${service.isBroadcaster} joined=${service.isJoinedChannel}',
    );
    _mediaController.beginVideoAction(
      next ? 'Starting camera...' : 'Stopping camera...',
    );
    try {
      if (next) {
        if (mounted) {
          _mediaController.setCameraStatus(
            'Requesting browser camera access...',
          );
        }

        // Claim a broadcaster slot in Firebase before enabling the camera.
        // If no slot is available the request is blocked with feedback.
        final userId = _joinedUserId;
        if (userId != null) {
          final slotService = ref.read(roomSlotServiceProvider);
          final slotId = await slotService.claimSlot(
            widget.roomId,
            userId,
            maxBroadcasters: _maxBroadcasters,
          );
          if (slotId == null) {
            if (mounted) {
              _mediaController.failVideoAction('All camera slots are full.');
              _showSnackBar('All camera slots are full. Try again later.');
            }
            return;
          }
          _mediaController.setClaimedSlotId(slotId);
          _logLiveRoom('slot_claimed: slotId=$slotId');
        }

        // enableVideo handles broadcaster role, channel options, startPreview, and
        // local video capture wait. Pass the current mic mute state so enabling
        // the camera does not silently re-enable a muted microphone.
        await service.enableVideo(true, publishMicrophoneTrack: !_isMicMuted);
        if (mounted) {
          _mediaController.setAppliedMediaRole('member');
        }
      } else {
        // Turning camera off — release the slot (fire-and-forget to Firestore).
        // Do NOT clear _claimedSlotId here; clear it atomically with
        // _isVideoEnabled in the success setState below to avoid a race window
        // where _claimedSlotId==null but _isVideoEnabled==true, which would
        // let the role-media sync re-enable the camera mid-teardown.
        final userId = _joinedUserId;
        if (userId != null && _claimedSlotId != null) {
          final slotService = ref.read(roomSlotServiceProvider);
          unawaited(slotService.releaseSlot(widget.roomId, userId));
        }
        _logLiveRoom('toggle_video:step enableVideo(false)');
        await service.enableVideo(false);
        _logLiveRoom('toggle_video:step enableVideo(false) completed');
        // enableVideo(false) now keeps Agora in broadcaster role; only the
        // camera track is stopped. Re-publish audio if the mic was not muted.
        // Best-effort: a failure here must NOT abort the cam-off success path.
        if (!_isMicMuted && mounted) {
          _logLiveRoom('toggle_video:restoring_mic_after_cam_off');
          try {
            await service.publishLocalAudioStream(true);
          } catch (e) {
            _logLiveRoom('toggle_video:mic_restore_failed', error: e);
            // Mic track could not be restored; mark mic muted to reflect reality.
            if (mounted) _mediaController.setMicMuted(true);
          }
        }
      }

      _logLiveRoom('toggle_video:success next=$next mounted=$mounted');
      // Only commit the state change if the AgoraService reference hasn't
      // been replaced (e.g. by _handleConnectionLost mid-enable). On web,
      // _awaitLocalVideoCapturing times out silently, so enableVideo() returns
      // success even after the old service was disposed and a new one created.
      if (mounted && identical(service, _agoraService)) {
        _mediaController.finishVideoAction(
          isVideoEnabled: next,
          claimedSlotId: next ? _claimedSlotId : null,
          appliedMediaRole: next ? 'member' : null,
          cameraStatus: next ? 'Camera active.' : 'Camera off.',
        );
        _syncMediaUiFromService();
        // Mirror cam state into RTDB so onDisconnect clears it automatically.
        final camUserId = _joinedUserId;
        if (camUserId != null) {
          unawaited(
            ref
                .read(rtdbPresenceServiceProvider)
                .setCamOn(camUserId, camOn: next),
          );
        }
        if (next) {
          Future<void>.delayed(const Duration(milliseconds: 450), () {
            if (mounted) setState(() {});
          });
          final myName =
              _senderDisplayNameById[_joinedUserId ?? ''] ??
              (_joinedUserId ?? '');
          if (myName.isNotEmpty) {
            _sendSystemEvent('$myName turned on their camera 📷');
          }
          if ((_joinedUserId ?? '').isNotEmpty) {
            AppEventBus.instance.emit(
              CameraStateChangedEvent(
                id: 'camera:${widget.roomId}:${_joinedUserId!}:on:${DateTime.now().millisecondsSinceEpoch}',
                timestamp: DateTime.now(),
                sessionId: AppEventIds.roomSession(
                  roomId: widget.roomId,
                  userId: _joinedUserId!,
                ),
                correlationId: AppEventIds.cameraCorrelation(
                  roomId: widget.roomId,
                  userId: _joinedUserId!,
                ),
                userId: _joinedUserId!,
                roomId: widget.roomId,
                isCameraOn: true,
              ),
            );
          }
        } else {
          final myName =
              _senderDisplayNameById[_joinedUserId ?? ''] ??
              (_joinedUserId ?? '');
          if (myName.isNotEmpty) {
            _sendSystemEvent('$myName turned off their camera');
          }
        }
        final msg = next ? 'Camera turned on.' : 'Camera turned off.';
        _logLiveRoom('toggle_video:success_message $msg');
        _showSnackBar(msg);
      } else if (mounted && !identical(service, _agoraService)) {
        _logLiveRoom(
          'toggle_video:stale_success ignored (service replaced during operation)',
        );
      }
    } catch (e, st) {
      _logLiveRoom('toggle_video:failed', error: e, stackTrace: st);
      final mapped = _mapMediaError(e, canBroadcast: true);
      _showSnackBar(mapped);
      if (mounted) {
        final detail = e is AgoraServiceException
            ? ' [${e.code}] ${e.cause ?? e.message}'
            : ' [$e]';
        _mediaController.failVideoAction('Camera failed: $mapped$detail');
      }
    } finally {
      if (mounted) {
        // Set a short cooldown before another toggle is allowed. This prevents
        // a second click (or a Flutter-web button double-fire on rebuild) from
        // immediately re-toggling the camera.
        _videoToggleCooldownUntil = DateTime.now().add(
          const Duration(milliseconds: 900),
        );
        _mediaController.endVideoAction();
      }
      _logLiveRoom('toggle_video:end');
    }
  }

  Widget _buildLocalCamContent({String? avatarUrl}) {
    final service = _agoraService;
    final safeAvatarUrl = sanitizeNetworkImageUrl(avatarUrl);
    // Also gate on _isVideoEnabled: on web canRenderLocalView stays true when
    // the user keeps mic-only broadcaster mode after turning the camera off,
    // which would render a black AgoraVideoView instead of the "Camera is off"
    // placeholder.
    if (service != null && service.canRenderLocalView && _isVideoEnabled) {
      return KeyedSubtree(
        key: _localViewMoveKey,
        child: KeyedSubtree(
          key: ValueKey<String>('local-view-$_localViewEpoch'),
          child: service.getLocalView(),
        ),
      );
    }
    return ColoredBox(
      color: const Color(0xFF241820),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (safeAvatarUrl != null)
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(safeAvatarUrl),
                  backgroundColor: const Color(0xFF2A2D35),
                )
              else
                const Icon(
                  Icons.videocam_off,
                  size: 40,
                  color: Color(0xFFB09080),
                ),
              const SizedBox(height: 8),
              Text(
                _isVideoEnabled
                    ? 'Camera feed is preparing.'
                    : 'Camera is off.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB09080), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteCamContent({
    required int remoteUid,
    required bool canViewRemote,
    String? avatarUrl,
    VoidCallback? onRequestAccess,
  }) {
    final service = _agoraService;
    final safeAvatarUrl = sanitizeNetworkImageUrl(avatarUrl);
    if (canViewRemote && service != null) {
      return service.getRemoteView(remoteUid, widget.roomId);
    }
    return ColoredBox(
      color: const Color(0xFF241820),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (safeAvatarUrl != null)
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(safeAvatarUrl),
                  backgroundColor: const Color(0xFF2A2D35),
                )
              else
                const Icon(
                  Icons.lock_outline,
                  size: 24,
                  color: Color(0xFFB09080),
                ),
              const SizedBox(height: 6),
              Text(
                canViewRemote ? 'Loading video...' : 'Cam access locked',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB09080), fontSize: 11),
              ),
              if (onRequestAccess != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onRequestAccess,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Request Access',
                    style: TextStyle(fontSize: 10, color: Color(0xFFC45E7A)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog then sends a cam-view request to [targetUserId].
  Future<void> _sendCamViewRequest(String targetUserId) async {
    final myUserId = _joinedUserId;
    if (myUserId == null || !mounted) return;
    final targetName = _senderDisplayNameById[targetUserId] ?? targetUserId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request cam access'),
        content: Text('Ask $targetName to let you view their camera?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final requesterName =
          (_senderDisplayNameById[myUserId] ??
                  ref.read(userProvider)?.username ??
                  myUserId)
              .trim();
      await ref
          .read(camViewRequestControllerProvider)
          .sendRequest(
            roomId: widget.roomId,
            requesterId: myUserId,
            targetId: targetUserId,
            requesterName: requesterName,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request sent')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not send request')));
      }
    }
  }

  Widget _buildFloatingCamWindowContent(FloatingCamWindowData window) {
    if (window.isLocal) {
      return _buildLocalCamContent(avatarUrl: window.avatarUrl);
    }

    final remoteUid = window.remoteUid;
    if (remoteUid == null) {
      return const ColoredBox(color: Color(0xFF241820));
    }

    final currentUserId = _joinedUserId;
    final remoteUserId = window.userId;
    final allowedViewers = remoteUserId == null
        ? const <String>[]
        : ref.watch(userCamAllowedViewersProvider(remoteUserId)).valueOrNull ??
              const <String>[];
    final canViewRemote = remoteUserId == null
        ? window.canViewRemote
        : (allowedViewers.isEmpty ||
              (currentUserId != null &&
                  allowedViewers.contains(currentUserId)));

    return KeyedSubtree(
      key: _remoteViewKey(remoteUid),
      child: _buildRemoteCamContent(
        remoteUid: remoteUid,
        canViewRemote: canViewRemote,
        avatarUrl: window.avatarUrl,
        onRequestAccess:
            (!canViewRemote &&
                remoteUserId != null &&
                remoteUserId != currentUserId)
            ? () => _sendCamViewRequest(remoteUserId)
            : null,
      ),
    );
  }

  /// Shows an Allow/Deny dialog when another user requests to view the current
  /// user's camera.
  Future<void> _handleIncomingCamViewRequest(CamViewRequest request) async {
    if (!mounted) return;
    final requesterName =
        request.requesterName ??
        _senderDisplayNameById[request.requesterId] ??
        request.requesterId;
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cam view request'),
        content: Text('$requesterName wants to view your camera.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Deny'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final myUserId = _joinedUserId;
    if (myUserId == null) return;
    try {
      if (approved == true) {
        await ref
            .read(liveRoomControllerProvider(widget.roomId).notifier)
            .approveCameraViewer(
              ownerUserId: myUserId,
              viewerUserId: request.requesterId,
              approved: true,
            );
      }
      await ref
          .read(camViewRequestControllerProvider)
          .respondToRequest(
            roomId: widget.roomId,
            requestId: request.id,
            approved: approved == true,
          );
    } finally {
      _activeCamViewRequestId = null;
    }
  }

  String _mapMediaError(Object error, {required bool canBroadcast}) {
    if (error is AgoraServiceException) {
      switch (error.code) {
        case 'no-system-audio':
          return 'No system audio was captured. In the share picker, check "Share system audio" before clicking Share.';
        case 'system-audio-cancelled':
          return 'Screen share was cancelled. Tap the button again and choose a tab or window to share.';
        case 'permission-denied':
          return canBroadcast
              ? 'Camera/microphone access was denied. Allow permissions in browser site settings, then rejoin the room.'
              : 'Microphone access was denied. Allow permission in browser site settings, then retry.';
        case 'no-media-devices':
          return 'No camera/microphone was detected. Connect a device and retry.';
        case 'device-in-use':
          return 'Camera/microphone is busy in another app or tab. Close the other session and retry.';
        case 'unsupported-browser':
          return 'This browser is not fully supported for live media. Use the latest Chrome or Edge.';
        case 'insecure-context':
          return 'Live media requires HTTPS (or localhost). Open MixVy on a secure origin.';
        case 'agora-backend-misconfigured':
          return 'Live media is temporarily unavailable due to server configuration. Please contact support.';
        case 'agora-rate-limited':
          return 'Too many live-media attempts right now. Please wait a moment and retry.';
        case 'agora-token-missing':
        case 'agora-appid-invalid':
          return 'Live media backend configuration is invalid. Please contact support.';
        case 'agora-initialize-live-media-failed':
          return 'Live media engine failed to start in this browser session. Reload the page and try again.';
        case 'agora-join-room-failed':
          return 'Live media channel join timed out. Check connection and retry.';
        default:
          return error.message;
      }
    }

    final lower = error.toString().toLowerCase();
    if (lower.contains('unsupported browser') ||
        lower.contains('webrtc is not supported') ||
        lower.contains('not supported on this browser')) {
      return 'This browser is not fully supported for live media. Use the latest Chrome or Edge.';
    }
    if (lower.contains('secure context') ||
        lower.contains('only secure origins')) {
      return 'Live media requires HTTPS (or localhost). Open MixVy on a secure origin.';
    }
    if (lower.contains('permission') || lower.contains('denied')) {
      return canBroadcast
          ? 'Camera/microphone permission denied. Enable permissions in app settings and retry.'
          : 'Microphone permission denied. Enable permissions in app settings and retry.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network issue while connecting audio/video. Check your connection and retry.';
    }
    if (lower.contains('agora server credentials are not configured') ||
        lower.contains('failed-precondition')) {
      return 'Live media backend is not configured. AGORA credentials must be set in Cloud Functions.';
    }
    if (lower.contains('camera') ||
        lower.contains('microphone') ||
        lower.contains('device')) {
      return 'Camera or microphone is unavailable on this device.';
    }
    return 'Audio/video operation failed. Please retry.';
  }

  /// Shows a friend picker and sends room-invite in-app notifications to each
  /// selected friend. Uses batch Firestore writes for efficiency.
  Future<void> _inviteFriendsToRoom({
    required String userId,
    required String username,
    required String roomName,
  }) async {
    if (!mounted) return;
    final roomRepository = ref.read(roomRepositoryProvider);
    try {
      final friends = await roomRepository.getFriends(userId);
      if (!mounted) return;
      if (friends.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have no friends to invite yet.')),
        );
        return;
      }
      final Set<String> selected = {};
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetCtx) {
          return StatefulBuilder(
            builder: (_, setModalState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Invite friends to this room',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () => Navigator.of(sheetCtx).pop(true),
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: friends.length,
                        itemBuilder: (ctx, i) {
                          final friend = friends[i];
                          final isSelected = selected.contains(friend.id);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              friend.username.trim().isEmpty
                                  ? friend.id
                                  : friend.username,
                            ),
                            secondary: CircleAvatar(
                              child: Text(
                                (friend.username.trim().isEmpty
                                        ? '?'
                                        : friend.username.trim()[0])
                                    .toUpperCase(),
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selected.add(friend.id);
                                } else {
                                  selected.remove(friend.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      );
      if (confirmed != true || selected.isEmpty) return;
      await roomRepository.sendRoomInviteToFriends(
        friendIds: selected.toList(),
        inviterId: userId,
        inviterName: username.trim().isEmpty ? 'Someone' : username.trim(),
        roomId: widget.roomId,
        roomName: roomName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invited ${selected.length} friend${selected.length == 1 ? '' : 's'}!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send invites: $e')));
      }
    }
  }

  /// Shows a bottom sheet listing which of the current user's friends are
  /// currently online (have a live presence doc), with a quick "Go to room"
  /// button when the friend is already in a room.
  Future<void> _showOnlineFriendsSheet({
    required String currentUserId,
    required String roomId,
  }) async {
    if (!mounted) return;

    final friends = await ref
        .read(roomRepositoryProvider)
        .getFriends(currentUserId);
    if (!mounted) return;

    if (friends.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You have no friends yet.')));
      return;
    }

    final presenceByUserId = await ref
        .read(presenceRepositoryProvider)
        .getUsersPresence(
          friends.map((friend) => friend.id).toList(growable: false),
        );

    final online =
        <
          ({
            String id,
            String username,
            String? avatarUrl,
            String? currentRoomId,
          })
        >[];
    for (var i = 0; i < friends.length; i++) {
      final presence = presenceByUserId[friends[i].id];
      if (presence == null) continue;
      if (presence.isOnline != true) continue;
      online.add((
        id: friends[i].id,
        username: friends[i].username,
        avatarUrl: friends[i].avatarUrl,
        currentRoomId: presence.inRoom,
      ));
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Online friends',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${online.length} online',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (online.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'None of your friends are online right now.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: online.length,
                  itemBuilder: (ctx, i) {
                    final f = online[i];
                    final inThisRoom = f.currentRoomId == roomId;
                    final inOtherRoom =
                        f.currentRoomId != null && f.currentRoomId != roomId;
                    final safeAvatarUrl = sanitizeNetworkImageUrl(f.avatarUrl);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: safeAvatarUrl != null
                            ? NetworkImage(safeAvatarUrl)
                            : null,
                        child: safeAvatarUrl == null
                            ? Text(
                                f.username.isNotEmpty
                                    ? f.username[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(f.username),
                      subtitle: inThisRoom
                          ? const Text(
                              'In this room',
                              style: TextStyle(color: Color(0xFFC45E7A)),
                            )
                          : inOtherRoom
                          ? const Text('In another room')
                          : const Text('Online'),
                      trailing: inOtherRoom
                          ? TextButton(
                              onPressed: () {
                                Navigator.of(sheetCtx).pop();
                                context.push('/room/${f.currentRoomId}');
                              },
                              child: const Text('Go'),
                            )
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _stopPresenceHeartbeat() async {
    await ref
        .read(liveRoomControllerProvider(widget.roomId).notifier)
        .pausePresence();
  }

  /// Fetches a replacement token and calls engine.renewToken() so the channel
  /// never disconnects due to expiry. Called from onTokenWillExpire.
  Future<void> _renewAgoraToken() async {
    final service = _agoraService;
    final rtcUid = _currentRtcUid;
    if (service == null || rtcUid == null || !_isCallReady) return;
    try {
      final credentials = await _fetchAgoraToken(
        channelName: widget.roomId,
        rtcUid: rtcUid,
      );
      await service.renewToken(credentials.token);
      _logLiveRoom('token_renewed: ok');
    } catch (e) {
      _logLiveRoom('token_renewal_failed', error: e);
    }
  }

  /// Handles an unexpected Agora connection drop. On web we attempt a full
  /// reconnect so the camera comes back automatically.
  Future<void> _handleConnectionLost() async {
    if (!mounted || !_isCallReady) return;
    final userId = _joinedUserId;
    if (userId == null) return;

    // Exponential back-off: 1 s, 2 s, 4 s … capped at _kMaxBackoffSeconds.
    _reconnectAttempts++;
    final delaySecs = (_reconnectAttempts <= 1)
        ? 1
        : (1 << (_reconnectAttempts - 1)).clamp(1, _kMaxBackoffSeconds);
    _logLiveRoom(
      'connection_lost: reconnect attempt=$_reconnectAttempts delay=${delaySecs}s',
    );

    // Snapshot media state before _disconnectCall() resets it to defaults.
    final hadCameraSlot = _claimedSlotId != null;
    final previousRole = _appliedMediaRole;
    final wasMicMuted = _isMicMuted;

    _logLiveRoom(
      'connection_lost: reconnecting hadSlot=$hadCameraSlot micMuted=$wasMicMuted',
    );
    await _disconnectCall();
    if (!mounted) return;

    _mediaController.markReconnecting(
      delaySecs > 1 ? 'Reconnecting in ${delaySecs}s…' : 'Reconnecting…',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySecs), () async {
      if (!mounted) return;
      await _connectCall(userId);

      // After reconnect the channel join resets media state to audience/cam-off.
      // If the user was broadcasting, restore the camera and slot.
      if (mounted && hadCameraSlot) {
        _logLiveRoom('connection_lost: restoring broadcaster slot');
        try {
          final service = _agoraService;
          if (service != null && _isCallReady) {
            // Re-claim the slot (idempotent if slot doc still has our userId).
            final slotService = ref.read(roomSlotServiceProvider);
            final slotId = await slotService.claimSlot(
              widget.roomId,
              userId,
              maxBroadcasters: _maxBroadcasters,
            );
            if (slotId != null && mounted) {
              _mediaController.setClaimedSlotId(slotId);
              await service.enableVideo(
                true,
                publishMicrophoneTrack: !wasMicMuted,
              );
              await service.mute(wasMicMuted);
              if (mounted) {
                _mediaController.restoreBroadcastAfterReconnect(
                  slotId: slotId,
                  wasMicMuted: wasMicMuted,
                  role: previousRole ?? 'member',
                );
                // Successful reconnect — reset backoff counter.
                _reconnectAttempts = 0;
              }
            }
          }
        } catch (e) {
          _logLiveRoom('connection_lost: slot restore failed', error: e);
        }
      } else if (mounted && _isCallReady) {
        _reconnectAttempts = 0;
      }
    });
  }

  Future<void> _disconnectCall({bool resetUiState = true}) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopMicLevelPolling();
    final service = _agoraService;
    if (service is WebRtcRoomService) service.onSystemAudioStopped = null;
    _agoraService = null;
    if (resetUiState && mounted) {
      _mediaController.resetDisconnected();
    }
    if (service != null) {
      await service.dispose();
    }
  }

  Future<void> _applyRoleMediaState({
    required String role,
    required RoomAudioState audioState,
  }) async {
    final service = _agoraService;
    if (service == null ||
        !_isCallReady ||
        (_appliedMediaRole == role && _appliedAudioState == audioState) ||
        _isMicActionInFlight ||
        _isVideoActionInFlight) {
      return;
    }

    try {
      await service.syncAudio(audioState, shouldMute: _isMicMuted);
      if (_isVideoEnabled && _claimedSlotId == null) {
        await service.enableVideo(
          true,
          publishMicrophoneTrack:
              (audioState == RoomAudioState.speaking ||
                  audioState == RoomAudioState.cohostSpeaking) &&
              !_isMicMuted,
        );
      }

      if (mounted) {
        if (audioState == RoomAudioState.denied ||
            audioState == RoomAudioState.requestingMic ||
            audioState == RoomAudioState.muted) {
          _mediaController.setMicMuted(true);
        }
        if (audioState == RoomAudioState.cohostSpeaking &&
            _appliedAudioState != RoomAudioState.cohostSpeaking) {
          _showSnackBar('You are now a co-host — your mic is live!');
        }
        if (audioState == RoomAudioState.muted &&
            _appliedAudioState == RoomAudioState.speaking &&
            _claimedSlotId == null) {
          _showSnackBar('Your mic was taken — someone else grabbed it.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(_mapMediaError(e, canBroadcast: true));
        _mediaController
          ..setAppliedMediaRole(role)
          ..setAppliedAudioState(audioState);
      }
      return;
    }

    if (!mounted) {
      return;
    }

    _mediaController
      ..setAppliedMediaRole(role)
      ..setAppliedAudioState(audioState);
  }

  void _exitRoom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/');
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _markRecentChatter(String senderId) {
    if (!mounted) return;
    _recentChatterTimers[senderId]?.cancel();
    setState(() => _recentChatters.add(senderId));
    _recentChatterTimers[senderId] = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _recentChatters.remove(senderId));
      _recentChatterTimers.remove(senderId);
    });
  }

  void _onTypingInput() {
    try {
      _typingTimer?.cancel();
      final userId = _joinedUserId;
      if (userId == null || userId.isEmpty) return;
      if (messageController.text.trim().isEmpty) {
        _clearTypingStatus().ignore();
        return;
      }
      final now = DateTime.now();
      final shouldWrite =
          !_typingStatusActive ||
          _lastTypingWriteAt == null ||
          now.difference(_lastTypingWriteAt!) >= _kTypingWriteThrottle;
      if (shouldWrite) {
        _typingStatusActive = true;
        _lastTypingWriteAt = now;
        _roomController.setTyping(userId: userId, isTyping: true).ignore();
      }
      _typingTimer = Timer(_kTypingIdleTimeout, _clearTypingStatus);
    } catch (_) {
      // Typing indicators are best-effort only and must never block editing.
    }
  }

  Future<void> _clearTypingStatus() async {
    _typingTimer?.cancel();
    _typingTimer = null;
    _typingStatusActive = false;
    if (_isTearingDown) return;
    final userId = _joinedUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _roomController.setTyping(userId: userId, isTyping: false);
    } catch (_) {}
  }

  void _appendEmoji(String emoji) {
    final text = messageController.text;
    final selection = messageController.selection;
    if (!selection.isValid) {
      messageController.text = '$text$emoji';
      messageController.selection = TextSelection.collapsed(
        offset: messageController.text.length,
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final newText = text.replaceRange(start, end, emoji);
    messageController.text = newText;
    messageController.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
  }

  Widget _buildEmojiTray() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _quickEmojis
            .map((emoji) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _appendEmoji(emoji);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  String _senderLabelFor({
    required String senderId,
    required String currentUserId,
    required String currentUsername,
  }) {
    final fallbackName = senderId == currentUserId ? currentUsername : senderId;
    return getDisplayName(
      uid: senderId,
      resolvedDisplayName: _senderDisplayNameById[senderId],
      fallbackName: fallbackName,
    );
  }

  Future<void> _hydrateSenderDisplayNames({
    List<MessageModel>? messages,
    List<String>? userIds,
    required String currentUserId,
  }) async {
    final senderIds = <String>{
      if (messages != null)
        ...messages
            .map((m) => m.senderId.trim())
            .where((id) => id.isNotEmpty && id != currentUserId),
      if (userIds != null)
        ...userIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty && id != currentUserId),
    };
    final missingIds = senderIds
        .where((id) {
          final cachedDisplayName = _senderDisplayNameById[id]?.trim() ?? '';
          final needsLookup =
              cachedDisplayName.isEmpty ||
              cachedDisplayName == id ||
              isAnonymousDisplayName(cachedDisplayName);
          return needsLookup && !_senderLookupInFlight.contains(id);
        })
        .toList(growable: false);
    if (missingIds.isEmpty) {
      return;
    }

    _senderLookupInFlight.addAll(missingIds);
    final resolved = <String, String>{};
    final resolvedVip = <String, int>{};
    final resolvedAvatar = <String, String?>{};
    final resolvedGender = <String, String?>{};

    try {
      final lookup = await ref
          .read(roomRepositoryProvider)
          .loadUserLookup(missingIds);

      for (final entry in lookup.entries) {
        resolved[entry.key] = resolvePublicUsername(
          uid: entry.key,
          profileUsername: entry.value.profileUsername,
        );
        resolvedVip[entry.key] = entry.value.vipLevel;
        resolvedAvatar[entry.key] = entry.value.avatarUrl;
        resolvedGender[entry.key] = entry.value.gender;
      }

      // Prevent repeated lookups for missing docs by falling back to a
      // safe public display label instead of leaking the raw uid.
      for (final id in missingIds) {
        resolved.putIfAbsent(id, () => resolvePublicUsername(uid: id));
        resolvedVip.putIfAbsent(id, () => 0);
        resolvedAvatar.putIfAbsent(id, () => null);
        resolvedGender.putIfAbsent(id, () => null);
      }

      final roomController = ref.read(
        liveRoomControllerProvider(widget.roomId).notifier,
      );
      for (final entry in resolved.entries) {
        roomController.cacheDisplayName(
          userId: entry.key,
          displayName: entry.value,
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _senderDisplayNameById.addAll(resolved);
        _senderVipLevelById.addAll(resolvedVip);
        _senderAvatarUrlById.addAll(resolvedAvatar);
        _senderGenderById.addAll(resolvedGender);
      });
    } catch (_) {
      // Best effort only; fall back to sender id in UI if lookup fails.
    } finally {
      _senderLookupInFlight.removeAll(missingIds);
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _reportTarget({
    required String targetId,
    required ReportTargetType targetType,
    required String title,
    required String fallbackReason,
  }) async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted != true) {
      return;
    }

    try {
      await ModerationService().reportTarget(
        targetId: targetId,
        targetType: targetType,
        reason: reasonController.text.trim().isEmpty
            ? fallbackReason
            : reasonController.text.trim(),
        details: detailsController.text.trim(),
      );
      _showSnackBar('Report submitted.');
    } catch (e) {
      _showSnackBar('Could not submit report: $e');
    }
  }

  void _markRoomMembershipConfirmed() {
    _lastConfirmedRoomMembershipAt = DateTime.now();
  }

  Future<void> _verifyUnexpectedRoomRemoval(String userId) async {
    if (_isTearingDown ||
        _isHandlingParticipantRemoval ||
        _isVerifyingUnexpectedRemoval) {
      return;
    }

    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    _isVerifyingUnexpectedRemoval = true;
    try {
      final roomController = ref.read(
        liveRoomControllerProvider(widget.roomId).notifier,
      );
      await roomController.syncPresenceNow(forceSync: true);
      final roomState = ref.read(liveRoomControllerProvider(widget.roomId));
      final membershipState = roomState.membershipStateFor(normalizedUserId);
      if (membershipState.isAuthoritativeMember ||
          membershipState.shouldDeferRemoval) {
        _markRoomMembershipConfirmed();
        return;
      }

      final firestore = ref.read(roomFirestoreProvider);
      final roomRef = firestore.collection('rooms').doc(widget.roomId);
      final participantSnapshot = await roomRef
          .collection('participants')
          .doc(normalizedUserId)
          .get();
      final memberSnapshot = await roomRef
          .collection('members')
          .doc(normalizedUserId)
          .get();

      if ((participantSnapshot.data()?['isBanned'] as bool?) == true) {
        await _handleForcedRoomExit('You were banned from this room.');
        return;
      }

      if (participantSnapshot.exists || memberSnapshot.exists) {
        _markRoomMembershipConfirmed();
        return;
      }

      await _handleForcedRoomExit('You were removed from this room.');
    } catch (_) {
      _markRoomMembershipConfirmed();
    } finally {
      _isVerifyingUnexpectedRemoval = false;
    }
  }

  Future<void> _handleForcedRoomExit(String message) async {
    if (_isHandlingParticipantRemoval) {
      return;
    }

    _isHandlingParticipantRemoval = true;
    _lastConfirmedRoomMembershipAt = null;
    await _disconnectCall();

    // Release any camera slot before nulling _joinedUserId, which _leaveRoom
    // uses to find the slot owner. Forced exits don't call _leaveRoom so we
    // must clean up the slot here explicitly.
    final userId = _joinedUserId;
    if (userId != null && _claimedSlotId != null) {
      try {
        final slotService = ref.read(roomSlotServiceProvider);
        await slotService.releaseSlot(widget.roomId, userId);
      } catch (_) {
        // Best-effort; slot will expire on its own if cleanup fails.
      }
      _mediaController.setClaimedSlotId(null);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _roomJoinError = message;
      _joinedUserId = null;
    });
    _showSnackBar(message);
    _exitRoom();
  }

  Future<void> _showParticipantActions({
    required RoomParticipantModel target,
    required RoomParticipantModel? currentParticipant,
    required String currentUserId,
    required String hostId,
    required bool isHost,
    required bool isModerator,
    required Map<String, RoomUserPresentation> presentationByUserId,
  }) async {
    final isSelf = target.userId == currentUserId;
    final targetIsHost = target.userId == hostId || target.role == 'host';
    final actorRole =
        currentParticipant?.role ??
        (isHost ? 'host' : (isModerator ? 'moderator' : 'audience'));
    final canManageParticipant = RoomPermissions.canManageParticipant(
      actorRole: actorRole,
      actorUserId: currentUserId,
      targetRole: target.role,
      targetUserId: target.userId,
      hostUserId: hostId,
    );
    final canHostOnlyManage =
        RoomPermissions.isHost(actorRole) && !isSelf && !targetIsHost;
    final canTransferOwnership = RoomPermissions.canTransferOwnership(
      actorRole: actorRole,
      actorUserId: currentUserId,
      targetUserId: target.userId,
      hostUserId: hostId,
    );
    final moderationService = ModerationService();
    final followService = FollowService();
    var isBlocked = false;
    var isFollowing = false;

    if (!isSelf) {
      try {
        isBlocked = await moderationService.isBlocked(target.userId);
        isFollowing = await followService.isFollowing(
          currentUserId,
          target.userId,
        );
      } catch (_) {
        isBlocked = false;
        isFollowing = false;
      }
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        Future<void> runAction(Future<void> Function() action) async {
          Navigator.of(sheetContext).pop();
          await action();
        }

        final roomController = ref.read(
          liveRoomControllerProvider(widget.roomId).notifier,
        );

        final actions = <RoomActionItem>[
          RoomActionItem(
            label: 'View profile',
            icon: Icons.person_outline,
            onTap: () {
              Navigator.of(sheetContext).pop();
              UserProfilePopup.show(context, ref, userId: target.userId);
            },
          ),
          if (!isSelf &&
              (kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.linux))
            RoomActionItem(
              label: 'Pop out cam',
              icon: Icons.open_in_new,
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (kIsWeb) {
                  WebPopoutService().openCamWindow(target.userId);
                } else {
                  DesktopWindowService().openCamWindow(target.userId);
                }
              },
            ),
          if (!isSelf)
            RoomActionItem(
              label: 'Whisper',
              icon: Icons.message_outlined,
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final currentUser = ref.read(userProvider);
                if (currentUser == null) return;
                try {
                  final conversationId = await ref
                      .read(messagingControllerProvider)
                      .createDirectConversation(
                        userId1: currentUser.id,
                        user1Name: currentUser.username,
                        user1AvatarUrl: currentUser.avatarUrl,
                        userId2: target.userId,
                        user2Name:
                            presentationByUserId[target.userId]?.displayName ??
                            target.userId,
                        user2AvatarUrl:
                            presentationByUserId[target.userId]?.avatarUrl,
                      );
                  if (!mounted) return;
                  final peerName =
                      presentationByUserId[target.userId]?.displayName ??
                      target.userId;
                  final peerAvatar =
                      presentationByUserId[target.userId]?.avatarUrl;
                  if (kIsWeb) {
                    WebPopoutService().openWhisperWindow(
                      target.userId,
                      peerName,
                    );
                  } else if (defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.linux) {
                    await DesktopWindowService().openWhisperWindow(
                      target.userId,
                      peerName,
                    );
                  } else {
                    FloatingWhisperPanel.show(
                      context,
                      ref,
                      conversationId: conversationId,
                      peerName: peerName,
                      peerAvatarUrl: peerAvatar,
                    );
                  }
                } catch (e) {
                  _showSnackBar('Could not open whisper: $e');
                }
              },
            ),
          if (!isSelf)
            RoomActionItem(
              label: isFollowing ? 'Unfollow user' : 'Follow user',
              icon: isFollowing
                  ? Icons.person_remove_outlined
                  : Icons.person_add_alt_1_outlined,
              onTap: () => runAction(() async {
                try {
                  if (isFollowing) {
                    await followService.unfollowUser(target.userId);
                    _showSnackBar('Unfollowed ${target.userId}.');
                  } else {
                    await followService.followUser(target.userId);
                    _showSnackBar('Now following ${target.userId}.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update follow status: $e');
                }
              }),
            ),
          if (!isSelf)
            RoomActionItem(
              label: isBlocked ? 'Unblock user' : 'Block user',
              icon: isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
              destructive: !isBlocked,
              onTap: () => runAction(() async {
                try {
                  if (isBlocked) {
                    await moderationService.unblockUser(target.userId);
                    _showSnackBar('User unblocked.');
                  } else {
                    final confirmed = await _confirmAction(
                      title: 'Block user',
                      message:
                          'You will stop seeing each other in rooms and discovery.',
                      confirmLabel: 'Block',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await moderationService.blockUser(target.userId);
                    _showSnackBar('User blocked.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update block status: $e');
                }
              }),
            ),
          if (!isSelf)
            RoomActionItem(
              label: 'Report user',
              icon: Icons.flag_outlined,
              destructive: true,
              onTap: () => runAction(() {
                return _reportTarget(
                  targetId: target.userId,
                  targetType: ReportTargetType.user,
                  title: 'Report user',
                  fallbackReason: 'In-room user review requested',
                );
              }),
            ),
          if (canManageParticipant)
            RoomActionItem(
              label: target.isMuted ? 'Unmute user chat' : 'Mute user chat',
              icon: target.isMuted
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              onTap: () => runAction(() async {
                try {
                  if (target.isMuted) {
                    await roomController.unmuteUser(target.userId);
                    _showSnackBar('${target.userId} can chat again.');
                  } else {
                    await roomController.muteUser(target.userId);
                    _showSnackBar('${target.userId} was muted.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update mute status: $e');
                }
              }),
            ),
          if (canHostOnlyManage)
            RoomActionItem(
              label: target.role == 'moderator'
                  ? 'Remove moderator'
                  : 'Make moderator',
              icon: target.role == 'moderator'
                  ? Icons.shield_moon_outlined
                  : Icons.shield_outlined,
              onTap: () => runAction(() async {
                try {
                  if (target.role == 'moderator') {
                    await roomController.demoteToAudience(target.userId);
                    _showSnackBar('${target.userId} is now audience.');
                  } else {
                    await roomController.promoteToModerator(target.userId);
                    _showSnackBar('${target.userId} is now a moderator.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update moderator role: $e');
                }
              }),
            ),
          if (canHostOnlyManage)
            RoomActionItem(
              label: target.role == 'cohost'
                  ? 'Move to audience'
                  : 'Invite to stage',
              icon: target.role == 'cohost'
                  ? Icons.keyboard_double_arrow_down
                  : Icons.keyboard_double_arrow_up,
              onTap: () => runAction(() async {
                try {
                  if (target.role == 'cohost') {
                    await roomController.demoteToAudience(target.userId);
                    _showSnackBar('${target.userId} moved to the audience.');
                  } else {
                    await roomController.promoteToCohost(target.userId);
                    _showSnackBar('${target.userId} invited to the stage.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update role: $e');
                }
              }),
            ),
          // Invite non-cohost to the mic (push-invite) or pull them off the mic.
          if (canHostOnlyManage && target.role != 'cohost')
            RoomActionItem(
              label: target.role == 'stage' ? 'Pull from mic' : 'Invite to mic',
              icon: target.role == 'stage'
                  ? Icons.mic_off_outlined
                  : Icons.mic_outlined,
              onTap: () => runAction(() async {
                try {
                  if (target.role == 'stage') {
                    await ref
                        .read(
                          liveRoomControllerProvider(widget.roomId).notifier,
                        )
                        .demoteSpeaker(target.userId);
                    _showSnackBar('${target.userId} removed from mic.');
                  } else {
                    await ref
                        .read(
                          liveRoomControllerProvider(widget.roomId).notifier,
                        )
                        .promoteSpeaker(
                          actorUserId: currentUserId,
                          targetUserId: target.userId,
                        );
                    _showSnackBar('${target.userId} invited to the mic!');
                  }
                } catch (e) {
                  _showSnackBar('Could not update mic: $e');
                }
              }),
            ),
          if (canHostOnlyManage)
            RoomActionItem(
              label: '⭐ Spotlight this person',
              icon: Icons.star_outline_rounded,
              onTap: () => runAction(() async {
                try {
                  await ref
                      .read(liveRoomControllerProvider(widget.roomId).notifier)
                      .setSpotlightUser(target.userId);
                  _showSnackBar(
                    '${presentationByUserId[target.userId]?.displayName ?? target.userId} is now spotlighted!',
                  );
                } catch (e) {
                  _showSnackBar('Could not spotlight user: $e');
                }
              }),
            ),
          if (canTransferOwnership)
            RoomActionItem(
              label: 'Transfer room ownership',
              icon: Icons.workspace_premium_outlined,
              destructive: true,
              onTap: () => runAction(() async {
                final confirmed = await _confirmAction(
                  title: 'Transfer ownership',
                  message:
                      'Make ${target.userId} the new room host? You will be moved to cohost.',
                  confirmLabel: 'Transfer',
                );
                if (!confirmed) {
                  return;
                }
                try {
                  await roomController.transferHost(
                    targetUserId: target.userId,
                  );
                  _showSnackBar('${target.userId} is now the room host.');
                } catch (e) {
                  _showSnackBar('Could not transfer ownership: $e');
                }
              }),
            ),
          if (canHostOnlyManage)
            RoomActionItem(
              label: target.isBanned ? 'Unban user' : 'Ban user',
              icon: target.isBanned
                  ? Icons.verified_user_outlined
                  : Icons.gpp_bad_outlined,
              destructive: !target.isBanned,
              onTap: () => runAction(() async {
                try {
                  if (target.isBanned) {
                    await roomController.unbanUser(target.userId);
                    _showSnackBar('${target.userId} was unbanned.');
                  } else {
                    final confirmed = await _confirmAction(
                      title: 'Ban user',
                      message:
                          'This removes the user from the room until you unban them.',
                      confirmLabel: 'Ban',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await roomController.banUser(target.userId);
                    _showSnackBar('${target.userId} was banned.');
                  }
                } catch (e) {
                  _showSnackBar('Could not update ban status: $e');
                }
              }),
            ),
          if (canManageParticipant)
            RoomActionItem(
              label: 'Remove from room',
              icon: Icons.exit_to_app,
              destructive: true,
              onTap: () => runAction(() async {
                final confirmed = await _confirmAction(
                  title: 'Remove user',
                  message:
                      'This kicks ${target.userId} out of the room right now.',
                  confirmLabel: 'Remove',
                );
                if (!confirmed) {
                  return;
                }
                try {
                  await roomController.removeUser(target.userId);
                  _showSnackBar('${target.userId} was removed from the room.');
                } catch (e) {
                  _showSnackBar('Could not remove user: $e');
                }
              }),
            ),
          if (isSelf)
            RoomActionItem(
              label: 'Leave room',
              icon: Icons.logout,
              destructive: true,
              onTap: () => runAction(() async {
                await _disconnectCall();
                await _leaveRoom();
                _exitRoom();
              }),
            ),
        ];

        return RoomParticipantActionSheet(
          participant: currentParticipant != null && isSelf
              ? currentParticipant
              : target,
          userPresentation:
              presentationByUserId[target.userId] ??
              RoomUserPresentation(displayName: target.userId),
          currentUserId: currentUserId,
          hostUserId: hostId,
          actions: actions,
        );
      },
    );
  }

  void _openSecretComposerForParticipant(RoomParticipantModel target) {
    if (!mounted) return;
    setState(() {
      _secretComposerTarget = target;
      _secretMessageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _secretInputFocusNode.requestFocus();
      }
    });
  }

  void _closeSecretComposer() {
    if (!mounted) return;
    setState(() {
      _secretComposerTarget = null;
      _isSendingSecretMessage = false;
      _secretMessageController.clear();
    });
  }

  Future<void> _sendPrivateRoomMessageToParticipant(
    RoomParticipantModel target,
  ) async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    final targetName = _senderDisplayNameById[target.userId] ?? target.userId;

    final trimmed = _secretMessageController.text.trim();
    if (trimmed.isEmpty) return;

    try {
      setState(() => _isSendingSecretMessage = true);
      final sendPrivate = ref.read(sendPrivateMessageProvider(widget.roomId));
      await sendPrivate(
        content: _buildOutgoingChatMessage(trimmed),
        recipientUserId: target.userId,
        recipientDisplayName: targetName,
      );
      if (!mounted) return;
      _closeSecretComposer();
      _showSnackBar('Private room message sent to $targetName.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingSecretMessage = false);
      _showSnackBar('Could not send private room message: $e');
    }
  }

  Future<void> _showPeopleSheet({
    required List<RoomParticipantModel> participants,
    required RoomParticipantModel? currentParticipant,
    required String currentUserId,
    required String hostId,
    required bool isHost,
    required bool isModerator,
    required Map<String, RoomUserPresentation> presentationByUserId,
    required List<RoomPresenceModel> presenceList,
  }) async {
    // Build userId → isOnline map with 60-second heartbeat staleness window.
    final onlineMap = <String, bool>{
      for (final p in presenceList)
        if (p.isOnline &&
            (p.lastHeartbeatAt == null ||
                DateTime.now().difference(p.lastHeartbeatAt!).inSeconds < 60))
          p.userId: true,
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: RoomRosterSheet(
            participants: participants,
            presentationByUserId: presentationByUserId,
            currentUserId: currentUserId,
            hostUserId: hostId,
            onlineStatusByUserId: onlineMap,
            onParticipantTap: (selected) {
              Navigator.of(sheetContext).pop();
              _showParticipantActions(
                target: selected,
                currentParticipant: currentParticipant,
                currentUserId: currentUserId,
                hostId: hostId,
                isHost: isHost,
                isModerator: isModerator,
                presentationByUserId: presentationByUserId,
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, RoomUserPresentation>> _loadParticipantPresentation({
    required List<RoomParticipantModel> participants,
    required String currentUserId,
    required String currentUsername,
    required String? currentAvatarUrl,
  }) async {
    final participantIds = participants
        .map((participant) => participant.userId.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (participantIds.isEmpty) {
      return const <String, RoomUserPresentation>{};
    }

    final presentationByUserId = <String, RoomUserPresentation>{};
    final lookup = await ref
        .read(roomRepositoryProvider)
        .loadUserLookup(participantIds);

    for (final entry in lookup.entries) {
      presentationByUserId[entry.key] = RoomUserPresentation(
        displayName: resolvePublicUsername(
          uid: entry.key,
          profileUsername: entry.value.profileUsername,
        ),
        avatarUrl: entry.value.avatarUrl,
      );
    }

    final resolvedCurrentUsername = currentUsername.trim();
    final hydratedCurrentDisplayName =
        presentationByUserId[currentUserId]?.displayName.trim() ?? '';
    final preferredCurrentDisplayName = getDisplayName(
      uid: currentUserId,
      resolvedDisplayName: resolvedCurrentUsername,
      fallbackName: hydratedCurrentDisplayName.isEmpty
          ? currentUserId
          : hydratedCurrentDisplayName,
    );

    presentationByUserId[currentUserId] = RoomUserPresentation(
      displayName: preferredCurrentDisplayName,
      avatarUrl: currentAvatarUrl == null || currentAvatarUrl.trim().isEmpty
          ? presentationByUserId[currentUserId]?.avatarUrl
          : currentAvatarUrl.trim(),
    );

    for (final participantId in participantIds) {
      presentationByUserId.putIfAbsent(
        participantId,
        () => RoomUserPresentation(displayName: participantId),
      );
    }

    return presentationByUserId;
  }

  Future<void> _openPeopleSheet({
    required List<RoomParticipantModel> participants,
    required RoomParticipantModel? currentParticipant,
    required String currentUserId,
    required String currentUsername,
    required String? currentAvatarUrl,
    required String hostId,
    required bool isHost,
    required bool isModerator,
    required List<RoomPresenceModel> presenceList,
  }) async {
    final presentationByUserId = await _loadParticipantPresentation(
      participants: participants,
      currentUserId: currentUserId,
      currentUsername: currentUsername,
      currentAvatarUrl: currentAvatarUrl,
    );
    if (!mounted) {
      return;
    }

    await _showPeopleSheet(
      participants: participants,
      currentParticipant: currentParticipant,
      currentUserId: currentUserId,
      hostId: hostId,
      isHost: isHost,
      isModerator: isModerator,
      presentationByUserId: presentationByUserId,
      presenceList: presenceList,
    );
  }

  void _showSetStatusDialog(
    BuildContext ctx, {
    required String roomId,
    required String userId,
  }) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241820),
          title: const Text(
            'Set Status',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: TextField(
            controller: ctrl,
            maxLength: 80,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. "Away" or "BRB in 5 min"',
              hintStyle: TextStyle(color: Color(0xFF5A5D65)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3A3E47)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD4A853)),
              ),
              counterStyle: TextStyle(color: Color(0xFF5A5D65)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFB09080)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref
                    .read(liveRoomControllerProvider(roomId).notifier)
                    .setCustomStatus(
                      userId: userId,
                      status: ctrl.text.trim().isEmpty
                          ? null
                          : ctrl.text.trim(),
                    );
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFFD4A853)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Posts a system event message (join/leave/cam-on/off) to the room chat.
  void _sendSystemEvent(String content) {
    if (_isTearingDown) {
      return;
    }
    _roomController.postSystemEvent(content).ignore();
  }

  Future<void> _joinRoom(String userId) async {
    if (_isJoiningRoom || _isTearingDown) return;

    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    _lastAutoJoinAttemptUserId = normalizedUserId;

    AppTelemetry.updateRoomState(
      roomId: widget.roomId,
      joinedUserId: userId,
      roomPhase: 'joining',
      roomError: null,
    );
    AppTelemetry.logAction(
      domain: 'room',
      action: 'join',
      message: 'Live room join started.',
      roomId: widget.roomId,
      userId: userId,
      result: 'start',
    );

    setState(() {
      _isJoiningRoom = true;
      _roomJoinError = null;
    });

    try {
      final sessionDisplayName = getDisplayName(
        uid: userId,
        resolvedDisplayName: _senderDisplayNameById[userId],
        fallbackName: ref.read(userProvider)?.username,
      );
      final joinResult = await _roomController.joinRoom(
        userId,
        displayName: sessionDisplayName,
        avatarUrl: ref.read(userProvider)?.avatarUrl,
      );
      _excludedUserIds = joinResult.excludedUserIds;
      if (!joinResult.isSuccess) {
        AppTelemetry.updateRoomState(
          roomId: widget.roomId,
          joinedUserId: null,
          roomPhase: 'error',
          roomError:
              joinResult.errorMessage ??
              'Could not join room. Please try again.',
        );
        if (mounted) {
          setState(
            () => _roomJoinError =
                joinResult.errorMessage ??
                'Could not join room. Please try again.',
          );
        }
        _joinedUserId = null;
        return;
      }

      _joinedUserId = userId;
      _lastConfirmedRoomMembershipAt = joinResult.joinedAt ?? DateTime.now();
      AppTelemetry.updateRoomState(
        roomId: widget.roomId,
        joinedUserId: userId,
        roomPhase: 'joined',
        roomError: null,
      );

      // Connect the media service automatically once Firebase is available.
      // On web this uses WebRTC which is instant, while native initializes
      // the live media engine.
      if (_hasFirebaseApp) {
        await _connectCall(userId);
      } else {
        _logLiveRoom('connect:skipped firebase_not_initialized');
      }

      if (!_hasTrackedRoomJoin) {
        _hasTrackedRoomJoin = true;
        await AnalyticsService().logEvent(
          'room_joined',
          params: {'room_id': widget.roomId, 'user_id': userId},
        );
      }
      _roomJoinedAt = joinResult.joinedAt ?? DateTime.now();
      final myName = _senderDisplayNameById[userId] ?? userId;
      _sendSystemEvent('$myName joined the room');
    } catch (_) {
      AppTelemetry.updateRoomState(
        roomId: widget.roomId,
        joinedUserId: null,
        roomPhase: 'error',
        roomError: 'Could not join room. Please try again.',
      );
      if (mounted) {
        setState(
          () => _roomJoinError = 'Could not join room. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoiningRoom = false);
      }
    }
  }

  /// Opens the [BackgroundPickerSheet] for the host/co-host to change the
  /// live room's visual theme. Writes the result through [RoomController].
  void _showThemePicker(RoomTheme current) {
    BackgroundPickerSheet.show(
      context,
      current: current,
      onSelect: (theme) {
        ref
            .read(liveRoomControllerProvider(widget.roomId).notifier)
            .updateRoomTheme(theme)
            .catchError((_) {
              if (mounted) _showSnackBar('Could not update room theme.');
            });
      },
      onReset: () {
        ref
            .read(liveRoomControllerProvider(widget.roomId).notifier)
            .resetRoomTheme()
            .catchError((_) {
              if (mounted) _showSnackBar('Could not reset room theme.');
            });
      },
    );
  }

  /// Shows a confirmation dialog and ends the room if confirmed.
  Future<void> _confirmAndEndRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Room?'),
        content: const Text(
          'This will close the room for all participants. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6E84),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Room'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(liveRoomControllerProvider(widget.roomId).notifier)
          .endRoom();
      await _disconnectCall();
      await _leaveRoom();
      _exitRoom();
    }
  }

  Future<void> _leaveRoom() async {
    final userId = _joinedUserId;
    if (userId == null) return;

    AppTelemetry.logAction(
      domain: 'room',
      action: 'leave',
      message: 'Live room leave started.',
      roomId: widget.roomId,
      userId: userId,
      result: 'start',
    );

    // Release any camera slot this user holds before removing their presence.
    if (_claimedSlotId != null) {
      try {
        final slotService = ref.read(roomSlotServiceProvider);
        await slotService.releaseSlot(widget.roomId, userId);
      } catch (_) {}
      _mediaController.setClaimedSlotId(null);
    }

    try {
      final myName = _senderDisplayNameById[userId] ?? userId;
      _sendSystemEvent('$myName left the room');
      await _stopPresenceHeartbeat();
      await ref
          .read(liveRoomControllerProvider(widget.roomId).notifier)
          .leaveRoom();
    } catch (_) {
      // Best-effort cleanup when users leave a room.
    } finally {
      _joinedUserId = null;
      AppTelemetry.clearRoomState();
    }
  }

  Future<void> _openManageCamViewersSheet({
    required List<RoomParticipantModel> members,
    required String currentUserId,
    required List<String> currentAllowedViewers,
  }) async {
    // Hydrate display names for all members so the sheet shows usernames.
    final missingIds = members
        .map((m) => m.userId)
        .where(
          (id) =>
              id != currentUserId && !_senderDisplayNameById.containsKey(id),
        )
        .toList(growable: false);
    if (missingIds.isNotEmpty) {
      final resolved = <String, String>{};
      try {
        final lookup = await ref
            .read(roomRepositoryProvider)
            .loadUserLookup(missingIds);
        for (final entry in lookup.entries) {
          resolved[entry.key] = resolvePublicUsername(
            uid: entry.key,
            profileUsername: entry.value.profileUsername,
          );
        }
        for (final id in missingIds) {
          resolved.putIfAbsent(id, () => resolvePublicUsername(uid: id));
        }
        if (mounted) setState(() => _senderDisplayNameById.addAll(resolved));
      } catch (_) {}
    }
    if (!mounted) return;
    final selected = Set<String>.from(currentAllowedViewers);
    // ignore: use_build_context_synchronously
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final selectableMembers = members
                .where((member) => member.userId != currentUserId)
                .toList(growable: false);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage who can view my cam',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (selectableMembers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No other room members found.'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: selectableMembers.length,
                          itemBuilder: (context, index) {
                            final member = selectableMembers[index];
                            final allowed = selected.contains(member.userId);
                            final displayName =
                                _senderDisplayNameById[member.userId] ??
                                member.userId;
                            return SwitchListTile.adaptive(
                              value: allowed,
                              title: Text(displayName),
                              subtitle: Text(
                                allowed
                                    ? 'Can view my cam'
                                    : 'Cannot view my cam',
                              ),
                              onChanged: (value) async {
                                setLocalState(() {
                                  if (value) {
                                    selected.add(member.userId);
                                  } else {
                                    selected.remove(member.userId);
                                  }
                                });
                                await ref
                                    .read(
                                      liveRoomControllerProvider(
                                        widget.roomId,
                                      ).notifier,
                                    )
                                    .approveCameraViewer(
                                      ownerUserId: currentUserId,
                                      viewerUserId: member.userId,
                                      approved: value,
                                    );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addGiftToast(RoomGiftEvent event) {
    final catalog = RoomGiftCatalog.findById(event.giftId);
    final emoji = catalog?.emoji ?? '🎁';
    final toast = _GiftToast(
      senderId: event.senderId,
      senderName: event.senderName.isNotEmpty
          ? event.senderName
          : event.senderId,
      giftEmoji: emoji,
      giftName: catalog?.displayName ?? event.giftId,
      coinCost: event.coinCost,
    );
    if (mounted) {
      setState(() => _giftToasts.insert(0, toast));
      _giftToastTimer?.cancel();
      _giftToastTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _giftToasts.clear());
      });
      // Spawn floating particle animation
      _floatingGiftKey.currentState?.spawnGift(emoji);
      // Audio cue
      RoomAudioCues.instance.playGiftReceived();
    }
  }

  Future<void> _showGiftSheet({
    required String hostId,
    required String hostName,
    required String senderName,
    required int coinBalance,
  }) async {
    RoomGiftItem? selectedGift;
    bool isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: MediaQuery.of(ctx).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Send a Gift to $hostName',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.monetization_on, size: 14),
                          label: Text('$coinBalance coins'),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: RoomGiftCatalog.items.length,
                    itemBuilder: (ctx, i) {
                      final gift = RoomGiftCatalog.items[i];
                      final chosen = selectedGift?.id == gift.id;
                      return GestureDetector(
                        onTap: isSending
                            ? null
                            : () => setSheetState(() => selectedGift = gift),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: chosen
                                ? Theme.of(ctx).colorScheme.primaryContainer
                                : Theme.of(
                                    ctx,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: chosen
                                ? Border.all(
                                    color: Theme.of(ctx).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                gift.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gift.displayName,
                                style: Theme.of(ctx).textTheme.labelSmall,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${gift.coinCost}🪙',
                                style: Theme.of(ctx).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            selectedGift == null ||
                                isSending ||
                                coinBalance < (selectedGift?.coinCost ?? 0)
                            ? null
                            : () async {
                                setSheetState(() => isSending = true);
                                try {
                                  await ref
                                      .read(roomGiftControllerProvider)
                                      .sendGift(
                                        roomId: widget.roomId,
                                        receiverId: hostId,
                                        senderName: senderName,
                                        gift: selectedGift!,
                                      );
                                  if (sheetCtx.mounted) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                  _showSnackBar(
                                    'Sent ${selectedGift!.emoji} ${selectedGift!.displayName}!',
                                  );
                                } catch (e) {
                                  if (sheetCtx.mounted) {
                                    setSheetState(() => isSending = false);
                                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not send gift: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.card_giftcard),
                        label: Text(
                          selectedGift == null
                              ? 'Select a gift'
                              : coinBalance < (selectedGift?.coinCost ?? 0)
                              ? 'Not enough coins'
                              : 'Send ${selectedGift!.emoji} for ${selectedGift!.coinCost} coins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _isTearingDown = true;
    _giftToastTimer?.cancel();
    _typingTimer?.cancel();
    _reconnectTimer?.cancel();
    _micLevelTimer?.cancel();
    _micExpiryTimer?.cancel();
    for (final t in _recentChatterTimers.values) {
      t.cancel();
    }
    _recentChatterTimers.clear();
    _giftEventsSubscription?.close();
    _mediaStateSubscription.close();
    unawaited(_clearTypingStatus());
    unawaited(_disconnectCall(resetUiState: false));
    AppTelemetry.clearRoomState();
    messageController.dispose();
    _secretMessageController.dispose();
    _chatInputFocusNode.dispose();
    _secretInputFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    ref.watch(liveRoomMediaControllerProvider(widget.roomId));
    if (user == null) {
      return const AppPageScaffold(
        safeArea: false,
        maxContentWidth: double.infinity,
        body: AppEmptyView(
          title: 'Please log in',
          message: 'Sign in to join this live room.',
          icon: Icons.lock_outline,
        ),
      );
    }
    if (_joinedUserId != user.id &&
        !_isJoiningRoom &&
        _roomJoinError == null &&
        _lastAutoJoinAttemptUserId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isTearingDown) {
          _lastAutoJoinAttemptUserId = user.id;
          _joinRoom(user.id);
        }
      });
    }
    final currentParticipantAsync = ref.watch(
      currentParticipantProvider(
        CurrentParticipantParams(roomId: widget.roomId, userId: user.id),
      ),
    );
    final currentUserPresenceAsync = ref.watch(friendPresenceProvider(user.id));
    final liveRoomState = ref.watch(liveRoomControllerProvider(widget.roomId));
    final currentSessionDisplayName = liveRoomState.displayNameFor(
      user.id,
      fallbackName: _senderDisplayNameById[user.id] ?? user.username,
    );
    final participantsAsync = ref.watch(
      participantsStreamProvider(widget.roomId),
    );
    final participantByUserId = {
      for (final participant
          in participantsAsync.valueOrNull ?? const <RoomParticipantModel>[])
        participant.userId: participant,
    };
    final messageStreamAsync = ref.watch(messageStreamProvider(widget.roomId));
    final presenceAsync = ref.watch(roomPresenceStreamProvider(widget.roomId));
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final typingUsersAsync = ref.watch(typingStreamProvider(widget.roomId));
    final micRequestsAsync = ref.watch(
      roomMicAccessRequestsProvider(widget.roomId),
    );
    final walletAsync = ref.watch(walletDetailsProvider);
    final topGifters = ref.watch(topGiftersProvider(widget.roomId));

    // Authoritative host check from the room doc — resolves before the
    // participant stream so broadcaster controls are NEVER gated on whether
    // the participant doc has been written yet.
    final roomDocData = ref
        .watch(roomDocStreamProvider(widget.roomId))
        .valueOrNull;
    final roomHostId = _asString(
      roomDocData?['ownerId'],
      fallback: _asString(roomDocData?['hostId']),
    );
    final isRoomHostByDoc = roomHostId.isNotEmpty && user.id == roomHostId;

    return currentParticipantAsync.when(
      data: (participant) {
        final isHost = ref.watch(isHostProvider(participant));
        final isCohost = ref.watch(isCohostProvider(participant));
        final isModerator = participant?.role == 'moderator';
        final role = participant?.role ?? 'audience';
        final myMicRequestAsync = ref.watch(
          myMicAccessRequestProvider((
            roomId: widget.roomId,
            requesterId: user.id,
          )),
        );
        final activeMicRequest = myMicRequestAsync.valueOrNull;
        final hasPendingMicRequest = activeMicRequest?.isPending ?? false;
        final hasMicPermission = activeMicRequest?.status != 'denied';
        if (liveRoomState.micRequested != hasPendingMicRequest ||
            liveRoomState.hasMicPermission != hasMicPermission) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref
                  .read(liveRoomControllerProvider(widget.roomId).notifier)
                  .updateAudioContext(
                    micRequested: hasPendingMicRequest,
                    hasMicPermission: hasMicPermission,
                  );
            }
          });
        }
        // Skip role-media sync when the user has an active camera slot.
        // They are already in broadcaster state; re-applying would call
        // enableVideo() a second time and disrupt the live camera track.
        // Deduplicate: only queue one postFrameCallback at a time to prevent
        // multiple concurrent _applyRoleMediaState calls from rapid rebuilds.
        // NOTE: _claimedSlotId guard was removed — _applyRoleMediaState itself
        // guards enableVideo internally, so running it while camera is on is
        // safe and necessary (e.g. user grabs mic while camera is active).
        if (_isCallReady &&
            (_appliedMediaRole != role ||
                _appliedAudioState != liveRoomState.audioState) &&
            !_roleMediaStatePending) {
          _roleMediaStatePending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _roleMediaStatePending = false;
            _applyRoleMediaState(
              role: role,
              audioState: liveRoomState.audioState,
            );
          });
        }
        // ── Mic play-time auto-release ──────────────────────────────────────
        // When a room owner sets a 30s/60s mic timer, the stage participant doc
        // carries micExpiresAt. Schedule a one-shot Timer to call releaseMic
        // on the client side; the CF also treats expired docs as stale on the
        // next grabMic call so the server stays consistent even if the client
        // misses the expiry.
        final expiresAt = role == 'stage' ? participant?.micExpiresAt : null;
        if (expiresAt != _scheduledMicExpiresAt) {
          _scheduledMicExpiresAt = expiresAt;
          _micExpiryTimer?.cancel();
          _micExpiryTimer = null;
          if (expiresAt != null) {
            final delay = expiresAt.difference(DateTime.now());
            if (delay > Duration.zero) {
              _micExpiryTimer = Timer(delay, () {
                if (!mounted) return;
                ref
                    .read(liveRoomControllerProvider(widget.roomId).notifier)
                    .releaseMic(userId: user.id)
                    .then((_) {
                      if (mounted) _showSnackBar('Your mic time is up.');
                    })
                    .catchError((_) {});
              });
            }
          }
        }
        final roomData = roomDocData;
        final roomTheme = RoomTheme.fromJson(
          roomData?['theme'] is Map<String, dynamic>
              ? roomData!['theme'] as Map<String, dynamic>
              : null,
        );
        slowModeSeconds = roomData?['slowModeSeconds'] ?? 0;
        final rawMbc = roomData?['maxBroadcasters'];
        if (rawMbc is num) _maxBroadcasters = rawMbc.toInt();
        final isLocked = roomData?['isLocked'] ?? false;
        final hostId = _asString(
          roomData?['ownerId'],
          fallback: _asString(roomData?['hostId']),
        );
        final allowGifts = roomPolicyAsync.valueOrNull?.allowGifts ?? true;
        final allowMicRequests =
            roomPolicyAsync.valueOrNull?.allowMicRequests ?? true;
        final roomPresenceList =
            presenceAsync.valueOrNull ?? const <RoomPresenceModel>[];
        final hasSelfPresenceSignal =
            roomPresenceList.any(
              (presence) =>
                  presence.userId.trim() == user.id &&
                  (presence.isOnline ||
                      (presence.userStatus?.trim().toLowerCase() ?? '') !=
                          'offline'),
            ) ||
            (currentUserPresenceAsync.valueOrNull?.inRoom?.trim() ?? '') ==
                widget.roomId;
        final membershipState = liveRoomState.membershipStateFor(user.id);
        final authorityKeepsUserInRoom = membershipState.isAuthoritativeMember;
        if (authorityKeepsUserInRoom || hasSelfPresenceSignal) {
          _markRoomMembershipConfirmed();
        }
        if (!authorityKeepsUserInRoom &&
            hasSelfPresenceSignal &&
            _joinedUserId == user.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              ref
                  .read(liveRoomControllerProvider(widget.roomId).notifier)
                  .syncPresenceNow(forceSync: true),
            );
          });
        }
        // Room-ended detection: when the host closes the room (isLive=false),
        // eject every participant so their camera slots are released and the
        // UI doesn't stay on a dead room. Only fire once the user has already
        // joined (_hasTrackedRoomJoin) to avoid false-ejecting during initial
        // Firestore CDC latency before isLive has been written.
        if (roomData != null &&
            roomData['isLive'] == false &&
            _hasTrackedRoomJoin &&
            _joinedUserId == user.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleForcedRoomExit('This room has ended.');
          });
          return const AppPageScaffold(
            safeArea: false,
            maxContentWidth: double.infinity,
            body: AppEmptyView(
              title: 'This room has ended',
              icon: Icons.videocam_off_outlined,
            ),
          );
        }
        // Ban enforcement
        if (participant?.isBanned == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleForcedRoomExit('You were banned from this room.');
          });
          return const AppPageScaffold(
            safeArea: false,
            maxContentWidth: double.infinity,
            body: AppEmptyView(
              title: 'You are banned from this room',
              icon: Icons.block_outlined,
            ),
          );
        }
        if (shouldEjectJoinedUserFromRoom(
              hasTrackedRoomJoin: _hasTrackedRoomJoin,
              membershipState: membershipState,
              lastConfirmedMembershipAt: _lastConfirmedRoomMembershipAt,
            ) &&
            _joinedUserId == user.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _verifyUnexpectedRoomRemoval(user.id);
          });
        }
        if (_roomJoinError != null && _joinedUserId == null) {
          return AppPageScaffold(
            safeArea: false,
            maxContentWidth: double.infinity,
            body: AppErrorView(
              error: _roomJoinError!,
              fallbackContext: 'join the live room',
              onRetry: () {
                if (_isJoiningRoom || _isTearingDown) {
                  return;
                }
                setState(() {
                  _roomJoinError = null;
                  _lastAutoJoinAttemptUserId = null;
                });
                _joinRoom(user.id);
              },
            ),
          );
        }
        final sendMessage = ref.read(sendMessageProvider(widget.roomId));
        final rosterParticipants =
            participantsAsync.valueOrNull ?? const <RoomParticipantModel>[];
        final rosterSelfParticipant = rosterParticipants
            .cast<RoomParticipantModel?>()
            .firstWhere((p) => p?.userId == user.id, orElse: () => null);
        final authoritativeSelfRole = liveRoomState.presentationRoleFor(
          user.id,
        );
        final authorityMicOn = liveRoomState.isOnMicByAuthority(user.id);
        final localMicActive = liveRoomState.canPublishAudio && !_isMicMuted;
        final effectiveSelfParticipant =
            (participant ?? rosterSelfParticipant)?.copyWith(
              role:
                  _appliedMediaRole ??
                  participant?.role ??
                  rosterSelfParticipant?.role ??
                  authoritativeSelfRole,
              isMuted: participant?.isMuted ?? _isMicMuted,
              isBanned:
                  participant?.isBanned ??
                  rosterSelfParticipant?.isBanned ??
                  false,
              camOn:
                  _isVideoEnabled ||
                  (participant?.camOn ?? false) ||
                  (rosterSelfParticipant?.camOn ?? false),
              micOn:
                  authorityMicOn ||
                  localMicActive ||
                  (participant?.micOn ?? false) ||
                  (rosterSelfParticipant?.micOn ?? false),
              userStatus:
                  participant?.userStatus ??
                  rosterSelfParticipant?.userStatus ??
                  'online',
              lastActiveAt: DateTime.now(),
            ) ??
            RoomParticipantModel(
              userId: user.id,
              role: authoritativeSelfRole,
              isMuted: _isMicMuted,
              isBanned: false,
              camOn: _isVideoEnabled,
              micOn: authorityMicOn || localMicActive,
              userStatus: 'online',
              joinedAt: liveRoomState.joinedAt ?? DateTime.now(),
              lastActiveAt: DateTime.now(),
            );
        final roomMessages =
            messageStreamAsync.valueOrNull ?? const <MessageModel>[];
        final presenceByUserId = <String, RoomPresenceModel>{
          for (final presence in roomPresenceList)
            if (presence.userId.trim().isNotEmpty)
              presence.userId.trim(): presence,
        };
        final recentMessageSenderIds = roomMessages
            .map((message) => message.senderId.trim())
            .where((userId) => userId.isNotEmpty)
            .toSet();

        final participantById = <String, RoomParticipantModel>{
          for (final participantItem in rosterParticipants)
            participantItem.userId: participantItem,
        };
        if (rosterSelfParticipant != null ||
            liveRoomState.shouldRenderUser(user.id)) {
          participantById[user.id] = effectiveSelfParticipant;
        }
        final stateBackedUserIds = <String>{
          ...liveRoomState.stableUserIds.where(liveRoomState.shouldRenderUser),
          ...liveRoomState.users.where(liveRoomState.shouldRenderUser),
          ...rosterParticipants.map((p) => p.userId),
          if (rosterSelfParticipant != null ||
              liveRoomState.shouldRenderUser(user.id))
            user.id,
        };
        final rawParticipantsInRoom = stateBackedUserIds
            .map((userId) {
              final existing = participantById[userId];
              if (existing != null) {
                return existing.copyWith(
                  role: userId == liveRoomState.hostId
                      ? 'host'
                      : (liveRoomState.isSpeaker(userId)
                            ? (existing.role == 'cohost' ? 'cohost' : 'stage')
                            : existing.role),
                  micOn: liveRoomState.isSpeaker(userId) || existing.micOn,
                );
              }
              return RoomParticipantModel(
                userId: userId,
                role: userId == liveRoomState.hostId
                    ? 'host'
                    : (liveRoomState.isSpeaker(userId) ? 'stage' : 'audience'),
                isMuted: false,
                isBanned: false,
                camOn: false,
                micOn: liveRoomState.isSpeaker(userId),
                userStatus: 'online',
                joinedAt: liveRoomState.joinedAt ?? DateTime.now(),
                lastActiveAt: DateTime.now(),
              );
            })
            .toList(growable: false);
        final hasPresenceSnapshot = roomPresenceList.isNotEmpty;
        final now = DateTime.now();
        final confirmedRoomUserIds = <String>{
          ...liveRoomState.users.map((userId) => userId.trim()),
          ...rosterParticipants.map(
            (participantItem) => participantItem.userId.trim(),
          ),
        }.where((participantId) => participantId.isNotEmpty).toSet();
        final participantsInRoom = hasPresenceSnapshot
            ? rawParticipantsInRoom
                  .where((participantItem) {
                    final participantUserId = participantItem.userId.trim();
                    if (participantUserId.isEmpty) {
                      return false;
                    }
                    if (!confirmedRoomUserIds.contains(participantUserId) &&
                        participantUserId != user.id) {
                      return false;
                    }

                    final presence = presenceByUserId[participantUserId];
                    final hasRecentRoomActivity =
                        recentMessageSenderIds.contains(participantUserId) ||
                        _recentChatters.contains(participantUserId) ||
                        participantItem.camOn ||
                        participantItem.micOn ||
                        liveRoomState.isOnMicByAuthority(participantUserId);
                    final joinedRecently =
                        now.difference(participantItem.joinedAt) <=
                        const Duration(minutes: 2);
                    final participantLooksOnline =
                        (participantItem.userStatus?.trim().toLowerCase() ??
                            '') ==
                        'online';
                    final hasExplicitOfflineSignal =
                        presence != null &&
                        !presence.isOnline &&
                        presence.lastHeartbeatAt == null &&
                        presence.lastSeenAt == null &&
                        !hasRecentRoomActivity;

                    if (participantUserId == user.id) {
                      return true;
                    }
                    if (hasRecentRoomActivity ||
                        (participantLooksOnline && joinedRecently)) {
                      return true;
                    }
                    return !hasExplicitOfflineSignal;
                  })
                  .toList(growable: false)
            : rawParticipantsInRoom;

        bool participantHasMicSeat(RoomParticipantModel? participantItem) {
          if (participantItem == null || participantItem.isBanned) {
            return false;
          }
          return liveRoomState.isOnMicByAuthority(participantItem.userId);
        }

        final onMicCount = participantsInRoom
            .where(participantHasMicSeat)
            .length;
        final onCamParticipants = participantsInRoom
            .where(
              (participantItem) => participantItem.userId == user.id
                  ? _isVideoEnabled
                  : participantItem.camOn,
            )
            .toList(growable: false);
        final onCamCount = onCamParticipants.length;
        final watchingCamCount = onCamParticipants.fold<int>(
          0,
          (total, participantItem) =>
              total + liveRoomState.viewerCountFor(participantItem.userId),
        );
        final roomFeelsQuiet = onMicCount == 0 && onCamCount == 0;
        final roomEnergyLabel = roomFeelsQuiet
            ? 'Room warming up'
            : watchingCamCount > 0
            ? 'People are tuned in'
            : onMicCount > 0
            ? 'Conversation is live'
            : 'Cameras are active';
        final roomPresenceSummary =
            '${participantsInRoom.length} here • $onMicCount on mic • $watchingCamCount watching cam';
        final roomEnergyPrompt = roomFeelsQuiet
            ? 'Tap Grab Mic above or turn on cam to start the vibe.'
            : onMicCount > 0
            ? 'Jump into the convo or keep the chat moving.'
            : 'Keep the room moving with chat, cam, or mic.';
        final isOnMic = participantHasMicSeat(effectiveSelfParticipant);
        final isMicFree = isOnMic || onMicCount < RoomState.maxSpeakers;

        Future<void> handleReleaseMic() async {
          try {
            await ref
                .read(liveRoomControllerProvider(widget.roomId).notifier)
                .releaseMic(userId: user.id);
            final svc = _agoraService;
            if (svc != null && _isCallReady) {
              await svc.syncAudio(RoomAudioState.muted, shouldMute: true);
              if (mounted) {
                _mediaController.setMicMuted(true);
              }
            }
            if (mounted) _showSnackBar('Mic released.');
          } catch (e) {
            if (mounted) {
              _showSnackBar('Could not release mic: $e');
            }
          }
        }

        Future<void> handleRequestMic() async {
          try {
            final result = await ref
                .read(liveRoomControllerProvider(widget.roomId).notifier)
                .requestMic(userId: user.id);
            if (mounted) {
              _showSnackBar(
                result == MicRequestResult.grabbed
                    ? 'You are now on mic.'
                    : 'Your hand is raised. You are in the mic queue.',
              );
            }
          } catch (e) {
            if (mounted) {
              _showSnackBar('Could not request mic: $e');
            }
          }
        }

        Future<void> handleCancelMicRequest() async {
          final pendingRequestId = activeMicRequest?.id ?? '';
          if (pendingRequestId.isEmpty) {
            return;
          }
          try {
            await ref
                .read(liveRoomControllerProvider(widget.roomId).notifier)
                .cancelMicRequest(pendingRequestId);
            if (mounted) {
              _showSnackBar('You left the mic queue.');
            }
          } catch (e) {
            if (mounted) {
              _showSnackBar('Could not update your mic request: $e');
            }
          }
        }

        void handleStartConversation() {
          if (isMobile && _mobileTab != 1) {
            setState(() => _mobileTab = 1);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _chatInputFocusNode.requestFocus();
          });
        }

        final canRequestMic =
            liveRoomState.audioState != RoomAudioState.denied &&
            (allowMicRequests || onMicCount < RoomState.maxSpeakers) &&
            !hasPendingMicRequest;
        final VoidCallback? onGrabMicAction = isOnMic
            ? () => unawaited(handleReleaseMic())
            : hasPendingMicRequest
            ? () => unawaited(handleCancelMicRequest())
            : canRequestMic
            ? () => unawaited(handleRequestMic())
            : null;
        _syncTelemetryForBuild(
          currentUserId: user.id,
          roomState: liveRoomState,
          participantsInRoom: participantsInRoom,
          currentParticipant: participant,
          presenceList: presenceAsync.valueOrNull ?? const [],
          globalPresence: currentUserPresenceAsync.valueOrNull,
        );
        // Hydrate display names for all roster participants whenever the
        // list changes. _hydrateSenderDisplayNames skips already-cached IDs.
        if (participantsInRoom.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _hydrateSenderDisplayNames(
                userIds: participantsInRoom.map((p) => p.userId).toList(),
                currentUserId: user.id,
              );
            }
          });
        }
        final hasBlockedParticipantInRoom = participantsInRoom.any((
          participantItem,
        ) {
          final participantId = participantItem.userId.trim();
          if (participantId.isEmpty || participantId == user.id) {
            return false;
          }
          return _excludedUserIds.contains(participantId);
        });
        final allowChat =
            liveRoomState.canChat(user.id) &&
            (roomPolicyAsync.valueOrNull?.allowChat ?? true);
        final primaryActionIsChat =
            !isOnMic && !hasPendingMicRequest && !canRequestMic && allowChat;
        final roomPrimaryActionLabel = isOnMic
            ? 'Release mic'
            : hasPendingMicRequest
            ? 'Leave queue'
            : canRequestMic
            ? 'Grab mic'
            : 'Say hello';
        final VoidCallback? roomPrimaryAction = isOnMic
            ? () => unawaited(handleReleaseMic())
            : hasPendingMicRequest
            ? () => unawaited(handleCancelMicRequest())
            : canRequestMic
            ? () => unawaited(handleRequestMic())
            : allowChat
            ? handleStartConversation
            : null;
        final String? roomSecondaryActionLabel =
            primaryActionIsChat || !allowChat ? null : 'Open chat';
        final VoidCallback? roomSecondaryAction =
            primaryActionIsChat || !allowChat ? null : handleStartConversation;
        if (isLocked && !isHost && !isCohost && !isModerator) {
          return const AppPageScaffold(
            safeArea: false,
            maxContentWidth: double.infinity,
            body: AppEmptyView(
              title: 'Room is locked',
              message:
                  'Only approved speakers and moderators can enter right now.',
              icon: Icons.lock_outline,
            ),
          );
        }
        final roomName = _asString(roomData?['name'], fallback: 'Live Room');
        final roomDescription = _asString(roomData?['description']);
        final spotlightUserId = _asString(roomData?['spotlightUserId']);
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        // ── 3-column layout helpers ──────────────────────────────────
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isMobile = screenWidth < 640;
        const kUsersW = _LiveRoomScreenState._kUsersColW;
        final effectiveChatW = isMobile ? 0.0 : _chatColW;
        final effectiveUsersW = isMobile ? 0.0 : kUsersW;
        final camsW = isMobile
            ? screenWidth
            : (screenWidth - _chatColW - kUsersW).clamp(200.0, double.infinity);
        double colLeft(String slot) {
          if (isMobile) {
            // Off-screen if not the active mobile tab
            const Map<String, int> slotTab = {'cams': 0, 'chat': 1, 'users': 2};
            return slotTab[slot] == _mobileTab ? 0.0 : -screenWidth * 2;
          }
          double l = 0;
          for (final s in _columnOrder) {
            if (s == slot) return l;
            l += switch (s) {
              'cams' => camsW,
              'chat' => effectiveChatW,
              _ => effectiveUsersW,
            };
          }
          return 0;
        }

        Widget panelMoveBtn(
          String slot,
          int dir, {
          required String tooltip,
          required IconData icon,
        }) {
          final i = _columnOrder.indexOf(slot);
          final canMove = i + dir >= 0 && i + dir < _columnOrder.length;
          return Tooltip(
            message: tooltip,
            child: InkWell(
              onTap: canMove ? () => _moveSlot(slot, dir) : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  icon,
                  size: 14,
                  color: canMove
                      ? const Color(0xFFD4A853)
                      : const Color(0xFF343640),
                ),
              ),
            ),
          );
        }

        final spotlightName = spotlightUserId.isNotEmpty
            ? (_senderDisplayNameById[spotlightUserId] ?? spotlightUserId)
            : null;
        return AppPageScaffold(
          backgroundColor: const Color(0xFF0D0A0C),
          safeArea: false,
          maxContentWidth: double.infinity,
          appBar: AppBar(
            backgroundColor: const Color(0xB40D0A0C),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(roomName),
            bottom: (roomDescription.isEmpty && _cameraStatus == null)
                ? null
                : LiveRoomAppBarStatus(
                    roomDescription: roomDescription,
                    cameraStatus: _cameraStatus,
                    tickerBuilder: (text) => _TickerBanner(text: text),
                  ),
            actions: [
              LiveRoomAppBarActions(
                isCallReady: _isCallReady,
                hasRtcService: _agoraService != null,
                isMicMuted: _isMicMuted,
                isVideoEnabled: _isVideoEnabled,
                isSharingSystemAudio: _isSharingSystemAudio,
                isMicActionInFlight: _isMicActionInFlight,
                isVideoActionInFlight: _isVideoActionInFlight,
                isSystemAudioActionInFlight: _isSystemAudioActionInFlight,
                localAudioLevel: _agoraService?.localAudioLevel ?? 0,
                showVolumeControls: _showVolumeControls,
                hasParticipants: participantsInRoom.isNotEmpty,
                pendingMicCount: isHost
                    ? (micRequestsAsync.valueOrNull
                              ?.where((r) => r.status == 'pending')
                              .length ??
                          0)
                    : 0,
                coinBalance: walletAsync.valueOrNull?.coinBalance,
                isOnMic: isOnMic,
                isMicFree: isMicFree,
                hasPendingMicRequest: hasPendingMicRequest,
                onToggleMic: RoomPermissions.canUseMic(role)
                    ? _toggleMic
                    : null,
                onToggleVideo: () async {
                  if (!_isVideoEnabled) {
                    final localPreview = _buildLocalCamContent(
                      avatarUrl: _senderAvatarUrlById[_joinedUserId ?? ''],
                    );
                    if (!context.mounted) return;
                    final confirmed = await CamPreviewSheet.show(
                      context,
                      previewWidget: localPreview,
                      isVideoEnabled: _isVideoEnabled,
                    );
                    if (confirmed != true) return;
                  }
                  await _toggleVideo();
                },
                onLongPressVideo: () {
                  final allowedViewers =
                      ref
                          .read(userCamAllowedViewersProvider(user.id))
                          .valueOrNull ??
                      const <String>[];
                  _openManageCamViewersSheet(
                    members: participantsInRoom,
                    currentUserId: user.id,
                    currentAllowedViewers: allowedViewers,
                  );
                },
                onToggleSystemAudio: _toggleSystemAudio,
                onGrabMicAction: onGrabMicAction,
                onToggleVolumeControls: () =>
                    setState(() => _showVolumeControls = !_showVolumeControls),
                onGoHome: () async {
                  await _disconnectCall();
                  await _leaveRoom();
                  if (context.mounted) context.go('/');
                },
                onOpenPeople: () => _openPeopleSheet(
                  participants: participantsInRoom,
                  currentParticipant: participant,
                  currentUserId: user.id,
                  currentUsername: currentSessionDisplayName,
                  currentAvatarUrl: user.avatarUrl,
                  hostId: hostId,
                  isHost: isHost,
                  isModerator: isModerator,
                  presenceList: presenceAsync.valueOrNull ?? const [],
                ),
                onLeaveRoom: () async {
                  await _disconnectCall();
                  await _leaveRoom();
                  _exitRoom();
                },
                onInviteFriends: () => _inviteFriendsToRoom(
                  userId: user.id,
                  username: user.username,
                  roomName: roomName,
                ),
                onShowOnlineFriends: () => _showOnlineFriendsSheet(
                  currentUserId: user.id,
                  roomId: widget.roomId,
                ),
                onShareRoom: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Join me in "$roomName" on MixVy!\nhttps://mixvy.app/room/${widget.roomId}',
                      subject: '$roomName – MixVy live room',
                    ),
                  );
                },
                onReportRoom: () => _reportTarget(
                  targetId: widget.roomId,
                  targetType: ReportTargetType.room,
                  title: 'Report room',
                  fallbackReason: 'Live room review requested',
                ),
                onReportIssue: () => BetaFeedbackSheet.show(context),
                onEditProfile: () => context.push('/edit-profile'),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── ROOM BACKGROUND (theme-driven, real-time) ────────────────
              // Reads from the room document so every participant sees the
              // same background the moment the host updates it.
              _RoomBackground(theme: roomTheme),
              // ── CAM COLUMN (order-aware) ──────────────────────────────
              // Camera panel width is whatever is left after chat + users.
              Positioned(
                left: colLeft('cams'),
                top: 0,
                bottom: 0,
                width: camsW,
                child: _agoraService != null
                    ? Builder(
                        builder: (context) {
                          final rawMaxBc = roomData?['maxBroadcasters'];
                          final slotCount = rawMaxBc is num
                              ? rawMaxBc.toInt()
                              : 6;
                          final remoteUserIds = _agoraService!.remoteUids
                              .map(
                                (uid) =>
                                    _userIdForRtcUid(uid, participantsInRoom),
                              )
                              .whereType<String>()
                              .toList();
                          if (remoteUserIds.isNotEmpty) {
                            unawaited(
                              _hydrateSenderDisplayNames(
                                userIds: remoteUserIds,
                                currentUserId: user.id,
                              ),
                            );
                          }
                          final presenceMap = <String, bool>{
                            for (final p
                                in presenceAsync.valueOrNull ??
                                    const <RoomPresenceModel>[])
                              if (p.isOnline &&
                                  (p.lastHeartbeatAt == null ||
                                      DateTime.now()
                                              .difference(p.lastHeartbeatAt!)
                                              .inSeconds <
                                          60))
                                p.userId: true,
                          };
                          final floatingIds = ref
                              .watch(floatingCamWindowsProvider)
                              .map((w) => w.id)
                              .toSet();
                          final localIsFloating = floatingIds.contains(
                            '${user.id}_local',
                          );
                          final remoteTiles = _agoraService!.remoteUids
                              .where((remoteUid) {
                                // Hide from grid if already popped out.
                                if (floatingIds.contains(
                                  '${remoteUid}_remote',
                                )) {
                                  return false;
                                }
                                final remoteUserId = _userIdForRtcUid(
                                  remoteUid,
                                  participantsInRoom,
                                );
                                if (remoteUserId == null) return true;
                                final knownOnline = presenceMap[remoteUserId];
                                if (knownOnline == null) return false;
                                return knownOnline;
                              })
                              .map((remoteUid) {
                                final remoteUserId = _userIdForRtcUid(
                                  remoteUid,
                                  participantsInRoom,
                                );
                                final canViewRemote =
                                    remoteUserId != null &&
                                    liveRoomState.canViewCamera(
                                      targetUserId: remoteUserId,
                                      viewerUserId: user.id,
                                    );
                                final tileLabel = getDisplayName(
                                  uid: remoteUserId ?? 'remote_$remoteUid',
                                  resolvedDisplayName: remoteUserId == null
                                      ? null
                                      : _senderDisplayNameById[remoteUserId],
                                  fallbackName: remoteUserId ?? 'Member',
                                );
                                return CameraWallRemoteTileData(
                                  uid: remoteUid,
                                  userId: remoteUserId,
                                  label: tileLabel,
                                  canView: canViewRemote,
                                  isSpeaking:
                                      remoteUserId != null &&
                                      liveRoomState.isSpeaker(remoteUserId),
                                  hasMic:
                                      remoteUserId != null &&
                                      liveRoomState.isSpeaker(remoteUserId),
                                  viewerCount: remoteUserId == null
                                      ? 0
                                      : liveRoomState.viewerCountFor(
                                          remoteUserId,
                                        ),
                                  avatarUrl: remoteUserId != null
                                      ? _senderAvatarUrlById[remoteUserId]
                                      : null,
                                );
                              })
                              .toList(growable: false);
                          return CameraWall(
                            roomId: widget.roomId,
                            roomName: roomName,
                            localLabel: currentSessionDisplayName,
                            showLocalTile:
                                (_agoraService?.isLocalVideoCapturing ??
                                    false) &&
                                !localIsFloating,
                            localHasMic: liveRoomState.isSpeaker(user.id),
                            localSpeaking: liveRoomState.isSpeaker(user.id),
                            localViewerCount: liveRoomState.viewerCountFor(
                              user.id,
                            ),
                            localTile: _buildLocalCamContent(
                              avatarUrl: _senderAvatarUrlById[user.id],
                            ),
                            localAvatarUrl: _senderAvatarUrlById[user.id],
                            remoteTiles: remoteTiles,
                            maxMainGridRemoteTiles: slotCount,
                            remoteTileBuilder: (tile) => KeyedSubtree(
                              key: _remoteViewKey(tile.uid),
                              child: _buildRemoteCamContent(
                                remoteUid: tile.uid,
                                canViewRemote: tile.canView,
                                avatarUrl: tile.avatarUrl,
                                onRequestAccess:
                                    (!tile.canView &&
                                        tile.userId != null &&
                                        tile.userId != _joinedUserId)
                                    ? () => _sendCamViewRequest(tile.userId!)
                                    : null,
                              ),
                            ),
                            onSubscriptionPlanChanged:
                                (highQualityUids, lowQualityUids) {
                                  _scheduleRemoteVideoLayoutSync(
                                    highQualityUids: highQualityUids,
                                    lowQualityUids: lowQualityUids,
                                  );
                                },
                            onDetachLocal: () {
                              ref
                                  .read(floatingCamWindowsProvider.notifier)
                                  .add(
                                    FloatingCamWindowData(
                                      id: '${user.id}_local',
                                      label:
                                          _senderDisplayNameById[user.id] ??
                                          'My Camera',
                                      isLocal: true,
                                      avatarUrl: _senderAvatarUrlById[user.id],
                                      offset: const Offset(40, 80),
                                      width: 320,
                                      height: 240,
                                    ),
                                  );
                            },
                            onDetachRemote: (tile) {
                              ref
                                  .read(floatingCamWindowsProvider.notifier)
                                  .add(
                                    FloatingCamWindowData(
                                      id: '${tile.uid}_remote',
                                      label: tile.label,
                                      isLocal: false,
                                      remoteUid: tile.uid,
                                      userId: tile.userId,
                                      avatarUrl: tile.avatarUrl,
                                      canViewRemote: tile.canView,
                                      offset: Offset(
                                        40 + (tile.uid % 200).toDouble(),
                                        80 + (tile.uid % 150).toDouble(),
                                      ),
                                      width: 320,
                                      height: 240,
                                    ),
                                  );
                            },
                          );
                        },
                      )
                    : const ColoredBox(
                        color: Color(0xFF0D0A0C),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🔴', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text(
                                "You're live 🔴\nInvite people or start the vibe",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              // ── CHAT COLUMN RESIZE HANDLE ─────────────────────────────
              Positioned(
                top: 0,
                bottom: 0,
                left: colLeft('chat') - 2,
                width: 4,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) => setState(() {
                      // Dragging toward chat grows/shrinks it depending on
                      // which side the chat column is on relative to cams.
                      final chatIdx = _columnOrder.indexOf('chat');
                      final camsIdx = _columnOrder.indexOf('cams');
                      final chatRightOfCams = chatIdx > camsIdx;
                      _chatColW =
                          (_chatColW +
                                  (chatRightOfCams ? -d.delta.dx : d.delta.dx))
                              .clamp(220.0, 480.0);
                    }),
                    child: Container(color: const Color(0x20D4A853)),
                  ),
                ),
              ),
              // ── CAM COLUMN MOVE BUTTONS ───────────────────────────────
              Positioned(
                top: kToolbarHeight + (roomDescription.isEmpty ? 8 : 32),
                left: colLeft('cams') + camsW - 66,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x9910131A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      panelMoveBtn(
                        'cams',
                        -1,
                        tooltip: 'Move Cams left',
                        icon: Icons.chevron_left,
                      ),
                      panelMoveBtn(
                        'cams',
                        1,
                        tooltip: 'Move Cams right',
                        icon: Icons.chevron_right,
                      ),
                    ],
                  ),
                ),
              ),
              // ── SPOTLIGHT BANNER ─────────────────────────────────────
              if (spotlightName != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 14,
                    ),
                    color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$spotlightName is in the spotlight!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isHost)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Clear spotlight',
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () async {
                              await ref
                                  .read(
                                    liveRoomControllerProvider(
                                      widget.roomId,
                                    ).notifier,
                                  )
                                  .setSpotlightUser(null);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              // ── CALL ERROR BANNER ─────────────────────────────────────
              if (_callError != null)
                Positioned(
                  top: spotlightName != null ? 38 : 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xD9FF6E84),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _callError!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isCallConnecting
                              ? null
                              : () async {
                                  await _disconnectCall();
                                  if (!mounted) return;
                                  await _connectCall(user.id);
                                },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry live media'),
                        ),
                      ],
                    ),
                  ),
                ),
              // ── CONNECTING PROGRESS ───────────────────────────────────
              if (_isCallConnecting)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
              // ── TOP GIFTERS STRIP (bottom-left, above admin bar) ──────
              if (topGifters.isNotEmpty)
                Positioned(
                  bottom: 140,
                  left: 8,
                  width: 344,
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: topGifters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (ctx, i) {
                        const medals = ['🥇', '🥈', '🥉'];
                        final gifter = topGifters[i];
                        final medal = i < 3 ? medals[i] : '${i + 1}';
                        final isFirst = i == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: isFirst
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                    ],
                                  )
                                : null,
                            color: isFirst ? null : Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(medal, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                gifter.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isFirst
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '🪙${gifter.totalCoins}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // ── OWNER ADMIN BAR (room owner/host only) ─────────────────
              if (isHost || isRoomHostByDoc)
                Positioned(
                  bottom: 92,
                  left: colLeft('cams') + 8,
                  child: _RoomOwnerAdminBar(
                    roomId: widget.roomId,
                    currentUserId: user.id,
                    isLocked: isLocked,
                    micVolume: _micVolume,
                    speakerVolume: _speakerVolume,
                    onMicVolumeChanged: _setMicVolume,
                    onSpeakerVolumeChanged: _setSpeakerVolume,
                    onToggleLock: () => ref
                        .read(
                          liveRoomControllerProvider(widget.roomId).notifier,
                        )
                        .toggleLockRoom(),
                    onEndRoom: _confirmAndEndRoom,
                    onTheme: () => _showThemePicker(roomTheme),
                  ),
                )
              // ── CO-HOST / MODERATOR CONTROLS BUTTON ────────────────────
              else if (isCohost || isModerator)
                Positioned(
                  bottom: 92,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => RoomHostControlPanel.show(
                      context,
                      roomId: widget.roomId,
                      currentUserId: user.id,
                      isOwner: false,
                      micVolume: _micVolume,
                      speakerVolume: _speakerVolume,
                      onMicVolumeChanged: _setMicVolume,
                      onSpeakerVolumeChanged: _setSpeakerVolume,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB310131A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x30D4A853)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCohost ? 'Co-host' : 'Mod Tools',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // ── VOLUME SLIDERS PANEL — anchored top-right below AppBar ───
              if (_showVolumeControls)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC10131A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x30D4A853)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.mic,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Mic',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(_micVolume * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 200,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF7C5FFF),
                              trackHeight: 2.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7,
                              ),
                            ),
                            child: Slider.adaptive(
                              value: _micVolume,
                              min: 0.0,
                              max: 2.0,
                              divisions: 40,
                              label: '${(_micVolume * 100).round()}%',
                              onChanged: _isCallReady ? _setMicVolume : null,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.volume_up,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Speaker',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(_speakerVolume * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 200,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: VelvetNoir.primary,
                              trackHeight: 2.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7,
                              ),
                            ),
                            child: Slider.adaptive(
                              value: _speakerVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label: '${(_speakerVolume * 100).round()}%',
                              onChanged: _isCallReady
                                  ? _setSpeakerVolume
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // ── CHAT COLUMN (order-aware) ──────────────────────────────
              Positioned(
                left: colLeft('chat'),
                top: 0,
                bottom: 0,
                width: isMobile ? screenWidth : _chatColW,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFF16181F),
                    border: Border(
                      left: BorderSide(color: Color(0xFF2E2F3A), width: 1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DockablePanel(
                          title: 'Room Chat',
                          icon: Icons.chat_bubble_outline,
                          backgroundColor: const Color(0xFF16181F),
                          headerColor: const Color(0xFF23253A),
                          actions: [
                            panelMoveBtn(
                              'chat',
                              -1,
                              tooltip: 'Move Chat left',
                              icon: Icons.chevron_left,
                            ),
                            panelMoveBtn(
                              'chat',
                              1,
                              tooltip: 'Move Chat right',
                              icon: Icons.chevron_right,
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(
                                height: 1,
                                color: Color(0x30D4A853),
                              ),
                              // Gift + hand raise row for non-hosts.
                              // Resolve hostId from Firestore doc first; fall back
                              // to the participants list so the row shows even when
                              // ownerId isn't written to the room doc yet.
                              Builder(
                                builder: (context) {
                                  final resolvedHostId = hostId.isNotEmpty
                                      ? hostId
                                      : participantsInRoom
                                            .where((p) => p.role == 'host')
                                            .map((p) => p.userId)
                                            .firstWhere(
                                              (id) => id.isNotEmpty,
                                              orElse: () => '',
                                            );
                                  if (isHost ||
                                      resolvedHostId.isEmpty ||
                                      resolvedHostId == user.id) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        if (allowGifts)
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.card_giftcard,
                                              size: 16,
                                            ),
                                            label: const Text('Gift'),
                                            onPressed: () => _showGiftSheet(
                                              hostId: resolvedHostId,
                                              hostName: 'Host',
                                              senderName: user.username,
                                              coinBalance:
                                                  walletAsync
                                                      .valueOrNull
                                                      ?.coinBalance ??
                                                  0,
                                            ),
                                          ),
                                        // Set Status / Away message button
                                        Tooltip(
                                          message: 'Set status / away message',
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            onTap: () => _showSetStatusDialog(
                                              context,
                                              roomId: widget.roomId,
                                              userId: user.id,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.emoji_emotions_outlined,
                                                color: Color(0xFFB09080),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Blocked relationship warning
                              participantsAsync.when(
                                data: (participants) {
                                  final hasBlocked = participants.any((p) {
                                    final pid = p.userId.trim();
                                    return pid.isNotEmpty &&
                                        pid != user.id &&
                                        _excludedUserIds.contains(pid);
                                  });
                                  if (!hasBlocked) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      4,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Blocked relationship in room. Leave to continue safely.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onErrorContainer,
                                          ),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                              // On-mic panel: shows host, co-hosts, and stage users
                              OnMicPanel(
                                roomId: widget.roomId,
                                currentUserId: user.id,
                                displayNameById: _senderDisplayNameById,
                              ),
                              // Mic queue (hand-raise queue, visible when non-empty)
                              MicQueuePanel(
                                roomId: widget.roomId,
                                currentUserId: user.id,
                                isHost: isHost || isCohost || isModerator,
                                displayNameById: _senderDisplayNameById,
                                onApprove: (request) {
                                  ref
                                      .read(
                                        liveRoomControllerProvider(
                                          widget.roomId,
                                        ).notifier,
                                      )
                                      .approveMicRequest(request)
                                      .ignore();
                                },
                                onDeny: (request) {
                                  ref
                                      .read(
                                        liveRoomControllerProvider(
                                          widget.roomId,
                                        ).notifier,
                                      )
                                      .denyMicRequest(request.id)
                                      .ignore();
                                },
                                onWithdraw: (request) {
                                  ref
                                      .read(
                                        liveRoomControllerProvider(
                                          widget.roomId,
                                        ).notifier,
                                      )
                                      .cancelMicRequest(request.id)
                                      .ignore();
                                },
                              ),
                              // Messages list
                              Expanded(
                                child: messageStreamAsync.when(
                                  data: (messages) {
                                    if (messages.length !=
                                        _lastRenderedMessageCount) {
                                      // Play a soft ping for new incoming messages (not own).
                                      if (messages.length >
                                          _lastRenderedMessageCount) {
                                        final newest = messages.last;
                                        if (newest.senderId != _joinedUserId) {
                                          if (newest.type == 'private') {
                                            RoomAudioCues.instance
                                                .playPrivateMessage();
                                          } else if (newest.type == 'normal') {
                                            RoomAudioCues.instance
                                                .playNewMessage();
                                          }
                                        }
                                        if (newest.type == 'normal') {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                _markRecentChatter(
                                                  newest.senderId,
                                                );
                                              });
                                        }
                                      }
                                      _lastRenderedMessageCount =
                                          messages.length;
                                      // Double postFrameCallback: first frame lets
                                      // ListView render the new item, second frame
                                      // ensures maxScrollExtent is fully updated.
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (scrollController
                                                          .hasClients &&
                                                      scrollController
                                                          .position
                                                          .hasContentDimensions) {
                                                    scrollController.jumpTo(
                                                      scrollController
                                                          .position
                                                          .maxScrollExtent,
                                                    );
                                                  }
                                                });
                                          });
                                    }
                                    if (messages.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons
                                                    .chat_bubble_outline_rounded,
                                                color: const Color(0xFFD4A853),
                                                size: 28,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                roomEnergyLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                roomPresenceSummary,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color(0xFFD4A853),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'No messages yet',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                roomEnergyPrompt,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.all(8),
                                      itemCount: messages.length,
                                      itemBuilder: (context, i) {
                                        if (i == 0) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                _hydrateSenderDisplayNames(
                                                  messages: messages,
                                                  currentUserId: user.id,
                                                );
                                              });
                                        }
                                        final msg = messages[i];
                                        return MessageBubble(
                                          message: msg,
                                          isMe: msg.senderId == user.id,
                                          senderLabel: _senderLabelFor(
                                            senderId: msg.senderId,
                                            currentUserId: user.id,
                                            currentUsername:
                                                currentSessionDisplayName,
                                          ),
                                          senderVipLevel:
                                              _senderVipLevelById[msg
                                                  .senderId] ??
                                              0,
                                          senderCamOn:
                                              participantByUserId[msg.senderId]
                                                  ?.camOn ??
                                              false,
                                          senderAvatarUrl:
                                              _senderAvatarUrlById[msg
                                                  .senderId],
                                          onTapSender: (senderId) =>
                                              UserProfilePopup.show(
                                                context,
                                                ref,
                                                userId: senderId,
                                              ),
                                          onTapCam: msg.senderId == user.id
                                              ? null
                                              : (senderId) =>
                                                    _sendCamViewRequest(
                                                      senderId,
                                                    ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, _) =>
                                      Center(child: Text('Error: $e')),
                                ),
                              ),
                              if (cooldownMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    cooldownMessage,
                                    style: const TextStyle(
                                      color: Color(0xFFFF6E84),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (_showEmojiTray)
                                SizedBox(
                                  height: 68,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      4,
                                    ),
                                    child: _buildEmojiTray(),
                                  ),
                                ),
                              Builder(
                                builder: (context) {
                                  final currentUid = _joinedUserId ?? '';
                                  final names =
                                      (typingUsersAsync.valueOrNull ??
                                              const <String, bool>{})
                                          .entries
                                          .where(
                                            (entry) =>
                                                entry.key != currentUid &&
                                                entry.value,
                                          )
                                          .map(
                                            (entry) =>
                                                _senderDisplayNameById[entry
                                                    .key] ??
                                                'Someone',
                                          )
                                          .toList(growable: false);
                                  if (names.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final label = names.length == 1
                                      ? '${names[0]} is typing…'
                                      : '${names.join(', ')} are typing…';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              // Rich text toolbar (toggled)
                              if (_showRichToolbar)
                                RichTextToolbar(
                                  controller: messageController,
                                  pendingColorHex: _pendingRichColorHex,
                                  onPendingColorChanged: (value) => setState(
                                    () => _pendingRichColorHex = value,
                                  ),
                                  onChanged: () => setState(() {}),
                                ),
                              // Input row
                              SafeArea(
                                top: false,
                                left: false,
                                right: false,
                                minimum: const EdgeInsets.only(bottom: 4),
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.only(
                                    bottom: keyboardInset > 0 ? 4 : 0,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      4,
                                      8,
                                      8,
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Emojis',
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          icon: Icon(
                                            _showEmojiTray
                                                ? Icons.emoji_emotions
                                                : Icons.emoji_emotions_outlined,
                                          ),
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(
                                              () => _showEmojiTray =
                                                  !_showEmojiTray,
                                            );
                                          },
                                        ),
                                        Tooltip(
                                          message: _showRichToolbar
                                              ? 'Hide formatting'
                                              : 'Rich text formatting',
                                          child: IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            icon: Icon(
                                              Icons.text_format,
                                              color: _showRichToolbar
                                                  ? const Color(0xFFD4A853)
                                                  : const Color(0xFF5A5E6B),
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                              () => _showRichToolbar =
                                                  !_showRichToolbar,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: messageController,
                                            focusNode: _chatInputFocusNode,
                                            onTap: () => _chatInputFocusNode
                                                .requestFocus(),
                                            onChanged: (_) => _onTypingInput(),
                                            enabled:
                                                !isSending &&
                                                participant?.isMuted != true &&
                                                participant?.isBanned != true &&
                                                !hasBlockedParticipantInRoom,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            cursorColor: const Color(
                                              0xFFD4A853,
                                            ),
                                            textInputAction:
                                                TextInputAction.send,
                                            scrollPadding: EdgeInsets.only(
                                              top: 24,
                                              bottom: keyboardInset + 120,
                                            ),
                                            onSubmitted:
                                                isSending ||
                                                    participant?.isMuted ==
                                                        true ||
                                                    participant?.isBanned ==
                                                        true ||
                                                    !allowChat ||
                                                    hasBlockedParticipantInRoom
                                                ? null
                                                : (text) async {
                                                    final trimmed = text.trim();
                                                    if (trimmed.isEmpty) return;
                                                    final outgoingMessage =
                                                        _buildOutgoingChatMessage(
                                                          trimmed,
                                                        );
                                                    if (slowModeSeconds > 0 &&
                                                        lastMessageTime !=
                                                            null) {
                                                      final secs = DateTime.now()
                                                          .difference(
                                                            lastMessageTime!,
                                                          )
                                                          .inSeconds;
                                                      if (secs <
                                                          slowModeSeconds) {
                                                        setState(() {
                                                          cooldownMessage =
                                                              'Slow mode on. Wait ${slowModeSeconds - secs}s.';
                                                        });
                                                        return;
                                                      }
                                                    }
                                                    setState(
                                                      () => isSending = true,
                                                    );
                                                    try {
                                                      await sendMessage(
                                                        outgoingMessage,
                                                      );
                                                      lastMessageTime =
                                                          DateTime.now();
                                                      cooldownMessage = '';
                                                      messageController.clear();
                                                      _pendingRichColorHex =
                                                          null;
                                                      _showEmojiTray = false;
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              e.toString(),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(
                                                          () =>
                                                              isSending = false,
                                                        );
                                                      }
                                                    }
                                                  },
                                            decoration: InputDecoration(
                                              hintText:
                                                  participant?.isMuted == true
                                                  ? 'You are muted'
                                                  : participant?.isBanned ==
                                                        true
                                                  ? 'You are banned'
                                                  : hasBlockedParticipantInRoom
                                                  ? 'Blocked relationship in room'
                                                  : !allowChat
                                                  ? 'Chat disabled by host'
                                                  : 'Type a message…',
                                              hintStyle: const TextStyle(
                                                color: Colors.white38,
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFF18131D,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0x66D4A853),
                                                  width: 1.1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0x88D4A853),
                                                  width: 1.1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD4A853),
                                                  width: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message: 'Send message',
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(40, 40),
                                              padding: const EdgeInsets.all(10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed:
                                                isSending ||
                                                    participant?.isMuted ==
                                                        true ||
                                                    participant?.isBanned ==
                                                        true ||
                                                    !allowChat ||
                                                    hasBlockedParticipantInRoom
                                                ? null
                                                : () async {
                                                    final trimmed =
                                                        messageController.text
                                                            .trim();
                                                    if (trimmed.isEmpty) {
                                                      return;
                                                    }
                                                    final outgoingMessage =
                                                        _buildOutgoingChatMessage(
                                                          trimmed,
                                                        );
                                                    if (slowModeSeconds > 0 &&
                                                        lastMessageTime !=
                                                            null) {
                                                      final secs = DateTime.now()
                                                          .difference(
                                                            lastMessageTime!,
                                                          )
                                                          .inSeconds;
                                                      if (secs <
                                                          slowModeSeconds) {
                                                        setState(() {
                                                          cooldownMessage =
                                                              'Slow mode on. Wait ${slowModeSeconds - secs}s.';
                                                        });
                                                        return;
                                                      }
                                                    }
                                                    setState(
                                                      () => isSending = true,
                                                    );
                                                    try {
                                                      await sendMessage(
                                                        outgoingMessage,
                                                      );
                                                      lastMessageTime =
                                                          DateTime.now();
                                                      cooldownMessage = '';
                                                      messageController.clear();
                                                      _pendingRichColorHex =
                                                          null;
                                                      _showEmojiTray = false;
                                                      if (!_hasTrackedFirstMessage) {
                                                        _hasTrackedFirstMessage =
                                                            true;
                                                        await AnalyticsService()
                                                            .logEvent(
                                                              'first_message_sent',
                                                              params: {
                                                                'room_id':
                                                                    widget
                                                                        .roomId,
                                                                'user_id':
                                                                    user.id,
                                                              },
                                                            );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              e.toString(),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } finally {
                                                      if (context.mounted) {
                                                        setState(
                                                          () =>
                                                              isSending = false,
                                                        );
                                                      }
                                                    }
                                                  },
                                            child: isSending
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.send_rounded,
                                                    size: 18,
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── USERS COLUMN (order-aware) ────────────────────────────
              Positioned(
                left: colLeft('users'),
                top: 0,
                bottom: 0,
                width: isMobile ? screenWidth : kUsersW,
                child: ColoredBox(
                  color: const Color(0xFF161A21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // AppBar spacer
                      SizedBox(
                        height: roomDescription.isEmpty
                            ? kToolbarHeight - 12
                            : kToolbarHeight + 8,
                      ),
                      // ── Room energy card above Users header ───────────
                      if (roomEnergyLabel.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: _RoomPresenceEnergyCard(
                            title: roomEnergyLabel,
                            statusLabel: roomEnergyLabel == 'Room warming up'
                                ? 'Start it'
                                : 'Live now',
                            summary: roomPresenceSummary,
                            prompt: roomEnergyPrompt,
                            isQuiet: roomFeelsQuiet,
                            primaryActionLabel: roomPrimaryActionLabel,
                            onPrimaryAction: roomPrimaryAction,
                            secondaryActionLabel: roomSecondaryActionLabel,
                            onSecondaryAction: roomSecondaryAction,
                          ),
                        ),
                      // 32 px header row with ◄ ► move buttons
                      Container(
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF241820),
                          border: Border(
                            left: BorderSide(
                              color: Color(0xFF2E2F3A),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Color(0xFFD4A853),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Users',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            panelMoveBtn(
                              'users',
                              -1,
                              tooltip: 'Move Users left',
                              icon: Icons.chevron_left,
                            ),
                            panelMoveBtn(
                              'users',
                              1,
                              tooltip: 'Move Users right',
                              icon: Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _RoomRosterSidebar(
                          topPadding: 0,
                          roomState: liveRoomState,
                          participants: participantsInRoom,
                          displayNameById: Map.unmodifiable(
                            _senderDisplayNameById,
                          ),
                          vipLevelById: Map.unmodifiable(_senderVipLevelById),
                          genderById: Map.unmodifiable(_senderGenderById),
                          currentUserId: user.id,
                          currentUsername: currentSessionDisplayName,
                          roomEnergyLabel: roomEnergyLabel,
                          roomEnergySummary: roomPresenceSummary,
                          roomEnergyPrompt: roomEnergyPrompt,
                          presenceList: presenceAsync.valueOrNull ?? const [],
                          pendingMicCount:
                              micRequestsAsync.valueOrNull
                                  ?.where((r) => r.status == 'pending')
                                  .length ??
                              0,
                          currentUserRole: liveRoomState.isSpeaker(user.id)
                              ? 'stage'
                              : (liveRoomState.hostId == user.id
                                    ? 'host'
                                    : 'audience'),
                          isMicFree:
                              liveRoomState.speakerIds.length <
                              RoomState.maxSpeakers,
                          isLocalVideoEnabled: _isVideoEnabled,
                          localSpeaking: liveRoomState.isSpeaker(user.id),
                          recentChatters: Set.unmodifiable({
                            ..._recentChatters,
                            ...(messageStreamAsync.valueOrNull
                                    ?.where(
                                      (message) => message.type == 'normal',
                                    )
                                    .map((message) => message.senderId.trim())
                                    .where((senderId) => senderId.isNotEmpty) ??
                                const <String>[]),
                          }),
                          remoteUids: _agoraService?.remoteUids ?? const [],
                          isSpeakingFn: (uid) =>
                              _agoraService?.isRemoteSpeaking(uid) ?? false,
                          uidToUserId: (uid) =>
                              _userIdForRtcUid(uid, participantsInRoom),
                          onReleaseMic: () => unawaited(handleReleaseMic()),
                          onJoinQueue: onGrabMicAction,
                          onWhisper: (p) async {
                            final currentUser = ref.read(userProvider);
                            if (currentUser == null) return;
                            try {
                              final conversationId = await ref
                                  .read(messagingControllerProvider)
                                  .createDirectConversation(
                                    userId1: currentUser.id,
                                    user1Name: currentUser.username,
                                    user1AvatarUrl: currentUser.avatarUrl,
                                    userId2: p.userId,
                                    user2Name:
                                        _senderDisplayNameById[p.userId] ??
                                        p.userId,
                                    user2AvatarUrl:
                                        _senderAvatarUrlById[p.userId],
                                  );
                              if (!context.mounted) return;
                              FloatingWhisperPanel.show(
                                context,
                                ref,
                                conversationId: conversationId,
                                peerName:
                                    _senderDisplayNameById[p.userId] ??
                                    p.userId,
                                peerAvatarUrl: _senderAvatarUrlById[p.userId],
                              );
                            } catch (e) {
                              _showSnackBar('Could not open whisper: $e');
                            }
                          },
                          onSecretMessage: (p) =>
                              _openSecretComposerForParticipant(p),
                          secretComposerTarget: _secretComposerTarget,
                          secretComposerTextController:
                              _secretMessageController,
                          secretComposerFocusNode: _secretInputFocusNode,
                          isSendingSecretMessage: _isSendingSecretMessage,
                          onSendSecretMessage: _secretComposerTarget == null
                              ? null
                              : () => _sendPrivateRoomMessageToParticipant(
                                  _secretComposerTarget!,
                                ),
                          onCancelSecretMessage: _closeSecretComposer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_giftToasts.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Column(
                      children: _giftToasts.take(3).map((toast) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xBF10131A),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                toast.giftEmoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${toast.senderName} sent ${toast.giftName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              // Floating cam windows layer (detached tiles)
              FloatingCamWindowLayer(
                contentBuilder: _buildFloatingCamWindowContent,
                onReattach: (id) {
                  ref.read(floatingCamWindowsProvider.notifier).remove(id);
                },
              ),
              // Floating emoji particles (gift animations)
              Positioned.fill(
                child: FloatingGiftOverlay(key: _floatingGiftKey),
              ),
              // Buzz overlay (full-screen flash on receipt)
              Positioned.fill(
                child: BuzzOverlay(
                  key: _buzzKey,
                  child: const SizedBox.expand(),
                ),
              ),
              // Debug inspector button — only visible in kDebugMode builds.
              if (kDebugMode)
                Positioned(
                  right: 8,
                  bottom: 72,
                  child: RoomInspectorButton(roomId: widget.roomId),
                ),
            ],
          ),
          bottomNavigationBar: !isMobile
              ? null
              : Container(
                  color: const Color(0xFF161A21),
                  child: Row(
                    children: [
                      _MobileTabBtn(
                        icon: Icons.videocam_outlined,
                        activeIcon: Icons.videocam_rounded,
                        label: 'Camera',
                        active: _mobileTab == 0,
                        onTap: () => setState(() => _mobileTab = 0),
                      ),
                      _MobileTabBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Chat',
                        active: _mobileTab == 1,
                        onTap: () => setState(() => _mobileTab = 1),
                      ),
                      _MobileTabBtn(
                        icon: Icons.people_outline_rounded,
                        activeIcon: Icons.people_rounded,
                        label: 'People',
                        active: _mobileTab == 2,
                        onTap: () => setState(() => _mobileTab = 2),
                      ),
                    ],
                  ),
                ),
        );
      },
      loading: () => AppPageScaffold(
        backgroundColor: const Color(0xFF0D0A0C),
        safeArea: false,
        maxContentWidth: double.infinity,
        body: Stack(
          children: [
            const AppLoadingView(label: 'Joining live room...'),
            // Show mic/cam controls while participant stream is loading so
            // users don't lose their buttons during reconnect/init lag.
            Positioned(
              bottom: 40,
              left: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xB310131A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x30D4A853)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LiveRoomMediaActionStrip(
                          isCallReady: _isCallReady,
                          hasRtcService: _agoraService != null,
                          isMicMuted: _isMicMuted,
                          isVideoEnabled: _isVideoEnabled,
                          isSharingSystemAudio: _isSharingSystemAudio,
                          isMicActionInFlight: _isMicActionInFlight,
                          isVideoActionInFlight: _isVideoActionInFlight,
                          isSystemAudioActionInFlight:
                              _isSystemAudioActionInFlight,
                          localAudioLevel: _agoraService?.localAudioLevel ?? 0,
                          onToggleMic: _toggleMic,
                          onToggleVideo: _toggleVideo,
                          showSystemAudioButton: false,
                          onToggleSystemAudio: _toggleSystemAudio,
                          showMicLevel: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => AppPageScaffold(
        safeArea: false,
        maxContentWidth: double.infinity,
        body: AppErrorView(error: e, fallbackContext: 'load the live room'),
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Mobile tab bar button
// ---------------------------------------------------------------------------

class _MobileTabBtn extends StatelessWidget {
  const _MobileTabBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFD4A853);
    const inactive = Color(0xFFB09080);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                color: active ? primary : inactive,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? primary : inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paltalk-style Roster Sidebar
// Shows: Talking Now / Mic Queue / On Cam / Chatting sections
// ---------------------------------------------------------------------------

class _RoomRosterSidebar extends StatelessWidget {
  const _RoomRosterSidebar({
    required this.roomState,
    required this.participants,
    required this.displayNameById,
    required this.vipLevelById,
    required this.genderById,
    required this.currentUserId,
    required this.currentUsername,
    this.roomEnergyLabel = '',
    this.roomEnergySummary = '',
    this.roomEnergyPrompt = '',
    required this.presenceList,
    required this.pendingMicCount,
    required this.isLocalVideoEnabled,
    required this.localSpeaking,
    required this.remoteUids,
    required this.isSpeakingFn,
    required this.uidToUserId,
    required this.isMicFree,
    required this.currentUserRole,
    this.onJoinQueue,
    this.onReleaseMic,
    this.onWhisper,
    this.onSecretMessage,
    this.secretComposerTarget,
    this.secretComposerTextController,
    this.secretComposerFocusNode,
    this.isSendingSecretMessage = false,
    this.onSendSecretMessage,
    this.onCancelSecretMessage,
    this.topPadding = kToolbarHeight,
    this.recentChatters = const {},
  });

  final RoomState roomState;
  final List<RoomParticipantModel> participants;
  final Map<String, String> displayNameById;
  final Map<String, int> vipLevelById;
  final Map<String, String?> genderById;
  final String currentUserId;
  final String currentUsername;
  final String roomEnergyLabel;
  final String roomEnergySummary;
  final String roomEnergyPrompt;
  final List<RoomPresenceModel> presenceList;
  final int pendingMicCount;
  final bool isLocalVideoEnabled;
  final bool localSpeaking;
  final List<int> remoteUids;
  final bool Function(int uid) isSpeakingFn;
  final String? Function(int uid) uidToUserId;
  final bool isMicFree;
  final String currentUserRole;
  final VoidCallback? onJoinQueue;
  final VoidCallback? onReleaseMic;
  final void Function(RoomParticipantModel participant)? onWhisper;
  final void Function(RoomParticipantModel participant)? onSecretMessage;
  final RoomParticipantModel? secretComposerTarget;
  final TextEditingController? secretComposerTextController;
  final FocusNode? secretComposerFocusNode;
  final bool isSendingSecretMessage;
  final VoidCallback? onSendSecretMessage;
  final VoidCallback? onCancelSecretMessage;
  final double topPadding;
  final Set<String> recentChatters;

  static const _kBg = Color(0xFF161A21);
  static const _kDivider = Color(0xFF2A2D38);
  static const _kSubtle = Color(0xFF5A5E6B);

  Color _nameColor(int level) {
    if (level >= 20) return const Color(0xFFFFD700);
    if (level >= 10) return const Color(0xFFC45E7A);
    if (level >= 5) return const Color(0xFF4CAF50);
    return Colors.white.withValues(alpha: 0.85);
  }

  String? _roleLabel(RoomParticipantModel? participant) {
    final role = participant?.role ?? '';
    switch (role) {
      case 'host':
      case 'owner':
        return 'Host';
      case 'cohost':
        return 'Co-host';
      case 'moderator':
        return 'Mod';
      case 'stage':
        return 'On mic';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayNameFor(String userId) {
      final selfName = currentUsername.trim();
      final hydratedName = displayNameById[userId]?.trim() ?? '';
      final fallbackName = userId == currentUserId
          ? (selfName.isEmpty ? hydratedName : selfName)
          : (hydratedName.isEmpty ? userId : hydratedName);
      final resolvedName = roomState.displayNameFor(
        userId,
        fallbackName: getDisplayName(
          uid: userId,
          resolvedDisplayName: hydratedName,
          fallbackName: fallbackName,
        ),
      );

      final trimmedResolved = resolvedName.trim();
      final normalizedUserId = userId.trim();
      final looksLikeSimpleHandle = RegExp(
        r'^[a-z][a-z0-9_]{2,24}$',
      ).hasMatch(trimmedResolved);
      if (trimmedResolved == normalizedUserId && looksLikeSimpleHandle) {
        return '${trimmedResolved[0].toUpperCase()}${trimmedResolved.substring(1)}';
      }
      return trimmedResolved;
    }

    final participantByUserId = <String, RoomParticipantModel>{
      for (final participant in participants) participant.userId: participant,
    };
    final onlinePresenceUserIds = {
      for (final presence in presenceList)
        if (presence.isOnline && presence.userId.trim().isNotEmpty)
          presence.userId.trim(),
    };
    final hasPresenceSnapshot = presenceList.isNotEmpty;
    for (final roomUserId in roomState.users) {
      final normalizedUserId = roomUserId.trim();
      final shouldIncludeFromSharedState =
          normalizedUserId == currentUserId ||
          !hasPresenceSnapshot ||
          onlinePresenceUserIds.contains(normalizedUserId) ||
          recentChatters.contains(normalizedUserId) ||
          roomState.isSpeaker(normalizedUserId);
      if (normalizedUserId.isEmpty ||
          participantByUserId.containsKey(normalizedUserId) ||
          !roomState.shouldRenderUser(normalizedUserId) ||
          !shouldIncludeFromSharedState) {
        continue;
      }
      participantByUserId[normalizedUserId] = RoomParticipantModel(
        userId: normalizedUserId,
        role: roomState.roleFor(normalizedUserId),
        isMuted: false,
        isBanned: false,
        camOn: false,
        micOn: roomState.isSpeaker(normalizedUserId),
        userStatus: 'online',
        joinedAt:
            roomState.snapshotFor(normalizedUserId)?.joinedAt ?? DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
    }
    if (!participantByUserId.containsKey(currentUserId) &&
        roomState.shouldRenderUser(currentUserId)) {
      participantByUserId[currentUserId] = RoomParticipantModel(
        userId: currentUserId,
        role: currentUserId == roomState.hostId
            ? 'host'
            : (roomState.isSpeaker(currentUserId) ? 'stage' : 'audience'),
        isMuted: false,
        isBanned: false,
        camOn: isLocalVideoEnabled,
        micOn: roomState.isSpeaker(currentUserId) || localSpeaking,
        joinedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
    }

    final isCurrentUserCamLive =
        isLocalVideoEnabled ||
        (participantByUserId[currentUserId]?.camOn ?? false);

    // ── Compute speaking user IDs from deterministic RoomState ──────────
    final speakingUserIds = roomState.speakerIds.toSet();

    // ── On-cam participants ───────────────────────────────────
    final onCamParticipants = participants
        .where(
          (p) => p.userId == currentUserId
              ? (isLocalVideoEnabled || p.camOn)
              : p.camOn,
        )
        .toList(growable: false);

    // ── Sort: host → cohost → mod → audience, with self visible ──
    final sorted = participantByUserId.values.toList(growable: false)
      ..sort((a, b) {
        int rank(String r) => switch (r) {
          'host' || 'owner' => 0,
          'cohost' => 1,
          'moderator' => 2,
          _ => 3,
        };
        final rankCompare = rank(a.role).compareTo(rank(b.role));
        if (rankCompare != 0) {
          return rankCompare;
        }
        if (a.userId == currentUserId && b.userId != currentUserId) {
          return -1;
        }
        if (b.userId == currentUserId && a.userId != currentUserId) {
          return 1;
        }
        final recentChatCompare = (recentChatters.contains(b.userId) ? 1 : 0)
            .compareTo(recentChatters.contains(a.userId) ? 1 : 0);
        if (recentChatCompare != 0) {
          return recentChatCompare;
        }
        return displayNameFor(
          a.userId,
        ).toLowerCase().compareTo(displayNameFor(b.userId).toLowerCase());
      });

    return ColoredBox(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Space for the floating AppBar above
          SizedBox(height: topPadding),
          // ── Talking Now ──────────────────────────────────────
          _RosterHeader(
            label: 'Talking Now',
            icon: Icons.mic,
            iconColor: const Color(0xFFC45E7A),
          ),
          if (speakingUserIds.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Nobody on mic yet',
                style: TextStyle(color: _kSubtle, fontSize: 12),
              ),
            )
          else
            ...speakingUserIds
                .take(3)
                .map(
                  (uid) => _RosterRow(
                    displayName: displayNameFor(uid),
                    vipLevel: vipLevelById[uid] ?? 0,
                    nameColor: _nameColor(vipLevelById[uid] ?? 0),
                    roleLabel: _roleLabel(participantByUserId[uid]),
                    isCurrentUser: uid == currentUserId,
                    camOn: participantByUserId[uid]?.camOn ?? false,
                    trailingIcon: Icons.mic,
                    trailingColor: const Color(0xFFC45E7A),
                    isWatchingMe:
                        isCurrentUserCamLive &&
                        roomState.isWatchingMe(
                          myUserId: currentUserId,
                          otherUserId: uid,
                        ),
                    onSecretMessage: onSecretMessage == null
                        ? null
                        : () => onSecretMessage!(participantByUserId[uid]!),
                    onDirectMessage: onWhisper == null
                        ? null
                        : () => onWhisper!(participantByUserId[uid]!),
                  ),
                ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          // ── Mic Queue ────────────────────────────────────────
          _RosterHeader(
            label: 'Mic Queue $pendingMicCount',
            icon: Icons.queue_music,
            iconColor: const Color(0xFFD4A853),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Text(
              roomState.isSpeaker(currentUserId)
                  ? 'Use the top bar button to release your mic.'
                  : isMicFree
                  ? 'Use the top bar button to grab the mic.'
                  : 'Use the top bar button to join the mic queue.',
              style: const TextStyle(color: _kSubtle, fontSize: 11),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          // ── On Cam ───────────────────────────────────────────
          _RosterHeader(
            label: 'On Cam ${onCamParticipants.length}',
            icon: Icons.videocam,
            iconColor: const Color(0xFF4CAF50),
          ),
          if (onCamParticipants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'No cameras live yet — be the first to go live',
                style: TextStyle(color: _kSubtle, fontSize: 11),
              ),
            )
          else
            ...onCamParticipants
                .take(8)
                .map(
                  (p) => _RosterRow(
                    displayName: displayNameFor(p.userId),
                    vipLevel: vipLevelById[p.userId] ?? 0,
                    nameColor: _nameColor(vipLevelById[p.userId] ?? 0),
                    gender: genderById[p.userId],
                    roleLabel: _roleLabel(p),
                    isCurrentUser: p.userId == currentUserId,
                    trailingIcon: Icons.videocam,
                    trailingColor: Colors.white38,
                    camOn: true,
                    hasRecentChat: recentChatters.contains(p.userId),
                    isWatchingMe:
                        isCurrentUserCamLive &&
                        roomState.isWatchingMe(
                          myUserId: currentUserId,
                          otherUserId: p.userId,
                        ),
                    onSecretMessage: onSecretMessage == null
                        ? null
                        : () => onSecretMessage!(p),
                    onDirectMessage: onWhisper == null
                        ? null
                        : () => onWhisper!(p),
                  ),
                ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          // ── In Room ───────────────────────────────────────────
          _RosterHeader(
            label: 'In Room ${sorted.length}',
            icon: Icons.people_outline,
            iconColor: const Color(0xFFB09080),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No one else is here yet. Invite people to join the room.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final p = sorted[i];
                      final vip = vipLevelById[p.userId] ?? 0;
                      return GestureDetector(
                        onTap: onWhisper == null ? null : () => onWhisper!(p),
                        child: _RosterRow(
                          displayName: displayNameFor(p.userId),
                          vipLevel: vip,
                          nameColor: _nameColor(vip),
                          gender: genderById[p.userId],
                          roleLabel: _roleLabel(p),
                          isCurrentUser: p.userId == currentUserId,
                          camOn: p.camOn,
                          trailingIcon: p.role == 'host' || p.role == 'owner'
                              ? Icons.star
                              : p.role == 'cohost'
                              ? Icons.star_half
                              : null,
                          trailingColor: const Color(0xFFFFD700),
                          hasRecentChat: recentChatters.contains(p.userId),
                          isWatchingMe:
                              isCurrentUserCamLive &&
                              roomState.isWatchingMe(
                                myUserId: currentUserId,
                                otherUserId: p.userId,
                              ),
                          onSecretMessage: onSecretMessage == null
                              ? null
                              : () => onSecretMessage!(p),
                          onDirectMessage: onWhisper == null
                              ? null
                              : () => onWhisper!(p),
                        ),
                      );
                    },
                  ),
          ),
          if (secretComposerTarget != null &&
              secretComposerTextController != null)
            _InlineSecretComposer(
              targetDisplayName: displayNameFor(secretComposerTarget!.userId),
              controller: secretComposerTextController!,
              focusNode: secretComposerFocusNode ?? FocusNode(),
              isSending: isSendingSecretMessage,
              onCancel: onCancelSecretMessage,
              onSend: onSendSecretMessage,
            ),
        ],
      ),
    );
  }
}

class _RosterHeader extends StatelessWidget {
  const _RosterHeader({
    required this.label,
    required this.icon,
    this.iconColor = Colors.white54,
  });

  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF241820),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB09080),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomPresenceEnergyCard extends StatelessWidget {
  const _RoomPresenceEnergyCard({
    required this.title,
    required this.statusLabel,
    required this.summary,
    required this.prompt,
    required this.isQuiet,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String statusLabel;
  final String summary;
  final String prompt;
  final bool isQuiet;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final accent = isQuiet ? const Color(0xFFD4A853) : const Color(0xFFC45E7A);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xE6141018),
            isQuiet ? const Color(0xCC302316) : const Color(0xCC351623),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 0.6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isQuiet ? Icons.auto_awesome : Icons.local_fire_department,
                color: accent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prompt,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if ((primaryActionLabel?.trim().isNotEmpty ?? false) ||
              (secondaryActionLabel?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (primaryActionLabel?.trim().isNotEmpty ?? false)
                  FilledButton.tonal(
                    onPressed: onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.18),
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(primaryActionLabel!),
                  ),
                if (secondaryActionLabel?.trim().isNotEmpty ?? false)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.displayName,
    required this.vipLevel,
    required this.nameColor,
    this.gender,
    this.roleLabel,
    this.isCurrentUser = false,
    this.camOn = false,
    this.trailingIcon,
    this.trailingColor = Colors.white38,
    this.hasRecentChat = false,
    this.isWatchingMe = false,
    this.onSecretMessage,
    this.onDirectMessage,
  });

  final String displayName;
  final int vipLevel;
  final Color nameColor;
  final String? gender;
  final String? roleLabel;
  final bool isCurrentUser;
  final bool camOn;
  final IconData? trailingIcon;
  final Color trailingColor;
  final bool hasRecentChat;
  final bool isWatchingMe;
  final VoidCallback? onSecretMessage;
  final VoidCallback? onDirectMessage;

  IconData? _genderIcon(String? g) {
    if (g == null) return null;
    final lower = g.toLowerCase();
    if (lower == 'male') return Icons.male;
    if (lower == 'female') return Icons.female;
    return Icons.transgender;
  }

  Color _genderColor(String? g) {
    if (g == null) return Colors.white38;
    final lower = g.toLowerCase();
    if (lower == 'male') return const Color(0xFF64B5F6);
    if (lower == 'female') return const Color(0xFFF48FB1);
    return const Color(0xFFCE93D8);
  }

  @override
  Widget build(BuildContext context) {
    final gIcon = _genderIcon(gender);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (gIcon != null) ...[
                Icon(gIcon, size: 11, color: _genderColor(gender)),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: nameColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isWatchingMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.visibility,
                  size: 12,
                  color: Color(0xFFD4AF37),
                ),
              ],
              if (vipLevel > 0) ...[
                const SizedBox(width: 3),
                Text(
                  '💎$vipLevel',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF7777BB)),
                ),
              ],
              if (trailingIcon != null) ...[
                const SizedBox(width: 3),
                Icon(trailingIcon, size: 11, color: trailingColor),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (isCurrentUser)
                const _RosterChip(
                  label: '(You)',
                  icon: Icons.person,
                  color: Color(0xFFD4A853),
                ),
              if (roleLabel != null)
                _RosterChip(
                  label: roleLabel!,
                  icon: Icons.label_outline,
                  color: const Color(0xFFC45E7A),
                ),
              if (camOn)
                const _RosterChip(
                  label: 'Cam On',
                  icon: Icons.videocam,
                  color: Color(0xFF4CAF50),
                ),
              if (hasRecentChat)
                _RosterChip(
                  label: 'Chatting',
                  icon: Icons.chat_bubble_outline,
                  color: VelvetNoir.primary,
                ),
              if (onSecretMessage != null)
                _RosterActionChip(
                  label: 'Secret',
                  icon: Icons.lock_outline,
                  color: const Color(0xFFD4A853),
                  onTap: onSecretMessage!,
                ),
              if (onDirectMessage != null)
                _RosterActionChip(
                  label: 'DM',
                  icon: Icons.mail_outline,
                  color: const Color(0xFFB09080),
                  onTap: onDirectMessage!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RosterChip extends StatelessWidget {
  const _RosterChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelColor = Color.alphaBlend(
      color.withValues(alpha: 0.18),
      Colors.white,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 8,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: labelColor.withValues(alpha: 0.95),
              fontSize: 9.4,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterActionChip extends StatelessWidget {
  const _RosterActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = Color.alphaBlend(
      color.withValues(alpha: 0.2),
      Colors.white,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.52)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 10,
                spreadRadius: 0.2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: labelColor.withValues(alpha: 0.98),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineSecretComposer extends StatelessWidget {
  const _InlineSecretComposer({
    required this.targetDisplayName,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    this.onCancel,
    this.onSend,
  });

  final String targetDisplayName;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final secretTextColor = Theme.of(context).colorScheme.onSurface;
    final secretHintColor = secretTextColor.withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241820), Color(0xFF1A141B)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4A853).withValues(alpha: 0.24),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.lock, size: 12, color: Color(0xFFD4A853)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Secret to $targetDisplayName',
                  style: const TextStyle(
                    color: Color(0xFFE7D7B5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCancel != null)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: isSending ? null : onCancel,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: Colors.white54),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  enabled: !isSending,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: secretTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  cursorColor: const Color(0xFFD4A853),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (isSending || onSend == null) return;
                    onSend!();
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type secret message...',
                    hintStyle: TextStyle(
                      color: secretHintColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Color(0xFFD4A853),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF120E12),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x33D4A853)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x55D4A853)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4A853)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 34,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A853),
                    foregroundColor: const Color(0xFF1A141B),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 13),
                  label: Text(isSending ? '...' : 'Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gift toast data class
// ---------------------------------------------------------------------------

class _GiftToast {
  final String senderId;
  final String senderName;
  final String giftEmoji;
  final String giftName;
  final int coinCost;

  const _GiftToast({
    required this.senderId,
    required this.senderName,
    required this.giftEmoji,
    required this.giftName,
    required this.coinCost,
  });
}

// ---------------------------------------------------------------------------
// Raise-hand button
// ---------------------------------------------------------------------------

/// Compact icon button that lets audience members raise their hand to request
/// the mic.  Shows a filled orange hand when a request is pending.  Tapping
/// while pending cancels the request.
// ignore: unused_element
class _HandRaiseButton extends StatelessWidget {
  const _HandRaiseButton({
    required this.status,
    required this.onRaise,
    required this.onCancel,
  });

  final String? status;
  final Future<void> Function() onRaise;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return IconButton(
      tooltip: isPending ? 'Cancel hand raise' : 'Raise hand to speak',
      icon: Icon(
        isPending ? Icons.front_hand : Icons.front_hand_outlined,
        color: isPending ? const Color(0xFFD4A853) : null,
      ),
      onPressed: isPending ? () => onCancel() : onRaise,
    );
  }
}

// ---------------------------------------------------------------------------
// Host Controls bottom-sheet content — shown when host taps the Controls
// button in the TikTok-style overlay.
// ---------------------------------------------------------------------------

class _HostControlsContent extends ConsumerStatefulWidget {
  const _HostControlsContent({required this.roomId});
  final String roomId;

  @override
  ConsumerState<_HostControlsContent> createState() =>
      _HostControlsContentState();
}

class _HostControlsContentState extends ConsumerState<_HostControlsContent> {
  int _lastPendingMicRequestCount = 0;

  @override
  Widget build(BuildContext context) {
    final roomController = ref.read(
      liveRoomControllerProvider(widget.roomId).notifier,
    );
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final micRequestsAsync = ref.watch(
      roomMicAccessRequestsProvider(widget.roomId),
    );
    final roomDocData = ref
        .watch(roomDocStreamProvider(widget.roomId))
        .valueOrNull;
    final isLocked =
        ref.watch(roomStreamProvider(widget.roomId)).valueOrNull?.isLocked ??
        false;
    final allowChat = roomPolicyAsync.valueOrNull?.allowChat ?? true;
    final allowGifts = roomPolicyAsync.valueOrNull?.allowGifts ?? true;
    final allowMicRequests =
        roomPolicyAsync.valueOrNull?.allowMicRequests ?? true;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Host Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<int>(
                        initialValue:
                            (roomDocData?['slowModeSeconds'] as num?)
                                ?.toInt() ??
                            0,
                        decoration: const InputDecoration(
                          labelText: 'Slow mode',
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Off')),
                          DropdownMenuItem(value: 5, child: Text('5 seconds')),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('10 seconds'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 seconds'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            roomController.toggleSlowMode(val);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lock room'),
                        subtitle: Text(
                          isLocked ? 'New listeners blocked' : 'Room is open',
                        ),
                        value: isLocked,
                        onChanged: (_) => roomController.toggleLockRoom(),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chat'),
                        subtitle: Text(
                          allowChat ? 'Members can message' : 'Chat paused',
                        ),
                        value: allowChat,
                        onChanged: (_) => roomController.toggleAllowChat(),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mic requests'),
                        subtitle: Text(
                          allowMicRequests
                              ? 'Users can request stage access'
                              : 'Requests paused',
                        ),
                        value: allowMicRequests,
                        onChanged: (_) =>
                            roomController.toggleAllowMicRequests(),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gifts'),
                        subtitle: Text(
                          allowGifts
                              ? 'Gift interactions enabled'
                              : 'Gifts paused',
                        ),
                        value: allowGifts,
                        onChanged: (_) => roomController.toggleAllowGifts(),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        initialValue:
                            roomPolicyAsync.valueOrNull?.micLimit ?? 6,
                        decoration: const InputDecoration(
                          labelText: 'Mic seats',
                        ),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('2 seats')),
                          DropdownMenuItem(value: 4, child: Text('4 seats')),
                          DropdownMenuItem(value: 6, child: Text('6 seats')),
                          DropdownMenuItem(value: 8, child: Text('8 seats')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          roomController.setMaxBroadcasters(value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        initialValue:
                            roomPolicyAsync.valueOrNull?.camLimit ?? 6,
                        decoration: const InputDecoration(
                          labelText: 'Camera seats',
                        ),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('2 seats')),
                          DropdownMenuItem(value: 4, child: Text('4 seats')),
                          DropdownMenuItem(value: 6, child: Text('6 seats')),
                          DropdownMenuItem(value: 8, child: Text('8 seats')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          roomController.setCamLimit(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage people',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use the People in room button in the room to manage participants.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mic request queue',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                micRequestsAsync.when(
                  data: (requests) {
                    final pending = requests
                        .where((r) => r.status == 'pending')
                        .toList(growable: false);
                    if (pending.length > _lastPendingMicRequestCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        RoomAudioCues.instance.playHandRaised();
                      });
                    }
                    _lastPendingMicRequestCount = pending.length;
                    if (pending.isEmpty) {
                      return const Text('No pending mic requests.');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pending
                          .map((request) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                  'Mic request from ${request.requesterId}',
                                ),
                                subtitle: Text(
                                  'Approve for stage access • Priority ${request.priority}',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      onPressed: () => roomController
                                          .bumpMicRequest(request.id),
                                      icon: const Icon(Icons.arrow_upward),
                                      tooltip: 'Bump priority',
                                    ),
                                    IconButton(
                                      onPressed: () => roomController
                                          .lowerMicRequest(request.id),
                                      icon: const Icon(Icons.arrow_downward),
                                      tooltip: 'Lower priority',
                                    ),
                                    IconButton(
                                      onPressed: () => ref
                                          .read(
                                            liveRoomControllerProvider(
                                              widget.roomId,
                                            ).notifier,
                                          )
                                          .approveMicRequest(request),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      tooltip: 'Approve',
                                    ),
                                    IconButton(
                                      onPressed: () => ref
                                          .read(
                                            liveRoomControllerProvider(
                                              widget.roomId,
                                            ).notifier,
                                          )
                                          .denyMicRequest(request.id),
                                      icon: const Icon(Icons.cancel_outlined),
                                      tooltip: 'Deny',
                                    ),
                                    IconButton(
                                      onPressed: () => roomController
                                          .expireMicRequest(request.id),
                                      icon: const Icon(
                                        Icons.timer_off_outlined,
                                      ),
                                      tooltip: 'Expire now',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Could not load mic requests: $e'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mic level bar — five animated bars showing live audio energy
// ─────────────────────────────────────────────────────────────────────────────
/// One numbered step row in the "Share PC audio" guide bottom sheet.
class _SystemAudioStep extends StatelessWidget {
  const _SystemAudioStep({required this.number, required this.text, this.icon});

  final String number;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF7C5FFF),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: const Color(0xFF7C5FFF)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(text, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scrolling ticker banner (Paltalk-style room description marquee)
// ---------------------------------------------------------------------------

/// Scrolls [text] continuously from right to left in a 24px strip.
/// Implements [PreferredSizeWidget] so it can be used as [AppBar.bottom].
class _TickerBanner extends StatefulWidget implements PreferredSizeWidget {
  const _TickerBanner({required this.text});

  final String text;

  @override
  Size get preferredSize => const Size.fromHeight(24);

  @override
  State<_TickerBanner> createState() => _TickerBannerState();
}

class _TickerBannerState extends State<_TickerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Roughly 0.2s per character, clamped between 12 and 60 seconds.
    final secs = (widget.text.length * 0.2).clamp(12.0, 60.0).round();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: secs),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: const Color(0xFF14172B),
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final containerWidth = constraints.maxWidth;
          // Approximate text width: ~7 px per char at font-size 11.
          final textWidth = widget.text.length * 7.0;
          final totalTravel = containerWidth + textWidth;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              final offset = containerWidth - _ctrl.value * totalTravel;
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.text,
              style: const TextStyle(color: Color(0xFFB09080), fontSize: 11),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner Admin Menu Bar
// A compact horizontal toolbar shown exclusively to the room owner/host.
// Provides quick-access buttons that open the control panel on a specific tab
// or trigger owner-only actions (lock toggle, end room).
// ─────────────────────────────────────────────────────────────────────────────

class _RoomOwnerAdminBar extends StatelessWidget {
  const _RoomOwnerAdminBar({
    required this.roomId,
    required this.currentUserId,
    required this.isLocked,
    required this.micVolume,
    required this.speakerVolume,
    required this.onToggleLock,
    required this.onEndRoom,
    required this.onTheme,
    this.onMicVolumeChanged,
    this.onSpeakerVolumeChanged,
  });

  final String roomId;
  final String currentUserId;
  final bool isLocked;
  final double micVolume;
  final double speakerVolume;
  final VoidCallback onToggleLock;
  final VoidCallback onEndRoom;
  final VoidCallback onTheme;
  final ValueChanged<double>? onMicVolumeChanged;
  final ValueChanged<double>? onSpeakerVolumeChanged;

  void _openPanel(BuildContext context, int tab) {
    RoomHostControlPanel.show(
      context,
      roomId: roomId,
      currentUserId: currentUserId,
      isOwner: true,
      initialTabIndex: tab,
      micVolume: micVolume,
      speakerVolume: speakerVolume,
      onMicVolumeChanged: onMicVolumeChanged,
      onSpeakerVolumeChanged: onSpeakerVolumeChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xCC10131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x50D4A853)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AdminBtn(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () => _openPanel(context, 0),
          ),
          _AdminBtn(
            icon: Icons.palette_rounded,
            label: 'Theme',
            onTap: onTheme,
          ),
          _AdminBtn(
            icon: isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            label: isLocked ? 'Locked' : 'Lock',
            color: isLocked ? const Color(0xFFD4A853) : null,
            onTap: onToggleLock,
          ),
          _AdminBtn(
            icon: Icons.mic_rounded,
            label: 'Stage',
            onTap: () => _openPanel(context, 1),
          ),
          _AdminBtn(
            icon: Icons.headset_rounded,
            label: 'Audio',
            onTap: () => _openPanel(context, 2),
          ),
          _AdminBtn(
            icon: Icons.people_alt_rounded,
            label: 'People',
            onTap: () => _openPanel(context, 3),
          ),
          _AdminBtn(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Mods',
            onTap: () => _openPanel(context, 4),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0x40D4A853),
          ),
          _AdminBtn(
            icon: Icons.stop_circle_rounded,
            label: 'End',
            color: const Color(0xFFFF6E84),
            onTap: onEndRoom,
          ),
        ],
      ),
    );
  }
}

class _AdminBtn extends StatelessWidget {
  const _AdminBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoomBackground
//
// Renders the active room theme as a full-screen background layer.
// When the host updates the theme the parent's roomData changes via a
// Firestore stream, causing a rebuild with the new theme instantly.
//
// Rendering priority:
//   1. Custom backgroundUrl from host  (network image)
//   2. vibePreset gradient            (built-in palette)
//   3. Default dark surface           (fallback)
// A semi-transparent overlay is always applied on top to keep UI readable.
// ─────────────────────────────────────────────────────────────────────────────

class _RoomBackground extends StatelessWidget {
  const _RoomBackground({required this.theme});

  final RoomTheme theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: base background
        if (theme.hasBackground)
          Image.network(
            theme.backgroundUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _presetGradient(theme.vibePreset),
          )
        else
          _presetGradient(theme.vibePreset),

        // Layer 2: readability overlay (always present)
        Container(color: const Color(0xD90D0A0C)),
      ],
    );
  }

  Widget _presetGradient(RoomVibePreset preset) {
    final colors = switch (preset) {
      RoomVibePreset.club => [const Color(0xFF0A0020), const Color(0xFF3D0070)],
      RoomVibePreset.lounge => [
        const Color(0xFF1A0A00),
        const Color(0xFF3D200A),
      ],
      RoomVibePreset.neon => [const Color(0xFF001A2E), const Color(0xFF00204A)],
      RoomVibePreset.hype => [const Color(0xFF1A0000), const Color(0xFF5C0000)],
      RoomVibePreset.space => [
        const Color(0xFF000015),
        const Color(0xFF060618),
      ],
      RoomVibePreset.ocean => [
        const Color(0xFF001A2E),
        const Color(0xFF003355),
      ],
      _ => [const Color(0xFF0D0A0C), const Color(0xFF1A1520)],
    };
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}
