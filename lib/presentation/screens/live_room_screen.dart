import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
import '../../features/room/providers/room_firestore_provider.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/providers/presence_provider.dart';
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
import '../../features/room/providers/host_controls_provider.dart';
import '../../features/feed/providers/host_controls_providers.dart';
import '../../features/room/providers/room_policy_provider.dart';
import '../../features/room/providers/room_gift_provider.dart';
import '../../features/room/providers/user_cam_permissions_provider.dart';
import '../../features/room/providers/cam_view_request_provider.dart';
import '../../features/room/providers/room_slot_provider.dart';
import '../../features/room/room_permissions.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/agora_service.dart';
import '../../services/rtc_room_service.dart';
import '../../services/webrtc_room_service_shim.dart';
import '../../services/follow_service.dart';
import '../../services/moderation_service.dart';
import '../../services/friend_service.dart';
import '../../services/notification_service.dart';
import '../../services/presence_repository.dart';
import '../../services/room_audio_cues.dart';
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

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  late TextEditingController messageController;
  late TextEditingController _secretMessageController;
  late ScrollController scrollController;
  FirebaseFirestore? _firestore;
  String? _joinedUserId;
  DateTime? lastMessageTime;
  int slowModeSeconds = 0;
  bool isSending = false;
  String cooldownMessage = '';
  bool _isJoiningRoom = false;
  String? _roomJoinError;
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
  bool _preWarmDone = false;

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
  late final LiveRoomMediaController _liveRoomMediaNotifier;
  late final ProviderSubscription<LiveRoomMediaState> _mediaStateSubscription;
  LiveRoomMediaState _latestMediaState = const LiveRoomMediaState();
  final Set<String> _shownBuzzIds = {};
  final Set<String> _shownCamViewRequestIds = {};
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
  int _maxBroadcasters = 6;
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

  bool _looksLikeAgoraAppId(String value) {
    final trimmed = value.trim();
    if (trimmed.length != 32) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(trimmed);
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
  Set<int> get _requestedHighQualityRemoteUids =>
      _mediaState.requestedHighQualityRemoteUids;
  Set<int> get _requestedLowQualityRemoteUids =>
      _mediaState.requestedLowQualityRemoteUids;
  int get _localViewEpoch => _mediaState.localViewEpoch;

  @override
  void initState() {
    super.initState();
    _liveRoomMediaNotifier =
        ref.read(liveRoomMediaControllerProvider(widget.roomId).notifier);
    _mediaStateSubscription = ref.listenManual<LiveRoomMediaState>(
      liveRoomMediaControllerProvider(widget.roomId),
      (_, next) {
        _latestMediaState = next;
      },
      fireImmediately: true,
    );
    messageController = TextEditingController();
    _secretMessageController = TextEditingController();
    scrollController = ScrollController();

    final user = ref.read(userProvider);
    if (user != null) {
      _firestore = ref.read(roomFirestoreProvider);
      _joinedUserId = user.id;
      // Pre-seed own display name so local tile shows username immediately.
      if (user.username.trim().isNotEmpty) {
        _senderDisplayNameById[user.id] = user.username.trim();
      }
      _senderAvatarUrlById[user.id] =
          (user.avatarUrl?.isNotEmpty == true) ? user.avatarUrl : null;
      _joinRoom(user.id);
      if (kIsWeb) {
        // WebRTC path: no Agora WASM pre-warm needed.
        // Camera init is instant (browser native WebRTC).
      } else {
        // Pre-warm the Agora SDK in the background (mobile only) so WASM cold-start
        // completes before the user taps "Turn on cam".
        _preWarmAgora(user.id);
      }
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
        incomingBuzzStreamProvider((roomId: widget.roomId, currentUserId: user.id)),
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
              final senderName = _senderDisplayNameById[buzz.fromUserId] ?? buzz.fromUserId;
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
        pendingCamViewRequestsProvider(
            (roomId: widget.roomId, targetId: user.id)),
        (_, next) {
          next.whenData((requests) {
            for (final request in requests) {
              if (_shownCamViewRequestIds.contains(request.id)) continue;
              _shownCamViewRequestIds.add(request.id);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _handleIncomingCamViewRequest(request);
              });
            }
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
  static Future<List<Map<String, dynamic>>> _fetchIceServers() async {
    const fallback = [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ];
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('generateTurnCredentials');
      final result = await callable.call<Map<String, dynamic>>({});
      final raw = result.data['iceServers'];
      if (raw is List && raw.isNotEmpty) {
        return raw
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
      return fallback;
    } catch (_) {
      // Cloud Function unavailable (offline / test env) — STUN only.
      return fallback;
    }
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
    final currentRoomPresence = _roomPresenceForUser(presenceList, currentUserId);
    final isJoined = _joinedUserId == currentUserId;
    final globalPresenceMismatch = globalPresence != null &&
        (((globalPresence.isOnline ?? false) == false) ||
            globalPresence.inRoom != widget.roomId);
    final roomPresenceMismatch =
        currentRoomPresence != null && currentRoomPresence.userStatus == 'offline';
    final cameraMismatch = isJoined && _isVideoEnabled && currentParticipant?.camOn != true;

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
      presenceMismatch: isJoined && (globalPresenceMismatch || roomPresenceMismatch),
    );
  }

  void _logLiveRoom(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
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
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateAgoraToken',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': channelName,
        'rtcUid': rtcUid,
      });
      final data = Map<String, dynamic>.from(result.data);
      final token = _asString(data['token']);
      final serverAppId = _asString(data['appId']);
      if (token.isEmpty) {
        throw const AgoraServiceException(
          code: 'agora-token-missing',
          message: 'Live media token is missing from backend response.',
        );
      }

      final localAppId = AgoraConstants.appId.trim();
      final resolvedAppId = serverAppId.isNotEmpty ? serverAppId : localAppId;
      if (!_looksLikeAgoraAppId(resolvedAppId)) {
        throw const AgoraServiceException(
          code: 'agora-appid-invalid',
          message: 'AGORA_APP_ID is missing or invalid (expected 32 chars).',
        );
      }

      return (token: token, appId: resolvedAppId);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        throw AgoraServiceException(
          code: 'agora-backend-misconfigured',
          message:
              'Live media backend is not configured. Please set AGORA_APP_ID and AGORA_APP_CERTIFICATE in Cloud Functions.',
          cause: e,
        );
      }
      if (e.code == 'resource-exhausted') {
        throw AgoraServiceException(
          code: 'agora-rate-limited',
          message:
              'Too many live-media attempts. Please wait a moment and retry.',
          cause: e,
        );
      }
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        throw AgoraServiceException(
          code: 'permission-denied',
          message:
              'Your session is not authorized for live media. Please sign in again.',
          cause: e,
        );
      }
      rethrow;
    }
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
      _logLiveRoom(
        'connect:start user=$userId room=${widget.roomId}',
      );
      final rtcUid = _buildRtcUid(userId);

      if (kIsWeb) {
        // ── WebRTC path (web only) ────────────────────────────────────────
        // Browser-native WebRTC. No WASM to download → initialises instantly.
        // Firestore is used for signaling (offer/answer/ICE).
        _logLiveRoom('connect:webrtc_path uid=$rtcUid');
        if (mounted) {
          _mediaController.setCameraStatus('Connecting to live room…');
        }
        final iceServers = await _fetchIceServers();
        final service = WebRtcRoomService(
          firestore: _firestore!,
          localUserId: userId,
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
        final credentials = await _runWithWatchdog<({String token, String appId})>(
          phase: 'token',
          timeout: const Duration(seconds: 12),
          timeoutCode: 'agora-token-missing',
          timeoutMessage: 'Timed out fetching live media token.',
          action: () => _fetchAgoraToken(
            channelName: widget.roomId,
            rtcUid: rtcUid,
          ),
        );
        _logLiveRoom('connect:token_ok uid=$rtcUid');

        const maxConnectAttempts = 2;
        for (var attempt = 1; attempt <= maxConnectAttempts; attempt++) {
          final service = AgoraService();
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
      _logLiveRoom(
        'connect:failed',
        error: e,
        stackTrace: stackTrace,
      );
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
    if (service == null || !_isCallReady || _isMicActionInFlight) return;
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
      if (!next) {
        await service.ensureDeviceAccess(video: false, audio: true);
        await service.setBroadcaster(true);
        await service.publishLocalAudioStream(true);
      }
      await service.mute(next);
      if (mounted) {
        _mediaController.finishMicAction(isMuted: next);
      }
      _syncMediaUiFromService();
      // Mirror mic state to RTDB so onDisconnect clears it automatically.
      // next=true means muted, so mic_on = !next.
      final micUserId = _joinedUserId;
      if (micUserId != null) {
        unawaited(
          ref.read(rtdbPresenceServiceProvider).setMicOn(micUserId, micOn: !next),
        );
      }
      // Start or stop the timer that refreshes the mic level bar.
      if (!next) {
        _startMicLevelPolling();
      } else {
        _stopMicLevelPolling();
      }
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
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                text: 'Check "Share system audio" (the checkbox near the bottom of the picker).',
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
    if (service == null || !_isCallReady || _isSystemAudioActionInFlight) return;

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
          _mediaController.setCameraStatus('Requesting browser camera access...');
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
            ref.read(rtdbPresenceServiceProvider).setCamOn(camUserId, camOn: next),
          );
        }
        if (next) {
          Future<void>.delayed(const Duration(milliseconds: 450), () {
            if (mounted) setState(() {});
          });
          final myName = _senderDisplayNameById[_joinedUserId ?? ''] ?? (_joinedUserId ?? '');
          if (myName.isNotEmpty) _sendSystemEvent('$myName turned on their camera 📷');
        } else {
          final myName = _senderDisplayNameById[_joinedUserId ?? ''] ?? (_joinedUserId ?? '');
          if (myName.isNotEmpty) _sendSystemEvent('$myName turned off their camera');
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
      _logLiveRoom(
        'toggle_video:failed',
        error: e,
        stackTrace: st,
      );
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
        _videoToggleCooldownUntil =
            DateTime.now().add(const Duration(milliseconds: 900));
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
                const Icon(Icons.videocam_off, size: 40, color: Color(0xFFB09080)),
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
                const Icon(Icons.lock_outline, size: 24, color: Color(0xFFB09080)),
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
                        horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Request Access',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFFC45E7A)),
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
    final targetName =
        _senderDisplayNameById[targetUserId] ?? targetUserId;
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
      await ref.read(camViewRequestControllerProvider).sendRequest(
            roomId: widget.roomId,
            requesterId: myUserId,
            targetId: targetUserId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send request')),
        );
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
            (currentUserId != null && allowedViewers.contains(currentUserId)));

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
        _senderDisplayNameById[request.requesterId] ?? request.requesterId;
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
    if (approved == true) {
      await ref
          .read(userCamPermissionsControllerProvider)
          .addAllowedViewer(userId: myUserId, viewerId: request.requesterId);
    }
    await ref.read(camViewRequestControllerProvider).respondToRequest(
          roomId: widget.roomId,
          requestId: request.id,
          approved: approved == true,
        );
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
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final friends = await FriendService(firestore: firestore).getFriends(userId);
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
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: selected.isEmpty ? null : () => Navigator.of(sheetCtx).pop(true),
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
                            title: Text(friend.username.trim().isEmpty ? friend.id : friend.username),
                            secondary: CircleAvatar(
                              child: Text(
                                (friend.username.trim().isEmpty ? '?' : friend.username.trim()[0]).toUpperCase(),
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
      await NotificationService(firestore: firestore).sendRoomInviteToFriends(
        friendIds: selected.toList(),
        inviterId: userId,
        inviterName: username.trim().isEmpty ? 'Someone' : username.trim(),
        roomId: widget.roomId,
        roomName: roomName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invited ${selected.length} friend${selected.length == 1 ? '' : 's'}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send invites: $e')),
        );
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
    final firestore = _firestore;
    if (firestore == null) return;

    final friends = await FriendService(firestore: firestore)
        .getFriends(currentUserId);
    if (!mounted) return;

    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have no friends yet.')),
      );
      return;
    }

    final presenceByUserId = await ref
        .read(presenceRepositoryProvider)
        .getUsersPresence(friends.map((friend) => friend.id).toList(growable: false));

    final online = <({String id, String username, String? avatarUrl, String? currentRoomId})>[];
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
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                    final inOtherRoom = f.currentRoomId != null &&
                        f.currentRoomId != roomId;
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
                          ? const Text('In this room',
                              style: TextStyle(color: Color(0xFFC45E7A)))
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
    await ref.read(liveRoomControllerProvider(widget.roomId).notifier).pausePresence();
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
        'connection_lost: reconnect attempt=$_reconnectAttempts delay=${delaySecs}s');

    // Snapshot media state before _disconnectCall() resets it to defaults.
    final hadCameraSlot = _claimedSlotId != null;
    final previousRole = _appliedMediaRole;
    final wasMicMuted = _isMicMuted;

    _logLiveRoom('connection_lost: reconnecting hadSlot=$hadCameraSlot micMuted=$wasMicMuted');
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
              await service.enableVideo(true, publishMicrophoneTrack: !wasMicMuted);
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

  Future<void> _disconnectCall() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopMicLevelPolling();
    final service = _agoraService;
    if (service is WebRtcRoomService) service.onSystemAudioStopped = null;
    _agoraService = null;
    _mediaController.resetDisconnected();
    if (service != null) {
      await service.dispose();
    }
  }

  Future<void> _applyRoleMediaState(String role) async {
    final service = _agoraService;
    if (service == null ||
        !_isCallReady ||
        _appliedMediaRole == role ||
        _isMicActionInFlight ||
        _isVideoActionInFlight) {
      return;
    }

    try {
      // When promoted to stage or cohost: ensure we are in broadcaster mode
      // and publish audio. Skip ensureDeviceAccess when the camera is already
      // on — the stream already holds an audio track and re-acquiring the mic
      // via a separate getUserMedia call would disrupt the existing track.
      if (role == 'stage' || role == 'cohost') {
        if (!service.isBroadcaster) {
          // No stream yet — need device access before going broadcaster.
          await service.ensureDeviceAccess(video: false, audio: true);
          await service.setBroadcaster(true);
        }
        await service.publishLocalAudioStream(true);
        if (mounted) {
          _mediaController.setMicMuted(false);
          if (role == 'cohost') {
            _showSnackBar('You are now a co-host — your mic is live!');
          }
        }
      }
      // When demoted back to audience or member: stop publishing and downgrade
      // Agora client role so this user no longer occupies a broadcaster slot.
      // Skip if the user has an active camera slot (already broadcaster).
      if ((role == 'audience' || role == 'member') &&
          service.isBroadcaster &&
          _claimedSlotId == null) {
        await service.setBroadcaster(false);
        if (mounted) _mediaController.setMicMuted(true);
        // If demoted from stage the user was displaced by someone grabbing the
        // mic — show a brief notice so they are not confused.
        if (mounted && _appliedMediaRole == 'stage') {
          _showSnackBar('Your mic was taken — someone else grabbed it.');
        }
      }
      await service.mute(_isMicMuted);
      // Do NOT call enableVideo again if the camera is already running.
      // The track is already in broadcaster state; a duplicate call on web
      // stops and restarts the preview, causing a visible camera-off flicker.
      if (_isVideoEnabled && _claimedSlotId == null) {
        await service.enableVideo(true, publishMicrophoneTrack: !_isMicMuted);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(_mapMediaError(e, canBroadcast: true));
      }
      // Still update _appliedMediaRole so we don't loop infinitely.
      if (mounted) _mediaController.setAppliedMediaRole(role);
      return;
    }

    if (!mounted) {
      return;
    }

    _mediaController.setAppliedMediaRole(role);
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
    _typingTimer?.cancel();
    final userId = _joinedUserId;
    if (userId == null || userId.isEmpty) return;
    if (messageController.text.trim().isEmpty) {
      _clearTypingStatus().ignore();
      return;
    }
    final now = DateTime.now();
    final shouldWrite = !_typingStatusActive ||
        _lastTypingWriteAt == null ||
        now.difference(_lastTypingWriteAt!) >= _kTypingWriteThrottle;
    if (shouldWrite) {
      _typingStatusActive = true;
      _lastTypingWriteAt = now;
      ref
          .read(liveRoomControllerProvider(widget.roomId).notifier)
          .setTyping(userId: userId, isTyping: true)
          .ignore();
    }
    _typingTimer = Timer(_kTypingIdleTimeout, _clearTypingStatus);
  }

  Future<void> _clearTypingStatus() async {
    _typingTimer?.cancel();
    _typingTimer = null;
    _typingStatusActive = false;
    final userId = _joinedUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      await ref
          .read(liveRoomControllerProvider(widget.roomId).notifier)
          .setTyping(userId: userId, isTyping: false);
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
    if (senderId == currentUserId) {
      final trimmed = currentUsername.trim();
      return trimmed.isEmpty ? 'You' : trimmed;
    }
    return _senderDisplayNameById[senderId] ?? senderId;
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
        ...userIds.map((id) => id.trim()).where((id) => id.isNotEmpty && id != currentUserId),
    };
    final missingIds = senderIds
        .where(
          (id) =>
              !_senderDisplayNameById.containsKey(id) &&
              !_senderLookupInFlight.contains(id),
        )
        .toList(growable: false);
    if (missingIds.isEmpty) {
      return;
    }

    _senderLookupInFlight.addAll(missingIds);
    final FirebaseFirestore firestore =
        _firestore ?? ref.read(roomFirestoreProvider);
    final resolved = <String, String>{};
    final resolvedVip = <String, int>{};
    final resolvedAvatar = <String, String?>{};
    final resolvedGender = <String, String?>{};

    try {
      for (var i = 0; i < missingIds.length; i += 10) {
        final upperBound = (i + 10 > missingIds.length)
            ? missingIds.length
            : i + 10;
        final batchIds = missingIds.sublist(i, upperBound);
        final snapshot = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final username = _asString(data['username']);
          resolved[doc.id] = username.isEmpty ? doc.id : username;
          final vip = data['vipLevel'];
          resolvedVip[doc.id] = vip is int
              ? vip
              : (vip is num ? vip.toInt() : 0);
          final avatar = data['avatarUrl'];
          resolvedAvatar[doc.id] =
              (avatar is String && avatar.isNotEmpty) ? avatar : null;
          final gender = data['gender'];
          resolvedGender[doc.id] =
              (gender is String && gender.isNotEmpty) ? gender : null;
        }
      }

      // Prevent repeated lookups for missing docs by falling back to the id.
      for (final id in missingIds) {
        resolved.putIfAbsent(id, () => id);
        resolvedVip.putIfAbsent(id, () => 0);
        resolvedAvatar.putIfAbsent(id, () => null);
        resolvedGender.putIfAbsent(id, () => null);
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

  Future<void> _handleForcedRoomExit(String message) async {
    if (_isHandlingParticipantRemoval) {
      return;
    }

    _isHandlingParticipantRemoval = true;
    await _disconnectCall();

    // Release any camera slot before nulling _joinedUserId, which _leaveRoom
    // uses to find the slot owner. Forced exits don't call _leaveRoom so we
    // must clean up the slot here explicitly.
    final userId = _joinedUserId;
    if (userId != null && _claimedSlotId != null) {
      try {
        final firestore = _firestore;
        if (firestore != null) {
          final slotService = ref.read(roomSlotServiceProvider);
          await slotService.releaseSlot(widget.roomId, userId);
        }
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
    required HostControls hostControls,
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

        final actions = <RoomActionItem>[
          RoomActionItem(
            label: 'View profile',
            icon: Icons.person_outline,
            onTap: () {
              Navigator.of(sheetContext).pop();
              UserProfilePopup.show(context, ref, userId: target.userId);
            },
          ),
          if (!isSelf && (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux))
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
                        user2Name: presentationByUserId[target.userId]?.displayName ?? target.userId,
                        user2AvatarUrl: presentationByUserId[target.userId]?.avatarUrl,
                      );
                  if (!mounted) return;
                  final peerName = presentationByUserId[target.userId]?.displayName ?? target.userId;
                  final peerAvatar = presentationByUserId[target.userId]?.avatarUrl;
                  if (kIsWeb) {
                    WebPopoutService().openWhisperWindow(target.userId, peerName);
                  } else if (defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.linux) {
                    await DesktopWindowService().openWhisperWindow(target.userId, peerName);
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
                    await hostControls.unmuteUser(widget.roomId, target.userId);
                    _showSnackBar('${target.userId} can chat again.');
                  } else {
                    await hostControls.muteUser(widget.roomId, target.userId);
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
                    await hostControls.demoteToAudience(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} is now audience.');
                  } else {
                    await hostControls.promoteToModerator(
                      widget.roomId,
                      target.userId,
                    );
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
                    await hostControls.demoteToAudience(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} moved to the audience.');
                  } else {
                    await hostControls.promoteToCohost(
                      widget.roomId,
                      target.userId,
                    );
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
                    await hostControls.forceReleaseMic(
                      widget.roomId,
                      target.userId,
                    );
                    _showSnackBar('${target.userId} removed from mic.');
                  } else {
                    await hostControls.inviteToMic(
                      widget.roomId,
                      target.userId,
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
                  _showSnackBar('${presentationByUserId[target.userId]?.displayName ?? target.userId} is now spotlighted!');
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
                  await hostControls.transferHost(
                    roomId: widget.roomId,
                    fromUserId: currentUserId,
                    toUserId: target.userId,
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
                    await hostControls.unbanUser(widget.roomId, target.userId);
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
                    await hostControls.banUser(widget.roomId, target.userId);
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
                  await hostControls.removeUser(widget.roomId, target.userId);
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
    required HostControls hostControls,
    required Map<String, RoomUserPresentation> presentationByUserId,
    required List<RoomPresenceModel> presenceList,
  }) async {
    // Build userId → isOnline map with 60-second heartbeat staleness window.
    final onlineMap = <String, bool>{
      for (final p in presenceList)
        if (p.isOnline &&
            (p.lastHeartbeatAt == null ||
                DateTime.now()
                        .difference(p.lastHeartbeatAt!)
                        .inSeconds <
              60))
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
                hostControls: hostControls,
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
    final firestore = _firestore ?? ref.read(roomFirestoreProvider);
    final participantIds = participants
        .map((participant) => participant.userId.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (firestore == null || participantIds.isEmpty) {
      return const <String, RoomUserPresentation>{};
    }

    final presentationByUserId = <String, RoomUserPresentation>{};
    for (var i = 0; i < participantIds.length; i += 10) {
      final upperBound = (i + 10 > participantIds.length)
          ? participantIds.length
          : i + 10;
      final batchIds = participantIds.sublist(i, upperBound);
      final userDocs = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      for (final userDoc in userDocs.docs) {
        final data = userDoc.data();
        final username = _asString(data['username']);
        final avatarUrl = _asString(data['avatarUrl']);
        presentationByUserId[userDoc.id] = RoomUserPresentation(
          displayName: username.isEmpty ? userDoc.id : username,
          avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
        );
      }
    }

    presentationByUserId[currentUserId] = RoomUserPresentation(
      displayName: currentUsername.trim().isEmpty
          ? currentUserId
          : currentUsername.trim(),
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
    required HostControls hostControls,
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
      hostControls: hostControls,
      presentationByUserId: presentationByUserId,
      presenceList: presenceList,
    );
  }

  void _showSetStatusDialog(BuildContext ctx, {required String roomId, required String userId}) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241820),
          title: const Text('Set Status', style: TextStyle(color: Colors.white, fontSize: 16)),
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
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFB09080))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(liveRoomControllerProvider(roomId).notifier).setCustomStatus(
                      userId: userId,
                      status: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
                    );
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFFD4A853))),
            ),
          ],
        );
      },
    );
  }

  /// Posts a system event message (join/leave/cam-on/off) to the room chat.
  void _sendSystemEvent(String content) {
    ref
        .read(liveRoomControllerProvider(widget.roomId).notifier)
        .postSystemEvent(content)
        .ignore();
  }

  Future<void> _joinRoom(String userId) async {
    if (_isJoiningRoom) return;

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
      final joinResult = await ref
          .read(liveRoomControllerProvider(widget.roomId).notifier)
          .joinRoom(userId);
      _excludedUserIds = joinResult.excludedUserIds;
      if (!joinResult.isSuccess) {
        AppTelemetry.updateRoomState(
          roomId: widget.roomId,
          joinedUserId: null,
          roomPhase: 'error',
          roomError:
              joinResult.errorMessage ?? 'Could not join room. Please try again.',
        );
        if (mounted) {
          setState(() => _roomJoinError =
              joinResult.errorMessage ?? 'Could not join room. Please try again.');
        }
        _joinedUserId = null;
        _exitRoom();
        return;
      }

      _joinedUserId = userId;
      AppTelemetry.updateRoomState(
        roomId: widget.roomId,
        joinedUserId: userId,
        roomPhase: 'joined',
        roomError: null,
      );

      // Connect the media service automatically on both platforms.
      // On web this uses WebRTC which is instant (no WASM download).
      // On native this initialises the Agora SDK.
      await _connectCall(userId);

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

  /// Shows a confirmation dialog and ends the room if confirmed.
  Future<void> _confirmAndEndRoom(HostControls hostControls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Room?'),
        content:
            const Text('This will close the room for all participants. Continue?'),
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
      await hostControls.endRoom(widget.roomId);
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
      await ref.read(liveRoomControllerProvider(widget.roomId).notifier).leaveRoom();
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
    required UserCamPermissionsController controller,
  }) async {
    // Hydrate display names for all members so the sheet shows usernames.
    final missingIds = members
        .map((m) => m.userId)
        .where((id) => id != currentUserId && !_senderDisplayNameById.containsKey(id))
        .toList(growable: false);
    if (missingIds.isNotEmpty) {
      final FirebaseFirestore firestore =
          _firestore ?? ref.read(roomFirestoreProvider);
      final resolved = <String, String>{};
      try {
        for (var i = 0; i < missingIds.length; i += 10) {
          final batch = missingIds.sublist(i, (i + 10).clamp(0, missingIds.length));
          final snap = await firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (final doc in snap.docs) {
            final username = _asString(doc.data()['username']);
            resolved[doc.id] = username.isEmpty ? doc.id : username;
          }
        }
        for (final id in missingIds) {
          resolved.putIfAbsent(id, () => id);
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
                            final displayName = _senderDisplayNameById[member.userId] ?? member.userId;
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
                                await controller.setAllowedViewers(
                                  userId: currentUserId,
                                  allowedViewers: selected.toList(
                                    growable: false,
                                  ),
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
    unawaited(_disconnectCall());
    unawaited(_leaveRoom());
    AppTelemetry.clearRoomState();
    messageController.dispose();
    _secretMessageController.dispose();
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
    if (_joinedUserId != user.id && !_isJoiningRoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _firestore = ref.read(roomFirestoreProvider);
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
    final micRequestsAsync = ref.watch(
      roomMicAccessRequestsProvider(widget.roomId),
    );
    final hostControls = ref.read(hostControlsProvider);
    final micAccessController = ref.read(micAccessControllerProvider);
    final walletAsync = ref.watch(walletDetailsProvider);
    final topGifters = ref.watch(topGiftersProvider(widget.roomId));

    // Authoritative host check from the room doc — resolves before the
    // participant stream so broadcaster controls are NEVER gated on whether
    // the participant doc has been written yet.
    final roomDocData = ref.watch(roomDocStreamProvider(widget.roomId)).valueOrNull;
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
        // ignore: unused_local_variable -- kept for potential future use
        final micRequestStatus = myMicRequestAsync.valueOrNull?.status;
        final firestore = ref.watch(roomFirestoreProvider);
        // Skip role-media sync when the user has an active camera slot.
        // They are already in broadcaster state; re-applying would call
        // enableVideo() a second time and disrupt the live camera track.
        // Deduplicate: only queue one postFrameCallback at a time to prevent
        // multiple concurrent _applyRoleMediaState calls from rapid rebuilds.
        // NOTE: _claimedSlotId guard was removed — _applyRoleMediaState itself
        // guards enableVideo internally, so running it while camera is on is
        // safe and necessary (e.g. user grabs mic while camera is active).
        if (_isCallReady && _appliedMediaRole != role &&
            !_roleMediaStatePending) {
          _roleMediaStatePending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _roleMediaStatePending = false;
            _applyRoleMediaState(role);
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
                    .read(micAccessControllerProvider)
                    .releaseMic(roomId: widget.roomId, userId: user.id)
                    .then((_) {
                  if (mounted) _showSnackBar('Your mic time is up.');
                }).catchError((_) {});
              });
            }
          }
        }
        return StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('rooms').doc(widget.roomId).snapshots(),
          builder: (context, roomSnap) {
            final roomData = roomSnap.data?.data() as Map<String, dynamic>?;
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
            // Room-ended detection: when the host closes the room (isLive=false),
            // eject every participant so their camera slots are released and the
            // UI doesn't stay on a dead room. Only fire once the user has already
            // joined (_hasTrackedRoomJoin) to avoid false-ejecting during initial
            // Firestore CDC latency before isLive has been written.
            if (roomSnap.hasData &&
                roomData != null &&
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
            if (participant == null &&
                _hasTrackedRoomJoin &&
                !_isJoiningRoom &&
                _joinedUserId == user.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleForcedRoomExit('You were removed from this room.');
              });
              return const AppPageScaffold(
                safeArea: false,
                maxContentWidth: double.infinity,
                body: AppEmptyView(
                  title: 'You were removed from this room',
                  icon: Icons.exit_to_app_outlined,
                ),
              );
            }
            if (_roomJoinError != null && _joinedUserId == null) {
              return AppPageScaffold(
                safeArea: false,
                maxContentWidth: double.infinity,
                body: AppErrorView(
                  error: _roomJoinError!,
                  fallbackContext: 'join the live room',
                ),
              );
            }
            final sendMessage = ref.read(sendMessageProvider(widget.roomId));
            final participantsInRoom =
                participantsAsync.valueOrNull ?? const [];
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
            final allowChat = roomPolicyAsync.valueOrNull?.allowChat ?? true;
            if (isLocked && !isHost && !isCohost && !isModerator) {
              return const AppPageScaffold(
                safeArea: false,
                maxContentWidth: double.infinity,
                body: AppEmptyView(
                  title: 'Room is locked',
                  message: 'Only approved speakers and moderators can enter right now.',
                  icon: Icons.lock_outline,
                ),
              );
            }
            final roomName = _asString(roomData?['name'], fallback: 'Live Room');
            final roomDescription = _asString(roomData?['description']);
            final spotlightUserId = _asString(roomData?['spotlightUserId']);
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
                const Map<String, int> slotTab = {
                  'cams': 0,
                  'chat': 1,
                  'users': 2,
                };
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
                    onToggleMic: _toggleMic,
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
                      final camController = ref.read(
                        userCamPermissionsControllerProvider,
                      );
                      final allowedViewers = ref
                              .read(userCamAllowedViewersProvider(user.id))
                              .valueOrNull ??
                          const <String>[];
                      _openManageCamViewersSheet(
                        members: participantsInRoom,
                        currentUserId: user.id,
                        currentAllowedViewers: allowedViewers,
                        controller: camController,
                      );
                    },
                    onToggleSystemAudio: _toggleSystemAudio,
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
                      currentUsername: user.username,
                      currentAvatarUrl: user.avatarUrl,
                      hostId: hostId,
                      isHost: isHost,
                      isModerator: isModerator,
                      hostControls: hostControls,
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
                  ),
                ],
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
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
                              final slotCount =
                                  rawMaxBc is num ? rawMaxBc.toInt() : 6;
                              final remoteUserIds = _agoraService!.remoteUids
                                  .map((uid) => _userIdForRtcUid(
                                        uid,
                                        participantsInRoom,
                                      ))
                                  .whereType<String>()
                                  .toList();
                              if (remoteUserIds.isNotEmpty) {
                                unawaited(_hydrateSenderDisplayNames(
                                  userIds: remoteUserIds,
                                  currentUserId: user.id,
                                ));
                              }
                              final presenceMap = <String, bool>{
                                for (final p in presenceAsync.valueOrNull ??
                                    const <RoomPresenceModel>[])
                                  if (p.isOnline &&
                                      (p.lastHeartbeatAt == null ||
                                          DateTime.now()
                                                  .difference(
                                                      p.lastHeartbeatAt!)
                                                  .inSeconds <
                                          60))
                                    p.userId: true,
                              };
                              final floatingIds = ref
                                  .watch(floatingCamWindowsProvider)
                                  .map((w) => w.id)
                                  .toSet();
                              final localIsFloating = floatingIds.contains('${user.id}_local');
                              final remoteTiles = _agoraService!.remoteUids
                                  .where((remoteUid) {
                                    // Hide from grid if already popped out.
                                    if (floatingIds.contains('${remoteUid}_remote')) return false;
                                    final remoteUserId = _userIdForRtcUid(
                                        remoteUid, participantsInRoom);
                                    if (remoteUserId == null) return true;
                                    final knownOnline =
                                        presenceMap[remoteUserId];
                                    if (knownOnline == null) return false;
                                    return knownOnline;
                                  })
                                  .map((remoteUid) {
                                    final remoteUserId = _userIdForRtcUid(
                                        remoteUid, participantsInRoom);
                                    final allowedViewers = remoteUserId == null
                                        ? const <String>[]
                                        : ref
                                                .watch(
                                                    userCamAllowedViewersProvider(
                                                        remoteUserId))
                                                .valueOrNull ??
                                            const <String>[];
                                    final canViewRemote =
                                        remoteUserId != null &&
                                            (allowedViewers.isEmpty ||
                                                allowedViewers
                                                    .contains(user.id));
                                    final tileLabel = remoteUserId != null
                                        ? (_senderDisplayNameById[
                                                remoteUserId] ??
                                            remoteUserId)
                                        : 'Guest $remoteUid';
                                    return CameraWallRemoteTileData(
                                      uid: remoteUid,
                                      userId: remoteUserId,
                                      label: tileLabel,
                                      canView: canViewRemote,
                                      isSpeaking: _agoraService!
                                          .isRemoteSpeaking(remoteUid),
                                      hasMic: remoteUserId != null &&
                                          participantsInRoom.any((p) =>
                                              p.userId == remoteUserId &&
                                              p.role == 'stage'),
                                      avatarUrl: remoteUserId != null
                                          ? _senderAvatarUrlById[remoteUserId]
                                          : null,
                                    );
                                  })
                                  .toList(growable: false);
                              return CameraWall(
                                roomId: widget.roomId,
                                roomName: roomName,
                                localLabel:
                                    _senderDisplayNameById[user.id] ?? 'You',
                                showLocalTile: (_agoraService?.isLocalVideoCapturing ?? false) && !localIsFloating,
                                localHasMic: participantsInRoom.any((p) =>
                                    p.userId == user.id &&
                                    p.role == 'stage'),
                                // Suppress speaking indicator when mic is muted so the
                                // local tile stays in the main grid (not the small
                                // "Talking Now" strip).  The VAD clone still monitors raw
                                // audio for the mic level bar even while muted.
                                localSpeaking: _agoraService!.localSpeaking && !_isMicMuted,
                                localTile: _buildLocalCamContent(
                                  avatarUrl: _senderAvatarUrlById[user.id],
                                ),
                                localAvatarUrl: _senderAvatarUrlById[user.id],
                                remoteTiles: remoteTiles,
                                maxMainGridRemoteTiles: slotCount,
                                remoteTileBuilder: (tile) =>
                                    KeyedSubtree(
                                  key: _remoteViewKey(tile.uid),
                                  child: _buildRemoteCamContent(
                                    remoteUid: tile.uid,
                                    canViewRemote: tile.canView,
                                    avatarUrl: tile.avatarUrl,
                                    onRequestAccess:
                                        (!tile.canView &&
                                                tile.userId != null &&
                                                tile.userId != _joinedUserId)
                                            ? () => _sendCamViewRequest(
                                                tile.userId!)
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
                                      .read(floatingCamWindowsProvider
                                          .notifier)
                                      .add(FloatingCamWindowData(
                                        id: '${user.id}_local',
                                        label:
                                            _senderDisplayNameById[user.id] ??
                                                'My Camera',
                                        isLocal: true,
                                        avatarUrl:
                                            _senderAvatarUrlById[user.id],
                                        offset: const Offset(40, 80),
                                        width: 320,
                                        height: 240,
                                      ));
                                },
                                onDetachRemote: (tile) {
                                  ref
                                      .read(floatingCamWindowsProvider
                                          .notifier)
                                      .add(FloatingCamWindowData(
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
                                      ));
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
                                  Text('🔴',
                                      style: TextStyle(fontSize: 48)),
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
                              (_chatColW + (chatRightOfCams ? -d.delta.dx : d.delta.dx))
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
                          panelMoveBtn('cams', -1,
                              tooltip: 'Move Cams left',
                              icon: Icons.chevron_left),
                          panelMoveBtn('cams', 1,
                              tooltip: 'Move Cams right',
                              icon: Icons.chevron_right),
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
                            vertical: 6, horizontal: 14),
                        color:
                            const Color(0xFFFFD700).withValues(alpha: 0.85),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐',
                                style: TextStyle(fontSize: 16)),
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
                                      .read(liveRoomControllerProvider(widget.roomId).notifier)
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
                            horizontal: 12, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _callError!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white),
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
                  // ── AVATAR STRIP + ONLINE COUNT (top-right of camera area) ──
                  Positioned(
                    top: 56,
                    left: 336,
                    child: presenceAsync.when(
                      data: (presence) {
                        final activeCutoff = DateTime.now()
                            .subtract(const Duration(seconds: 50));
                        final onlineCount = presence
                            .where((e) =>
                                e.isOnline &&
                                (e.lastHeartbeatAt == null ||
                                    e.lastHeartbeatAt!.isAfter(activeCutoff)))
                            .length;
                        if (onlineCount == 0) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: participantsInRoom.isEmpty
                              ? null
                              : () => _openPeopleSheet(
                                    participants: participantsInRoom,
                                    currentParticipant: participant,
                                    currentUserId: user.id,
                                    currentUsername: user.username,
                                    currentAvatarUrl: user.avatarUrl,
                                    hostId: hostId,
                                    isHost: isHost,
                                    isModerator: isModerator,
                                    hostControls: hostControls,
                                    presenceList:
                                        presenceAsync.valueOrNull ?? const [],
                                  ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0x9910131A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x30D4A853)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle,
                                    color: Color(0xFFC45E7A), size: 9),
                                const SizedBox(width: 5),
                                Text(
                                  '$onlineCount online',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
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
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            const medals = ['🥇', '🥈', '🥉'];
                            final gifter = topGifters[i];
                            final medal = i < 3 ? medals[i] : '${i + 1}';
                            final isFirst = i == 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: isFirst
                                    ? const LinearGradient(colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500)
                                      ])
                                    : null,
                                color: isFirst ? null : Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(medal,
                                      style:
                                          const TextStyle(fontSize: 12)),
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
                                        color: Colors.white54),
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
                        onToggleLock: () =>
                            hostControls.toggleLockRoom(widget.roomId),
                        onEndRoom: () =>
                            _confirmAndEndRoom(hostControls),
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
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xB310131A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x30D4A853)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.settings_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isCohost ? 'Co-host' : 'Mod Tools',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
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
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xCC10131A),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0x30D4A853)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.mic,
                                    size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                const Text('Mic',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${(_micVolume * 100).round()}%',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
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
                                      enabledThumbRadius: 7),
                                ),
                                child: Slider.adaptive(
                                  value: _micVolume,
                                  min: 0.0,
                                  max: 2.0,
                                  divisions: 40,
                                  label: '${(_micVolume * 100).round()}%',
                                  onChanged:
                                      _isCallReady ? _setMicVolume : null,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.volume_up,
                                    size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                const Text('Speaker',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${(_speakerVolume * 100).round()}%',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
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
                                      enabledThumbRadius: 7),
                                ),
                                child: Slider.adaptive(
                                  value: _speakerVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 20,
                                  label:
                                      '${(_speakerVolume * 100).round()}%',
                                  onChanged:
                                      _isCallReady ? _setSpeakerVolume : null,
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
                              panelMoveBtn('chat', -1,
                                  tooltip: 'Move Chat left',
                                  icon: Icons.chevron_left),
                              panelMoveBtn('chat', 1,
                                  tooltip: 'Move Chat right',
                                  icon: Icons.chevron_right),
                            ],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                          const Divider(height: 1, color: Color(0x30D4A853)),
                          // Gift + hand raise row for non-hosts.
                          // Resolve hostId from Firestore doc first; fall back
                          // to the participants list so the row shows even when
                          // ownerId isn't written to the room doc yet.
                          Builder(builder: (context) {
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
                                      borderRadius: BorderRadius.circular(6),
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
                          }),
                          // Blocked relationship warning
                          participantsAsync.when(
                            data: (participants) {
                              final hasBlocked = participants.any((p) {
                                final pid = p.userId.trim();
                                return pid.isNotEmpty &&
                                    pid != user.id &&
                                    _excludedUserIds.contains(pid);
                              });
                              if (!hasBlocked) return const SizedBox.shrink();
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
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
                              ref.read(micAccessControllerProvider)
                                  .approveRequest(widget.roomId, request).ignore();
                            },
                            onDeny: (request) {
                              ref.read(micAccessControllerProvider)
                                  .denyRequest(widget.roomId, request.id).ignore();
                            },
                          ),
                          // Messages list
                          Expanded(
                            child: messageStreamAsync.when(
                              data: (messages) {
                                if (messages.length !=
                                    _lastRenderedMessageCount) {
                                  // Play a soft ping for new incoming messages (not own).
                                  if (messages.length > _lastRenderedMessageCount) {
                                    final newest = messages.last;
                                    if (newest.senderId != _joinedUserId) {
                                      if (newest.type == 'private') {
                                        RoomAudioCues.instance.playPrivateMessage();
                                      } else if (newest.type == 'normal') {
                                        RoomAudioCues.instance.playNewMessage();
                                      }
                                    }
                                    if (newest.type == 'normal') {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _markRecentChatter(newest.senderId);
                                      });
                                    }
                                  }
                                  _lastRenderedMessageCount = messages.length;
                                  // Double postFrameCallback: first frame lets
                                  // ListView render the new item, second frame
                                  // ensures maxScrollExtent is fully updated.
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (scrollController.hasClients &&
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
                                    },
                                  );
                                }
                                if (messages.isEmpty) {
                                  return const Center(
                                    child: Text('No messages yet.'),
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
                                        currentUsername: user.username,
                                      ),
                                      senderVipLevel:
                                          _senderVipLevelById[msg.senderId] ??
                                          0,
                                        senderCamOn:
                                          participantByUserId[msg.senderId]
                                            ?.camOn ??
                                          false,
                                      senderAvatarUrl:
                                          _senderAvatarUrlById[msg.senderId],
                                      onTapSender: (senderId) =>
                                          UserProfilePopup.show(
                                            context,
                                            ref,
                                            userId: senderId,
                                          ),
                                        onTapCam: msg.senderId == user.id
                                          ? null
                                          : (senderId) =>
                                            _sendCamViewRequest(senderId),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(
                                child: Text('Error: $e'),
                              ),
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
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                child: _buildEmojiTray(),
                              ),
                            ),
                          if (_firestore != null)
                            StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>
                            >(
                              stream: _firestore!
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .collection('typing')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final docs = snapshot.data?.docs ?? [];
                                final currentUid = _joinedUserId ?? '';
                                final names = docs
                                    .where(
                                      (d) =>
                                          d.id != currentUid &&
                                          (d.data()['isTyping'] as bool? ??
                                              false),
                                    )
                                    .map(
                                      (d) =>
                                          _senderDisplayNameById[d.id] ??
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
                              onPendingColorChanged: (value) =>
                                  setState(() => _pendingRichColorHex = value),
                              onChanged: () => setState(() {}),
                            ),
                          // Input row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Emojis',
                                  icon: Icon(
                                    _showEmojiTray
                                        ? Icons.emoji_emotions
                                        : Icons.emoji_emotions_outlined,
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    setState(
                                      () =>
                                          _showEmojiTray = !_showEmojiTray,
                                    );
                                  },
                                ),
                                Tooltip(
                                  message: _showRichToolbar ? 'Hide formatting' : 'Rich text formatting',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.text_format,
                                      color: _showRichToolbar
                                          ? const Color(0xFFD4A853)
                                          : const Color(0xFF5A5E6B),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _showRichToolbar = !_showRichToolbar),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: messageController,
                                    onChanged: (_) => _onTypingInput(),
                                    enabled: !isSending &&
                                        participant?.isMuted != true &&
                                        participant?.isBanned != true &&
                                        !hasBlockedParticipantInRoom,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: isSending ||
                                            participant?.isMuted == true ||
                                            participant?.isBanned == true ||
                                            !allowChat ||
                                            hasBlockedParticipantInRoom
                                        ? null
                                        : (text) async {
                                          final trimmed = text.trim();
                                            if (trimmed.isEmpty) return;
                                          final outgoingMessage =
                                            _buildOutgoingChatMessage(trimmed);
                                            if (slowModeSeconds > 0 &&
                                                lastMessageTime != null) {
                                              final secs = DateTime.now()
                                                  .difference(lastMessageTime!)
                                                  .inSeconds;
                                              if (secs < slowModeSeconds) {
                                                setState(() {
                                                  cooldownMessage =
                                                      'Slow mode on. Wait ${slowModeSeconds - secs}s.';
                                                });
                                                return;
                                              }
                                            }
                                            setState(() => isSending = true);
                                            try {
                                              await sendMessage(outgoingMessage);
                                              lastMessageTime = DateTime.now();
                                              cooldownMessage = '';
                                              messageController.clear();
                                              _pendingRichColorHex = null;
                                              _showEmojiTray = false;
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(e.toString()),
                                                ));
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => isSending = false,
                                                );
                                              }
                                            }
                                          },
                                    decoration: InputDecoration(
                                      hintText: participant?.isMuted == true
                                          ? 'You are muted'
                                          : participant?.isBanned == true
                                          ? 'You are banned'
                                          : hasBlockedParticipantInRoom
                                          ? 'Blocked relationship in room'
                                          : !allowChat
                                          ? 'Chat disabled by host'
                                          : 'Type a message…',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilledButton(
                                  onPressed: isSending ||
                                          participant?.isMuted == true ||
                                          participant?.isBanned == true ||
                                          !allowChat ||
                                          hasBlockedParticipantInRoom
                                      ? null
                                      : () async {
                                          final trimmed = messageController.text
                                            .trim();
                                          if (trimmed.isEmpty) {
                                            return;
                                          }
                                          final outgoingMessage =
                                            _buildOutgoingChatMessage(trimmed);
                                          if (slowModeSeconds > 0 &&
                                              lastMessageTime != null) {
                                            final secs = DateTime.now()
                                                .difference(lastMessageTime!)
                                                .inSeconds;
                                            if (secs < slowModeSeconds) {
                                              setState(() {
                                                cooldownMessage =
                                                    'Slow mode on. Wait ${slowModeSeconds - secs}s.';
                                              });
                                              return;
                                            }
                                          }
                                          setState(() => isSending = true);
                                          try {
                                            await sendMessage(outgoingMessage);
                                            lastMessageTime = DateTime.now();
                                            cooldownMessage = '';
                                            messageController.clear();
                                            _pendingRichColorHex = null;
                                            _showEmojiTray = false;
                                            if (!_hasTrackedFirstMessage) {
                                              _hasTrackedFirstMessage = true;
                                              await AnalyticsService().logEvent(
                                                'first_message_sent',
                                                params: {
                                                  'room_id': widget.roomId,
                                                  'user_id': user.id,
                                                },
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (context.mounted) {
                                              setState(
                                                () => isSending = false,
                                              );
                                            }
                                          }
                                        },
                                  child: isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Send'),
                                ),
                              ],
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
                        // AppBar + ticker spacer so content starts below bar
                        SizedBox(
                            height: roomDescription.isEmpty
                                ? kToolbarHeight
                                : kToolbarHeight + 24),
                        // 32 px header row with ◄ ► move buttons
                        Container(
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF241820),
                            border: Border(
                              left: BorderSide(
                                  color: Color(0xFF2E2F3A), width: 1),
                            ),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 14, color: Color(0xFFD4A853)),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text('Users',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              panelMoveBtn('users', -1,
                                  tooltip: 'Move Users left',
                                  icon: Icons.chevron_left),
                              panelMoveBtn('users', 1,
                                  tooltip: 'Move Users right',
                                  icon: Icons.chevron_right),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _RoomRosterSidebar(
                            topPadding: 0,
                            participants: participantsInRoom,
                            displayNameById: Map.unmodifiable(
                                _senderDisplayNameById),
                            vipLevelById: Map.unmodifiable(
                                _senderVipLevelById),
                            genderById: Map.unmodifiable(
                                _senderGenderById),
                            currentUserId: user.id,
                            presenceList:
                                presenceAsync.valueOrNull ?? const [],
                            pendingMicCount: micRequestsAsync.valueOrNull
                                    ?.where((r) => r.status == 'pending')
                                    .length ??
                                0,
                            currentUserRole: participantsInRoom
                                    .firstWhere(
                                      (p) => p.userId == user.id,
                                      orElse: () => RoomParticipantModel(
                                        userId: user.id,
                                        role: 'member',
                                        joinedAt: DateTime.now(),
                                        lastActiveAt: DateTime.now(),
                                      ),
                                    )
                                    .role,
                            isMicFree: true,
                            isLocalVideoEnabled: _isVideoEnabled,
                            localSpeaking:
                                (_agoraService?.localSpeaking ?? false) ||
                                (!_isMicMuted &&
                                  participantsInRoom.any((p) =>
                                      p.userId == user.id && p.role == 'stage')),
                            recentChatters: Set.unmodifiable(_recentChatters),
                            remoteUids:
                                _agoraService?.remoteUids ?? const [],
                            isSpeakingFn: (uid) =>
                                _agoraService?.isRemoteSpeaking(uid) ??
                                false,
                            uidToUserId: (uid) =>
                                _userIdForRtcUid(uid, participantsInRoom),
                            onReleaseMic: () async {
                              try {
                                await micAccessController.releaseMic(
                                  roomId: widget.roomId,
                                  userId: user.id,
                                );
                                final svc = _agoraService;
                                if (svc != null && _isCallReady && !_isMicMuted) {
                                  await svc.mute(true);
                                      if (mounted) {
                                        _mediaController.setMicMuted(true);
                                      }
                                }
                                if (mounted) _showSnackBar('Mic released.');
                              } catch (e) {
                                if (mounted) _showSnackBar('Could not release mic: $e');
                              }
                            },
                            onJoinQueue: allowMicRequests
                                ? () async {
                                    // Grab the mic directly, displacing any
                                    // current stage user (co-hosts are
                                    // unaffected — their role stays 'cohost').
                                    try {
                                      await micAccessController
                                          .grabMicDirectly(
                                        roomId: widget.roomId,
                                        userId: user.id,
                                      );
                                      if (mounted) {
                                        _showSnackBar('You have the mic!');
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        _showSnackBar(
                                            'Could not grab mic: $e');
                                      }
                                    }
                                  }
                                : null,
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
                                      user2Name: _senderDisplayNameById[p.userId] ?? p.userId,
                                      user2AvatarUrl: _senderAvatarUrlById[p.userId],
                                    );
                                if (!context.mounted) return;
                                FloatingWhisperPanel.show(
                                  context,
                                  ref,
                                  conversationId: conversationId,
                                  peerName:
                                      _senderDisplayNameById[p.userId] ??
                                          p.userId,
                                  peerAvatarUrl:
                                      _senderAvatarUrlById[p.userId],
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
                      ref
                          .read(floatingCamWindowsProvider.notifier)
                          .remove(id);
                    },
                  ),
                  // Floating emoji particles (gift animations)
                  Positioned.fill(
                    child: FloatingGiftOverlay(key: _floatingGiftKey),
                  ),
                  // Buzz overlay (full-screen flash on receipt)
                  Positioned.fill(
                    child: BuzzOverlay(key: _buzzKey, child: const SizedBox.expand()),
                  ),
                ],
              ),
              bottomNavigationBar: !isMobile ? null : Container(
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
                              showSystemAudioButton: kIsWeb,
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
        body: AppErrorView(
          error: e,
          fallbackContext: 'load the live room',
        ),
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
    required this.participants,
    required this.displayNameById,
    required this.vipLevelById,
    required this.genderById,
    required this.currentUserId,
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
    this.isSendingSecretMessage = false,
    this.onSendSecretMessage,
    this.onCancelSecretMessage,
    this.topPadding = kToolbarHeight,
    this.recentChatters = const {},
  });

  final List<RoomParticipantModel> participants;
  final Map<String, String> displayNameById;
  final Map<String, int> vipLevelById;
  final Map<String, String?> genderById;
  final String currentUserId;
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
    // ── Compute speaking user IDs (others only) ───────────────
    final speakingUserIds = <String>{};
    for (final uid in remoteUids) {
      if (isSpeakingFn(uid)) {
        final userId = uidToUserId(uid);
        if (userId != null && userId != currentUserId) speakingUserIds.add(userId);
      }
    }

    // ── On-cam participants ───────────────────────────────────
    // Exclude the current user from all roster display sections — users
    // should only see others in the list, never themselves.
    final onCamParticipants = participants
        .where((p) => p.userId != currentUserId && p.camOn)
        .toList(growable: false);
    final participantByUserId = <String, RoomParticipantModel>{
      for (final participant in participants) participant.userId: participant,
    };

    // ── Sort: host → cohost → mod → audience (self excluded) ──
    final sorted = [...participants.where((p) => p.userId != currentUserId)]..sort((a, b) {
        int rank(String r) => switch (r) {
              'host' || 'owner' => 0,
              'cohost' => 1,
              'moderator' => 2,
              _ => 3,
            };
        return rank(a.role).compareTo(rank(b.role));
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
              child: Text('—',
                  style: TextStyle(color: _kSubtle, fontSize: 12)),
            )
          else
            ...speakingUserIds.take(3).map(
                  (uid) => _RosterRow(
                    displayName: displayNameById[uid] ?? uid,
                    vipLevel: vipLevelById[uid] ?? 0,
                    nameColor: _nameColor(vipLevelById[uid] ?? 0),
                    roleLabel: _roleLabel(participantByUserId[uid]),
                    camOn: participantByUserId[uid]?.camOn ?? false,
                    trailingIcon: Icons.mic,
                    trailingColor: const Color(0xFFC45E7A),
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
            label: 'Mic Queue  $pendingMicCount',
            icon: Icons.queue_music,
            iconColor: const Color(0xFFD4A853),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentUserRole == 'stage'
                      ? const Color(0xFFE53935)  // red = you are on mic
                      : isMicFree
                          ? const Color(0xFF1DB954)  // green = mic is free
                          : const Color(0xFF1756C8), // blue = join queue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                onPressed: currentUserRole == 'stage' ? onReleaseMic : onJoinQueue,
                child: Text(
                  currentUserRole == 'stage'
                      ? 'Release Mic'
                      : isMicFree
                          ? 'Grab Mic'
                          : 'Join Queue to Talk',
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          // ── On Cam ───────────────────────────────────────────
          _RosterHeader(
            label: 'On Cam  ${onCamParticipants.length}',
            icon: Icons.videocam,
            iconColor: const Color(0xFF4CAF50),
          ),
          if (onCamParticipants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('No cameras yet',
                  style: TextStyle(color: _kSubtle, fontSize: 11)),
            )
          else
            ...onCamParticipants.take(8).map(
                  (p) => _RosterRow(
                    displayName: displayNameById[p.userId] ?? p.userId,
                    vipLevel: vipLevelById[p.userId] ?? 0,
                    nameColor: _nameColor(vipLevelById[p.userId] ?? 0),
                    gender: genderById[p.userId],
                    roleLabel: _roleLabel(p),
                    trailingIcon: Icons.videocam,
                    trailingColor: Colors.white38,
                    camOn: true,
                    hasRecentChat: recentChatters.contains(p.userId),
                    onSecretMessage: onSecretMessage == null
                        ? null
                        : () => onSecretMessage!(p),
                    onDirectMessage: onWhisper == null
                        ? null
                        : () => onWhisper!(p),
                  ),
                ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          // ── Chatting ─────────────────────────────────────────
          _RosterHeader(
            label: 'Chatting  ${sorted.length}',
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFFB09080),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final p = sorted[i];
                final vip = vipLevelById[p.userId] ?? 0;
                return GestureDetector(
                  onTap: onWhisper == null ? null : () => onWhisper!(p),
                  child: _RosterRow(
                    displayName: displayNameById[p.userId] ?? p.userId,
                    vipLevel: vip,
                    nameColor: _nameColor(vip),
                    gender: genderById[p.userId],
                    roleLabel: _roleLabel(p),
                    camOn: p.camOn,
                    trailingIcon: p.role == 'host' || p.role == 'owner'
                        ? Icons.star
                        : p.role == 'cohost'
                            ? Icons.star_half
                            : null,
                    trailingColor: const Color(0xFFFFD700),
                    hasRecentChat: recentChatters.contains(p.userId),
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
              targetDisplayName:
                  displayNameById[secretComposerTarget!.userId] ??
                  secretComposerTarget!.userId,
              controller: secretComposerTextController!,
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

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.displayName,
    required this.vipLevel,
    required this.nameColor,
    this.gender,
    this.roleLabel,
    this.camOn = false,
    this.trailingIcon,
    this.trailingColor = Colors.white38,
    this.hasRecentChat = false,
    this.onSecretMessage,
    this.onDirectMessage,
  });

  final String displayName;
  final int vipLevel;
  final Color nameColor;
  final String? gender;
  final String? roleLabel;
  final bool camOn;
  final IconData? trailingIcon;
  final Color trailingColor;
  final bool hasRecentChat;
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
              if (vipLevel > 0) ...[
                const SizedBox(width: 3),
                Text(
                  '💎$vipLevel',
                  style: const TextStyle(
                      fontSize: 9, color: Color(0xFF7777BB)),
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
          colors: [
            color.withValues(alpha: 0.26),
            color.withValues(alpha: 0.1),
          ],
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
    required this.isSending,
    this.onCancel,
    this.onSend,
  });

  final String targetDisplayName;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF241820),
            Color(0xFF1A141B),
          ],
        ),
        border: Border(
          top: BorderSide(color: const Color(0xFFD4A853).withValues(alpha: 0.24)),
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
                  enabled: !isSending,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (isSending || onSend == null) return;
                    onSend!();
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type secret message... ',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F0D11),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x33D4A853)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x44D4A853)),
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
    final hostControls = ref.read(hostControlsProvider);
    final micAccessController = ref.read(micAccessControllerProvider);
    final roomPolicyController = ref.read(roomPolicyControllerProvider);
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final micRequestsAsync =
        ref.watch(roomMicAccessRequestsProvider(widget.roomId));
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                    StreamBuilder<DocumentSnapshot>(
                      stream: ref
                          .read(roomFirestoreProvider)
                          .collection('rooms')
                          .doc(widget.roomId)
                          .snapshots(),
                      builder: (context, snap) {
                        final data =
                            snap.data?.data() as Map<String, dynamic>?;
                        final slow =
                            (data?['slowModeSeconds'] as num?)?.toInt() ?? 0;
                        return SizedBox(
                          width: 190,
                          child: DropdownButtonFormField<int>(
                            initialValue: slow,
                            decoration: const InputDecoration(
                                labelText: 'Slow mode'),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Off')),
                              DropdownMenuItem(
                                  value: 5, child: Text('5 seconds')),
                              DropdownMenuItem(
                                  value: 10, child: Text('10 seconds')),
                              DropdownMenuItem(
                                  value: 30, child: Text('30 seconds')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                hostControls.toggleSlowMode(
                                    widget.roomId, val);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lock room'),
                        subtitle: Text(isLocked
                            ? 'New listeners blocked'
                            : 'Room is open'),
                        value: isLocked,
                        onChanged: (_) =>
                            hostControls.toggleLockRoom(widget.roomId),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chat'),
                        subtitle: Text(allowChat
                            ? 'Members can message'
                            : 'Chat paused'),
                        value: allowChat,
                        onChanged: (_) =>
                            hostControls.toggleAllowChat(widget.roomId),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mic requests'),
                        subtitle: Text(allowMicRequests
                            ? 'Users can request stage access'
                            : 'Requests paused'),
                        value: allowMicRequests,
                        onChanged: (_) =>
                            hostControls.toggleAllowMicRequests(widget.roomId),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gifts'),
                        subtitle: Text(allowGifts
                            ? 'Gift interactions enabled'
                            : 'Gifts paused'),
                        value: allowGifts,
                        onChanged: (_) =>
                            hostControls.toggleAllowGifts(widget.roomId),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        initialValue: roomPolicyAsync.valueOrNull?.micLimit ?? 6,
                        decoration:
                            const InputDecoration(labelText: 'Mic seats'),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('2 seats')),
                          DropdownMenuItem(value: 4, child: Text('4 seats')),
                          DropdownMenuItem(value: 6, child: Text('6 seats')),
                          DropdownMenuItem(value: 8, child: Text('8 seats')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          roomPolicyController.setMicLimit(
                              widget.roomId, value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        initialValue: roomPolicyAsync.valueOrNull?.camLimit ?? 6,
                        decoration:
                            const InputDecoration(labelText: 'Camera seats'),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('2 seats')),
                          DropdownMenuItem(value: 4, child: Text('4 seats')),
                          DropdownMenuItem(value: 6, child: Text('6 seats')),
                          DropdownMenuItem(value: 8, child: Text('8 seats')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          roomPolicyController.setCamLimit(
                              widget.roomId, value);
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
                      children: pending.map((request) {
                        return Card(
                          child: ListTile(
                            title: Text(
                                'Mic request from ${request.requesterId}'),
                            subtitle: Text(
                                'Approve for stage access • Priority ${request.priority}'),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      micAccessController.bumpPriority(
                                          widget.roomId, request.id),
                                  icon: const Icon(Icons.arrow_upward),
                                  tooltip: 'Bump priority',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      micAccessController.lowerPriority(
                                          widget.roomId, request.id),
                                  icon: const Icon(Icons.arrow_downward),
                                  tooltip: 'Lower priority',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      micAccessController.approveRequest(
                                          widget.roomId, request),
                                  icon: const Icon(
                                      Icons.check_circle_outline),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      micAccessController.denyRequest(
                                          widget.roomId, request.id),
                                  icon: const Icon(Icons.cancel_outlined),
                                  tooltip: 'Deny',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      micAccessController.expireNow(
                                          widget.roomId, request.id),
                                  icon: const Icon(
                                      Icons.timer_off_outlined),
                                  tooltip: 'Expire now',
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) =>
                      Text('Could not load mic requests: $e'),
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
  const _SystemAudioStep({
    required this.number,
    required this.text,
    this.icon,
  });

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
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 13),
                  ),
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
              style: const TextStyle(
                color: Color(0xFFB09080),
                fontSize: 11,
              ),
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

