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
import '../../models/moderation_model.dart';
import '../../models/message_model.dart';
import '../../models/room_policy_model.dart';
import '../../models/room_participant_model.dart';
import '../providers/user_provider.dart';
import '../../features/room/providers/room_firestore_provider.dart';
import '../../features/room/providers/participant_providers.dart';
import '../../features/room/providers/message_providers.dart';
import '../../features/room/providers/presence_provider.dart';
import '../../features/room/widgets/message_bubble.dart';
import '../../features/room/widgets/camera_wall.dart';
import '../../features/room/widgets/room_control_sheets.dart';
import '../../features/room/widgets/floating_gift_overlay.dart';
import '../../widgets/coin_balance_widget.dart';
import '../../widgets/user_profile_popup.dart';
import '../../widgets/floating_whisper_panel.dart';
import '../../services/web_popout_service.dart';
import '../../services/desktop_window_service.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../features/room/providers/mic_access_provider.dart';
import '../../features/room/providers/host_controls_provider.dart';
import '../../features/room/providers/host_provider.dart';
import '../../features/room/providers/room_policy_provider.dart';
import '../../features/room/providers/room_gift_provider.dart';
import '../../features/room/providers/user_cam_permissions_provider.dart';
import '../../features/room/providers/room_slot_provider.dart';
import '../../features/room/room_permissions.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/agora_service.dart';
import '../../services/rtc_room_service.dart';
import '../../services/webrtc_room_service.dart';
import '../../services/follow_service.dart';
import '../../services/moderation_service.dart';
import '../../services/friend_service.dart';
import '../../services/notification_service.dart';
import '../../services/presence_service.dart';
import '../../services/room_audio_cues.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LiveRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen>
    with WidgetsBindingObserver {
  late TextEditingController messageController;
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
  bool _isCallConnecting = false;
  bool _isCallReady = false;
  bool _isMicMuted = false;
  bool _isVideoEnabled = false;
  bool _isMicActionInFlight = false;
  bool _isVideoActionInFlight = false;
  String? _cameraStatus;
  String _connectPhase = 'idle';
  String? _connectErrorCode;
  bool _showEmojiTray = false;
  String? _callError;
  int? _currentRtcUid;
  /// Slot id in rooms/{roomId}/slots currently held by this user, if any.
  String? _claimedSlotId;
  /// Prevents re-triggering camera toggle (double-click / web event replay).
  DateTime? _videoToggleCooldownUntil;
  Set<String> _excludedUserIds = const <String>{};
  String? _appliedMediaRole;
  bool _isHandlingParticipantRemoval = false;
  bool _preWarmDone = false;
  Timer? _presenceHeartbeatTimer;
  DateTime? _roomJoinedAt;
  int _lastRenderedMessageCount = 0;
  final Set<String> _shownGiftEventIds = {};
  final List<_GiftToast> _giftToasts = [];
  Timer? _giftToastTimer;
  Timer? _typingTimer;
  final GlobalKey<FloatingGiftOverlayState> _floatingGiftKey =
      GlobalKey<FloatingGiftOverlayState>();
  ProviderSubscription<AsyncValue<List<RoomGiftEvent>>>?
  _giftEventsSubscription;

  // Reconnect back-off state
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _kMaxBackoffSeconds = 30;
  final Map<String, String> _senderDisplayNameById = <String, String>{};
  final Map<String, int> _senderVipLevelById = <String, int>{};
  final Set<String> _senderLookupInFlight = <String>{};
  Set<int> _requestedHighQualityRemoteUids = <int>{};
  Set<int> _requestedLowQualityRemoteUids = <int>{};
  bool _remoteLayoutSyncQueued = false;
  bool _roleMediaStatePending = false;
  int _localViewEpoch = 0;
  int _lastPendingMicRequestCount = 0;
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

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    messageController = TextEditingController();
    scrollController = ScrollController();

    final user = ref.read(userProvider);
    if (user != null) {
      _firestore = ref.read(roomFirestoreProvider);
      _joinedUserId = user.id;
      // Pre-seed own display name so local tile shows username immediately.
      if (user.username.trim().isNotEmpty) {
        _senderDisplayNameById[user.id] = user.username.trim();
      }
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

  String? _userIdForRtcUid(int rtcUid, List<RoomParticipantModel> members) {
    for (final member in members) {
      if (_buildRtcUid(member.userId) == rtcUid) {
        return member.userId;
      }
    }
    return null;
  }

  void _logLiveRoom(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(message, name: 'LIVE_ROOM');
    debugPrint('[LIVE_ROOM] $message');
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

    _requestedHighQualityRemoteUids = normalizedHighQuality;
    _requestedLowQualityRemoteUids = normalizedLowQuality;

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
      setState(() {
        _connectPhase = phase;
      });
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

  /// Wires up the common callbacks on any [RtcRoomService] implementation.
  void _attachServiceCallbacks(RtcRoomService service) {
    service.onRemoteUserJoined = () {
      RoomAudioCues.instance.playUserJoined();
      if (mounted) setState(() {});
    };
    service.onRemoteUserLeft = () {
      RoomAudioCues.instance.playUserLeft();
      if (mounted) setState(() {});
    };
    service.onSpeakerActivityChanged = () {
      if (mounted) setState(() {});
    };
    service.onLocalVideoCaptureChanged = () {
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

    setState(() {
      _isCallConnecting = true;
      _callError = null;
      _connectErrorCode = null;
      _connectPhase = 'starting';
    });

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
          setState(() => _cameraStatus = 'Connecting to live room…');
        }
        final service = WebRtcRoomService(
          firestore: _firestore!,
          localUserId: userId,
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
          setState(() => _cameraStatus = 'Connecting: requesting token...');
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
              setState(() {
                _cameraStatus = attempt == 1
                    ? 'Connecting: initializing media engine…'
                    : 'Retrying media engine initialization…';
              });
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
              setState(() => _cameraStatus = 'Connecting: joining live room...');
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
                setState(() {
                  _connectPhase = 'retrying-init';
                  _cameraStatus = 'Retrying media engine initialization...';
                });
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
      // Store uid for later token renewal without channel rejoin.
      _currentRtcUid = rtcUid;
      setState(() {
        _agoraService = connectedService;
        _isCallReady = true;
        // Do NOT set _appliedMediaRole here. Leave it null so the first
        // build after connect calls _applyRoleMediaState with the actual
        // Firestore participant role rather than hardcoding 'member'.
        _isMicMuted = true;
        _isVideoEnabled = false;
        _localViewEpoch++;
        _connectPhase = 'ready';
        _cameraStatus = 'Live media ready. Tap camera to publish.';
      });
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
        setState(() {
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
          _connectErrorCode = errorCode;
          _connectPhase = 'failed';
          _callError = '$mappedError$debugSuffix';
          _cameraStatus =
              'Live media connect failed (phase=$_connectPhase code=$errorCode): $mappedError$debugSuffix';
          _isCallReady = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallConnecting = false;
        });
      }
    }
  }

  Future<void> _toggleMic() async {
    final service = _agoraService;
    if (service == null || !_isCallReady || _isMicActionInFlight) return;
    final next = !_isMicMuted;
    setState(() => _isMicActionInFlight = true);
    try {
      if (!next) {
        await service.ensureDeviceAccess(video: false, audio: true);
        await service.setBroadcaster(true);
        await service.publishLocalAudioStream(true);
      }
      await service.mute(next);
      if (mounted) {
        setState(() {
          _isMicMuted = next;
        });
      }
    } catch (e) {
      _showSnackBar(_mapMediaError(e, canBroadcast: true));
    } finally {
      if (mounted) {
        setState(() => _isMicActionInFlight = false);
      }
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

    if (service == null || !_isCallReady || _isVideoActionInFlight) {
      if (service == null) {
        _logLiveRoom('toggle_video:blocked service_null');
        if (mounted) {
          setState(
            () => _cameraStatus =
                'Camera blocked: live media service not initialized.',
          );
        }
        _showSnackBar('Agora service not initialized.');
      } else if (!_isCallReady) {
        _logLiveRoom('toggle_video:blocked call_not_ready');
        if (mounted) {
          setState(
            () => _cameraStatus = 'Camera blocked: live media not ready yet.',
          );
        }
        _showSnackBar('Call not ready. Wait a moment and retry.');
      } else {
        _logLiveRoom('toggle_video:blocked already_in_flight');
        if (mounted) {
          setState(() => _cameraStatus = 'Camera action already in progress...');
        }
        _showSnackBar('Camera action in progress...');
      }
      return;
    }

    final next = !_isVideoEnabled;
    _logLiveRoom(
      'toggle_video:next=$next broadcaster=${service.isBroadcaster} joined=${service.isJoinedChannel}',
    );
    setState(() {
      _isVideoActionInFlight = true;
      _cameraStatus = next ? 'Starting camera...' : 'Stopping camera...';
    });
    try {
      if (next) {
        if (mounted) {
          setState(() => _cameraStatus = 'Requesting browser camera access...');
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
              setState(() {
                _isVideoActionInFlight = false;
                _cameraStatus = 'All camera slots are full.';
              });
              _showSnackBar('All camera slots are full. Try again later.');
            }
            return;
          }
          _claimedSlotId = slotId;
          _logLiveRoom('slot_claimed: slotId=$slotId');
        }

        // enableVideo handles broadcaster role, channel options, startPreview, and
        // local video capture wait. Pass the current mic mute state so enabling
        // the camera does not silently re-enable a muted microphone.
        await service.enableVideo(true, publishMicrophoneTrack: !_isMicMuted);
        if (mounted) {
          setState(() => _appliedMediaRole = 'member');
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
            if (mounted) setState(() => _isMicMuted = true);
          }
        }
      }

      _logLiveRoom('toggle_video:success next=$next mounted=$mounted');
      // Only commit the state change if the AgoraService reference hasn't
      // been replaced (e.g. by _handleConnectionLost mid-enable). On web,
      // _awaitLocalVideoCapturing times out silently, so enableVideo() returns
      // success even after the old service was disposed and a new one created.
      if (mounted && identical(service, _agoraService)) {
        setState(() {
          _isVideoEnabled = next;
          // When turning off, clear the slot atomically with isVideoEnabled so
          // there is never a frame where claimedSlotId==null but video==true.
          if (!next) _claimedSlotId = null;
          _cameraStatus = next ? 'Camera active.' : 'Camera off.';
        });
        if (next) {
          Future<void>.delayed(const Duration(milliseconds: 450), () {
            if (mounted) setState(() {});
          });
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
        setState(() => _cameraStatus = 'Camera failed: $mapped$detail');
      }
    } finally {
      if (mounted) {
        // Set a short cooldown before another toggle is allowed. This prevents
        // a second click (or a Flutter-web button double-fire on rebuild) from
        // immediately re-toggling the camera.
        _videoToggleCooldownUntil =
            DateTime.now().add(const Duration(milliseconds: 900));
        setState(() => _isVideoActionInFlight = false);
      }
      _logLiveRoom('toggle_video:end');
    }
  }

  Widget _buildLocalCamContent() {
    final service = _agoraService;
    // Also gate on _isVideoEnabled: on web canRenderLocalView stays true when
    // the user keeps mic-only broadcaster mode after turning the camera off,
    // which would render a black AgoraVideoView instead of the "Camera is off"
    // placeholder.
    return service != null && service.canRenderLocalView && _isVideoEnabled
        ? KeyedSubtree(
            key: ValueKey<String>('local-view-$_localViewEpoch'),
            child: service.getLocalView(),
          )
        : ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _isVideoEnabled
                          ? 'Camera feed is preparing.'
                          : 'Camera is off.',
                      textAlign: TextAlign.center,
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
  }) {
    final service = _agoraService;
    return canViewRemote && service != null
        ? service.getRemoteView(remoteUid, widget.roomId)
        : ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      canViewRemote ? 'Loading video...' : 'Cam access locked',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  String _mapMediaError(Object error, {required bool canBroadcast}) {
    if (error is AgoraServiceException) {
      switch (error.code) {
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

  void _startPresenceHeartbeat(String userId) {
    _presenceHeartbeatTimer?.cancel();
    final presenceController = ref.read(roomPresenceControllerProvider);
    presenceController.setOnline(roomId: widget.roomId, userId: userId);
    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      presenceController.heartbeat(roomId: widget.roomId, userId: userId);
    });
  }

  Future<void> _stopPresenceHeartbeat() async {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    final userId = _joinedUserId;
    if (userId == null) {
      return;
    }
    try {
      await ref
          .read(roomPresenceControllerProvider)
          .setOffline(roomId: widget.roomId, userId: userId);
    } catch (_) {
      // Best-effort cleanup.
    }
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

    setState(() {
      _callError = null;
      _cameraStatus = delaySecs > 1
          ? 'Reconnecting in ${delaySecs}s…'
          : 'Reconnecting…';
    });

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
              _claimedSlotId = slotId;
              await service.enableVideo(true, publishMicrophoneTrack: !wasMicMuted);
              await service.mute(wasMicMuted);
              if (mounted) {
                setState(() {
                  _isVideoEnabled = true;
                  _isMicMuted = wasMicMuted;
                  _appliedMediaRole = previousRole ?? 'member';
                  _cameraStatus = 'Camera restored after reconnect.';
                });
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
    final service = _agoraService;
    _agoraService = null;
    _isCallReady = false;
    _isVideoEnabled = false;
    _isMicMuted = false;
    _appliedMediaRole = null;
    _isMicActionInFlight = false;
    _isVideoActionInFlight = false;
    _requestedHighQualityRemoteUids = <int>{};
    _requestedLowQualityRemoteUids = <int>{};
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
      if (mounted) setState(() => _appliedMediaRole = role);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _appliedMediaRole = role;
    });
  }

  void _exitRoom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/');
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

  void _onTypingInput() {
    _typingTimer?.cancel();
    final firestore = _firestore;
    final userId = _joinedUserId;
    if (firestore == null || userId == null || userId.isEmpty) return;
    firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('typing')
        .doc(userId)
        .set({'isTyping': true, 'updatedAt': FieldValue.serverTimestamp()});
    _typingTimer = Timer(const Duration(seconds: 3), _clearTypingStatus);
  }

  Future<void> _clearTypingStatus() async {
    _typingTimer?.cancel();
    _typingTimer = null;
    final firestore = _firestore;
    final userId = _joinedUserId;
    if (firestore == null || userId == null || userId.isEmpty) return;
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('typing')
          .doc(userId)
          .delete();
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
        }
      }

      // Prevent repeated lookups for missing docs by falling back to the id.
      for (final id in missingIds) {
        resolved.putIfAbsent(id, () => id);
        resolvedVip.putIfAbsent(id, () => 0);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _senderDisplayNameById.addAll(resolved);
        _senderVipLevelById.addAll(resolvedVip);
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
      _claimedSlotId = null;
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
          if (canHostOnlyManage)
            RoomActionItem(
              label: '⭐ Spotlight this person',
              icon: Icons.star_outline_rounded,
              onTap: () => runAction(() async {
                try {
                  final firestore = _firestore ?? ref.read(roomFirestoreProvider);
                  await (firestore as FirebaseFirestore)
                      .collection('rooms')
                      .doc(widget.roomId)
                      .update({'spotlightUserId': target.userId});
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
                if (mounted) {
                  context.pop();
                }
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
    // Build userId → isOnline map with 90-second heartbeat staleness window.
    final onlineMap = <String, bool>{
      for (final p in presenceList)
        if (p.isOnline &&
            (p.lastHeartbeatAt == null ||
                DateTime.now()
                        .difference(p.lastHeartbeatAt!)
                        .inSeconds <
                    90))
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

  Future<void> _joinRoom(String userId) async {
    final firestore = _firestore;
    if (firestore == null || _isJoiningRoom) return;

    setState(() {
      _isJoiningRoom = true;
      _roomJoinError = null;
    });

    try {
      _joinedUserId = userId;
      final now = DateTime.now();
      final roomDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .get();
      if (!roomDoc.exists) {
        setState(() => _roomJoinError = 'This room no longer exists.');
        _joinedUserId = null;
        _exitRoom();
        return;
      }

      final ownerId = _asString(
        roomDoc.data()?['ownerId'],
        fallback: _asString(roomDoc.data()?['hostId']),
      );
      final moderationService = ModerationService(firestore: firestore);
      _excludedUserIds = await moderationService.getExcludedUserIds(userId);

      if (ownerId.isNotEmpty) {
        final hasBlockingRelationship = await moderationService
            .hasBlockingRelationship(userId, ownerId);
        if (hasBlockingRelationship) {
          setState(() => _roomJoinError = 'You cannot join this room.');
          _joinedUserId = null;
          _exitRoom();
          return;
        }
      }

      if (_excludedUserIds.isNotEmpty) {
        final participantsSnapshot = await firestore
            .collection('rooms')
            .doc(widget.roomId)
            .collection('participants')
            .get();
        final hasBlockedParticipant = participantsSnapshot.docs.any((doc) {
          final participantData = doc.data();
          final participantId = _asString(
            participantData['userId'],
            fallback: doc.id,
          );
          return participantId.isNotEmpty &&
              participantId != userId &&
              _excludedUserIds.contains(participantId);
        });
        if (hasBlockedParticipant) {
          setState(
            () => _roomJoinError =
                'You cannot join while a blocked user is in this room.',
          );
          _joinedUserId = null;
          _exitRoom();
          return;
        }
      }

      final isLocked = _asBool(roomDoc.data()?['isLocked']);
      if (isLocked) {
        setState(() => _roomJoinError = 'Room is locked by host.');
        _joinedUserId = null;
        _exitRoom();
        return;
      }

      final docRef = firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('participants')
          .doc(userId);
      final memberDocRef = firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isBanned'] == true) {
          setState(() => _roomJoinError = 'You are banned from this room.');
          _joinedUserId = null;
          _exitRoom();
          return;
        }
        await docRef.update({'lastActiveAt': now});
        await memberDocRef.set({
          'userId': userId,
          'role': ownerId == userId ? 'owner' : 'member',
          'joinedAt': data['joinedAt'] ?? now,
          'lastActiveAt': now,
        }, SetOptions(merge: true));
      } else {
        final participantRole = ownerId == userId ? 'host' : 'audience';
        await docRef.set({
          'userId': userId,
          'role': participantRole,
          'isMuted': false,
          'isBanned': false,
          'joinedAt': now,
          'lastActiveAt': now,
        });
        await memberDocRef.set({
          'userId': userId,
          'role': ownerId == userId ? 'owner' : 'member',
          'joinedAt': now,
          'lastActiveAt': now,
        });
      }

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
      _startPresenceHeartbeat(userId);
      _roomJoinedAt = DateTime.now();
      PresenceService().setInRoom(userId, widget.roomId).ignore();
    } catch (_) {
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

  Future<void> _leaveRoom() async {
    final userId = _joinedUserId;
    final firestore = _firestore;
    if (userId == null || firestore == null) return;

    // Release any camera slot this user holds before removing their presence.
    if (_claimedSlotId != null) {
      try {
        final slotService = ref.read(roomSlotServiceProvider);
        await slotService.releaseSlot(widget.roomId, userId);
      } catch (_) {}
      _claimedSlotId = null;
    }

    final docRef = firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('participants')
        .doc(userId);
    final memberDocRef = firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('members')
        .doc(userId);
    try {
      await _stopPresenceHeartbeat();
      await docRef.delete();
      await memberDocRef.delete();
      final leavingUserId = userId;
      PresenceService().clearRoom(leavingUserId).ignore();
    } catch (_) {
      // Best-effort cleanup when users leave a room.
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

  String _cameraAccessHint({
    required String role,
    required String? camRequestStatus,
  }) {
    return 'Your camera can publish anytime. Use viewer controls to decide who can see it.';
  }

  String _micAccessHint({
    required String role,
    required String? micRequestStatus,
  }) {
    return 'Mic controls are unlocked. Speak anytime.';
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
    WidgetsBinding.instance.removeObserver(this);
    _presenceHeartbeatTimer?.cancel();
    _giftToastTimer?.cancel();
    _typingTimer?.cancel();
    _reconnectTimer?.cancel();
    _giftEventsSubscription?.close();
    unawaited(_clearTypingStatus());
    unawaited(_disconnectCall());
    unawaited(_leaveRoom());
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final userId = _joinedUserId;
    if (userId == null) {
      return;
    }
    final presenceController = ref.read(roomPresenceControllerProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _presenceHeartbeatTimer?.cancel();
      _presenceHeartbeatTimer = null;
      presenceController.setOffline(roomId: widget.roomId, userId: userId);
    } else if (state == AppLifecycleState.resumed) {
      _startPresenceHeartbeat(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
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
    final participantsAsync = ref.watch(
      participantsStreamProvider(widget.roomId),
    );
    final messageStreamAsync = ref.watch(messageStreamProvider(widget.roomId));
    final participantCountAsync = ref.watch(
      participantCountProvider(widget.roomId),
    );
    final presenceAsync = ref.watch(roomPresenceStreamProvider(widget.roomId));
    final hostAsync = ref.watch(hostProvider(widget.roomId));
    final coHostsAsync = ref.watch(coHostsProvider(widget.roomId));
    final roomPolicyAsync = ref.watch(roomPolicyProvider(widget.roomId));
    final myAllowedViewersAsync = ref.watch(
      userCamAllowedViewersProvider(user.id),
    );
    final micRequestsAsync = ref.watch(
      roomMicAccessRequestsProvider(widget.roomId),
    );
    final hostControls = ref.read(hostControlsProvider);
    final micAccessController = ref.read(micAccessControllerProvider);
    final userCamPermissionsController = ref.read(
      userCamPermissionsControllerProvider,
    );
    final roomPolicyController = ref.read(roomPolicyControllerProvider);
    final walletAsync = ref.watch(walletDetailsProvider);
    final topGifters = ref.watch(topGiftersProvider(widget.roomId));

    return currentParticipantAsync.when(
      data: (participant) {
        final isHost = ref.watch(isHostProvider(participant));
        final isCohost = ref.watch(isCohostProvider(participant));
        final isModerator = participant?.role == 'moderator';
        final role = participant?.role ?? 'audience';
        final myAllowedViewers =
            myAllowedViewersAsync.valueOrNull ?? const <String>[];
        final myMicRequestAsync = ref.watch(
          myMicAccessRequestProvider((
            roomId: widget.roomId,
            requesterId: user.id,
          )),
        );
        final micRequestStatus = myMicRequestAsync.valueOrNull?.status;
        final firestore = ref.watch(roomFirestoreProvider);
        // Skip role-media sync when the user has an active camera slot.
        // They are already in broadcaster state; re-applying would call
        // enableVideo() a second time and disrupt the live camera track.
        // Deduplicate: only queue one postFrameCallback at a time to prevent
        // multiple concurrent _applyRoleMediaState calls from rapid rebuilds.
        if (_isCallReady && _appliedMediaRole != role && _claimedSlotId == null &&
            !_roleMediaStatePending) {
          _roleMediaStatePending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _roleMediaStatePending = false;
            _applyRoleMediaState(role);
          });
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
              return const Scaffold(
                body: Center(child: Text('This room has ended.')),
              );
            }
            // Ban enforcement
            if (participant?.isBanned == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleForcedRoomExit('You were banned from this room.');
              });
              return const Scaffold(
                body: Center(child: Text('You are banned from this room.')),
              );
            }
            if (participant == null &&
                _hasTrackedRoomJoin &&
                !_isJoiningRoom &&
                _joinedUserId == user.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleForcedRoomExit('You were removed from this room.');
              });
              return const Scaffold(
                body: Center(child: Text('You were removed from this room.')),
              );
            }
            if (_roomJoinError != null && _joinedUserId == null) {
              return Scaffold(body: Center(child: Text(_roomJoinError!)));
            }
            final sendMessage = ref.read(sendMessageProvider(widget.roomId));
            final participantsInRoom =
                participantsAsync.valueOrNull ?? const [];
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
            final isDesktopLayout = MediaQuery.sizeOf(context).width >= 1180;
            if (isLocked && !isHost && !isCohost && !isModerator) {
              return const Scaffold(
                body: Center(child: Text('Room is locked.')),
              );
            }
            final roomName = _asString(roomData?['name'], fallback: 'Live Room');
            final spotlightUserId = _asString(roomData?['spotlightUserId']);
            final spotlightName = spotlightUserId.isNotEmpty
                ? (_senderDisplayNameById[spotlightUserId] ?? spotlightUserId)
                : null;
            return Scaffold(
              appBar: AppBar(
                title: Text(roomName),
                actions: [
                  // Coin balance
                  walletAsync.when(
                    data: (wallet) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Center(child: CoinBalanceWidget(balance: wallet.coinBalance)),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  // Invite friends to room
                  IconButton(
                    tooltip: 'Invite friends',
                    onPressed: () => _inviteFriendsToRoom(
                      userId: user.id,
                      username: user.username,
                      roomName: roomName,
                    ),
                    icon: const Icon(Icons.group_add_outlined),
                  ),
                  // Share room link
                  IconButton(
                    tooltip: 'Share room',
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'Join me in "$roomName" on MixVy!\nhttps://mixvy.app/room/${widget.roomId}',
                          subject: '$roomName – MixVy live room',
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                  ),
                  IconButton(
                    tooltip: 'Leave Room',
                    onPressed: () async {
                      await _disconnectCall();
                      await _leaveRoom();
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.logout),
                  ),
                  Builder(builder: (ctx) {
                    final pendingCount = isHost
                        ? (micRequestsAsync.valueOrNull
                                ?.where((r) => r.status == 'pending')
                                .length ??
                            0)
                        : 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'People in room',
                          onPressed: participantsInRoom.isEmpty
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
                          icon: const Icon(Icons.people_alt_outlined),
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'report_room') {
                        _reportTarget(
                          targetId: widget.roomId,
                          targetType: ReportTargetType.room,
                          title: 'Report room',
                          fallbackReason: 'Live room review requested',
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'report_room',
                        child: Text('Report room'),
                      ),
                    ],
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: isDesktopLayout ? 420 : 0),
                    child: Column(
                      children: [
                        // Spotlight banner
                        if (spotlightName != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 14,
                            ),
                            color: const Color(0xFFFFD700).withValues(alpha: 0.85),
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
                                      final firestore = _firestore ??
                                          ref.read(roomFirestoreProvider);
                                      await (firestore as FirebaseFirestore)
                                          .collection('rooms')
                                          .doc(widget.roomId)
                                          .update({
                                        'spotlightUserId': FieldValue.delete(),
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        if (_callError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _callError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _isCallConnecting
                                      ? null
                                      : () async {
                                          await _disconnectCall();
                                          if (!mounted) {
                                            return;
                                          }
                                          await _connectCall(user.id);
                                        },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry live media'),
                                ),
                              ],
                            ),
                          ),
                        if (_isCallConnecting)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: LinearProgressIndicator(),
                          ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                        if (_agoraService != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Camera Wall',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    // maxBroadcasters from the room document drives how
                                    // many camera positions the wall exposes (default 6).
                                    // Do NOT use the slot-stream length here — that count
                                    // reflects currently *occupied* slots (docs), not the cap.
                                    final rawMaxBc = roomData?['maxBroadcasters'];
                                    final slotCount = rawMaxBc is num ? rawMaxBc.toInt() : 6;

                                    // Kick off display-name lookups for all
                                    // on-cam users so tiles show usernames.
                                    final remoteUserIds = _agoraService!.remoteUids
                                        .map((uid) => _userIdForRtcUid(uid, participantsInRoom))
                                        .whereType<String>()
                                        .toList();
                                    if (remoteUserIds.isNotEmpty) {
                                      unawaited(_hydrateSenderDisplayNames(
                                        userIds: remoteUserIds,
                                        currentUserId: user.id,
                                      ));
                                    }

                                    // Build a map from userId → isOnline using the presence
                                    // stream so we can filter out stale webrtc_peers entries
                                    // (e.g. users who disconnected abruptly without cleanup).
                                    final presenceMap = <String, bool>{
                                      for (final p in presenceAsync.valueOrNull ??
                                          const <RoomPresenceModel>[])
                                        if (p.isOnline &&
                                            (p.lastHeartbeatAt == null ||
                                                DateTime.now()
                                                        .difference(
                                                          p.lastHeartbeatAt!,
                                                        )
                                                        .inSeconds <
                                                    90))
                                          p.userId: true,
                                    };

                                    final remoteTiles = _agoraService!.remoteUids
                                        .where((remoteUid) {
                                          // Filter out UIDs whose owner is confirmed offline.
                                          final remoteUserId = _userIdForRtcUid(
                                            remoteUid,
                                            participantsInRoom,
                                          );
                                          if (remoteUserId == null) return true; // unknown — show
                                          // If presence doc exists and user is not online → hide stale tile.
                                          final knownOnline = presenceMap[remoteUserId];
                                          if (knownOnline == null) return true; // no doc yet — show
                                          return knownOnline;
                                        })
                                        .map((remoteUid) {
                                          final remoteUserId = _userIdForRtcUid(
                                            remoteUid,
                                            participantsInRoom,
                                          );
                                          final allowedViewers =
                                              remoteUserId == null
                                              ? const <String>[]
                                              : ref
                                                        .watch(
                                                          userCamAllowedViewersProvider(
                                                            remoteUserId,
                                                          ),
                                                        )
                                                        .valueOrNull ??
                                                    const <String>[];
                                          // Empty allowedViewers means no restriction (open to all).
                                          // Only restrict when the list is non-empty (explicit allow-list).
                                          final canViewRemote =
                                              remoteUserId != null &&
                                              (allowedViewers.isEmpty ||
                                                  allowedViewers.contains(
                                                    user.id,
                                                  ));
                                          // Use cached display name if available,
                                          // fall back to userId while fetch is in progress.
                                          final tileLabel = remoteUserId != null
                                              ? (_senderDisplayNameById[remoteUserId] ?? remoteUserId)
                                              : 'Guest $remoteUid';
                                          return CameraWallRemoteTileData(
                                            uid: remoteUid,
                                            label: tileLabel,
                                            canView: canViewRemote,
                                            isSpeaking: _agoraService!
                                                .isRemoteSpeaking(remoteUid),
                                          );
                                        })
                                        .toList(growable: false);

                                    return CameraWall(
                                      roomId: widget.roomId,
                                      roomName: roomName,
                                      localLabel: _senderDisplayNameById[user.id] ?? 'You',
                                      localSpeaking:
                                          _agoraService!.localSpeaking,
                                      localTile: _buildLocalCamContent(),
                                      remoteTiles: remoteTiles,
                                      maxMainGridRemoteTiles: slotCount,
                                      remoteTileBuilder: (tile) {
                                        return _buildRemoteCamContent(
                                          remoteUid: tile.uid,
                                          canViewRemote: tile.canView,
                                        );
                                      },
                                      onSubscriptionPlanChanged: (
                                        highQualityUids,
                                        lowQualityUids,
                                      ) {
                                        _scheduleRemoteVideoLayoutSync(
                                          highQualityUids: highQualityUids,
                                          lowQualityUids: lowQualityUids,
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: _isMicMuted
                                          ? 'Unmute microphone'
                                          : 'Mute microphone',
                                      onPressed:
                                          RoomPermissions.canUseMic(role) &&
                                              !_isMicActionInFlight
                                          ? _toggleMic
                                          : null,
                                      icon: Icon(
                                        _isMicMuted ? Icons.mic_off : Icons.mic,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton.filledTonal(
                                      tooltip: _isVideoEnabled
                                          ? 'Turn camera off'
                                          : 'Turn camera on',
                                      onPressed:
                                          RoomPermissions.canUseCamera(role) &&
                                              !_isVideoActionInFlight &&
                                              (_videoToggleCooldownUntil ==
                                                      null ||
                                                  DateTime.now().isAfter(
                                                    _videoToggleCooldownUntil!,
                                                  ))
                                          ? () {
                                              if (mounted) {
                                                setState(
                                                  () => _cameraStatus =
                                                      'Camera button pressed. Initializing...',
                                                );
                                              }
                                              _toggleVideo();
                                            }
                                          : null,
                                      icon: Icon(
                                        _isVideoEnabled
                                            ? Icons.videocam
                                            : Icons.videocam_off,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _openManageCamViewersSheet(
                                    members: participantsInRoom,
                                    currentUserId: user.id,
                                    currentAllowedViewers: myAllowedViewers,
                                    controller: userCamPermissionsController,
                                  ),
                                  icon: const Icon(Icons.lock_open_outlined),
                                  label: const Text(
                                    'Manage who can view my cam',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _cameraAccessHint(
                                    role: role,
                                    camRequestStatus: null,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (_cameraStatus != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _cameraStatus!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                  ),
                                ],
                                if (kDebugMode && _agoraService != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'debug: phase=$_connectPhase code=${_connectErrorCode ?? "none"} ready=$_isCallReady joined=${_agoraService!.isJoinedChannel} broadcaster=${_agoraService!.isBroadcaster} capturing=${_agoraService!.isLocalVideoCapturing} video=$_isVideoEnabled inFlight=$_isVideoActionInFlight',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        if (isHost)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 280,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Host Controls',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            SizedBox(
                                              width: 190,
                                              child:
                                                  DropdownButtonFormField<int>(
                                                    initialValue:
                                                        slowModeSeconds,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Slow mode',
                                                        ),
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 0,
                                                        child: Text('Off'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 5,
                                                        child: Text(
                                                          '5 seconds',
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 10,
                                                        child: Text(
                                                          '10 seconds',
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 30,
                                                        child: Text(
                                                          '30 seconds',
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        hostControls
                                                            .toggleSlowMode(
                                                              widget.roomId,
                                                              val,
                                                            );
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
                                                  isLocked
                                                      ? 'New listeners blocked'
                                                      : 'Room is open',
                                                ),
                                                value: isLocked,
                                                onChanged: (_) =>
                                                    hostControls.toggleLockRoom(
                                                      widget.roomId,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 220,
                                              child: SwitchListTile.adaptive(
                                                contentPadding: EdgeInsets.zero,
                                                title: const Text('Chat'),
                                                subtitle: Text(
                                                  allowChat
                                                      ? 'Members can message'
                                                      : 'Chat paused',
                                                ),
                                                value: allowChat,
                                                onChanged: (_) => hostControls
                                                    .toggleAllowChat(
                                                      widget.roomId,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 220,
                                              child: SwitchListTile.adaptive(
                                                contentPadding: EdgeInsets.zero,
                                                title: const Text(
                                                  'Mic requests',
                                                ),
                                                subtitle: Text(
                                                  allowMicRequests
                                                      ? 'Users can request stage access'
                                                      : 'Requests paused',
                                                ),
                                                value: allowMicRequests,
                                                onChanged: (_) => hostControls
                                                    .toggleAllowMicRequests(
                                                      widget.roomId,
                                                    ),
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
                                                onChanged: (_) => hostControls
                                                    .toggleAllowGifts(
                                                      widget.roomId,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 220,
                                              child:
                                                  DropdownButtonFormField<int>(
                                                    initialValue:
                                                        roomPolicyAsync
                                                            .valueOrNull
                                                            ?.micLimit ??
                                                        6,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Mic seats',
                                                        ),
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 2,
                                                        child: Text('2 seats'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 4,
                                                        child: Text('4 seats'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 6,
                                                        child: Text('6 seats'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 8,
                                                        child: Text('8 seats'),
                                                      ),
                                                    ],
                                                    onChanged: (value) {
                                                      if (value == null) return;
                                                      roomPolicyController
                                                          .setMicLimit(
                                                            widget.roomId,
                                                            value,
                                                          );
                                                    },
                                                  ),
                                            ),
                                            SizedBox(
                                              width: 220,
                                              child:
                                                  DropdownButtonFormField<int>(
                                                    initialValue:
                                                        roomPolicyAsync
                                                            .valueOrNull
                                                            ?.camLimit ??
                                                        6,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Camera seats',
                                                        ),
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 2,
                                                        child: Text('2 seats'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 4,
                                                        child: Text('4 seats'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 6,
                                                        child: Text('6 seats'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 8,
                                                        child: Text('8 seats'),
                                                      ),
                                                    ],
                                                    onChanged: (value) {
                                                      if (value == null) return;
                                                      roomPolicyController
                                                          .setCamLimit(
                                                            widget.roomId,
                                                            value,
                                                          );
                                                    },
                                                  ),
                                            ),
                                            SizedBox(
                                              width: 240,
                                              child: DropdownButtonFormField<String>(
                                                initialValue:
                                                    roomPolicyAsync
                                                        .valueOrNull
                                                        ?.defaultCamViewPolicy
                                                        .name ??
                                                    CamViewPolicy
                                                        .approvedOnly
                                                        .name,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Default cam policy',
                                                    ),
                                                items: CamViewPolicy.values
                                                    .map(
                                                      (policy) =>
                                                          DropdownMenuItem(
                                                            value: policy.name,
                                                            child: Text(
                                                              policy.name,
                                                            ),
                                                          ),
                                                    )
                                                    .toList(growable: false),
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  final policy = CamViewPolicy
                                                      .values
                                                      .firstWhere(
                                                        (item) =>
                                                            item.name == value,
                                                        orElse: () =>
                                                            CamViewPolicy
                                                                .approvedOnly,
                                                      );
                                                  roomPolicyController
                                                      .setDefaultCamViewPolicy(
                                                        widget.roomId,
                                                        policy,
                                                      );
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width: 220,
                                              child:
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    initialValue:
                                                        roomPolicyAsync
                                                            .valueOrNull
                                                            ?.visibility
                                                            .name ??
                                                        MixVyRoomVisibility
                                                            .public
                                                            .name,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Room visibility',
                                                        ),
                                                    items: MixVyRoomVisibility
                                                        .values
                                                        .map(
                                                          (
                                                            visibility,
                                                          ) => DropdownMenuItem(
                                                            value:
                                                                visibility.name,
                                                            child: Text(
                                                              visibility.name,
                                                            ),
                                                          ),
                                                        )
                                                        .toList(
                                                          growable: false,
                                                        ),
                                                    onChanged: (value) {
                                                      if (value == null) return;
                                                      final visibility =
                                                          MixVyRoomVisibility
                                                              .values
                                                              .firstWhere(
                                                                (item) =>
                                                                    item.name ==
                                                                    value,
                                                                orElse: () =>
                                                                    MixVyRoomVisibility
                                                                        .public,
                                                              );
                                                      roomPolicyController
                                                          .setVisibility(
                                                            widget.roomId,
                                                            visibility,
                                                          );
                                                    },
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed:
                                                  participantsInRoom.isEmpty
                                                  ? null
                                                  : () => _openPeopleSheet(
                                                      participants:
                                                          participantsInRoom,
                                                      currentParticipant:
                                                          participant,
                                                      currentUserId: user.id,
                                                      currentUsername:
                                                          user.username,
                                                      currentAvatarUrl:
                                                          user.avatarUrl,
                                                      hostId: hostId,
                                                      isHost: true,
                                                      isModerator: false,
                                                      hostControls:
                                                          hostControls,
                                                      presenceList:
                                                          presenceAsync
                                                              .valueOrNull ??
                                                          const [],
                                                    ),
                                              icon: const Icon(
                                                Icons.manage_accounts_outlined,
                                              ),
                                              label: const Text(
                                                'Manage people',
                                              ),
                                            ),
                                            if (participantsInRoom.isNotEmpty)
                                              Chip(
                                                label: Text(
                                                  '${participantsInRoom.length} participants',
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Mic request queue',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        micRequestsAsync.when(
                                          data: (requests) {
                                            final pendingRequests = requests
                                                .where(
                                                  (request) =>
                                                      request.status ==
                                                      'pending',
                                                )
                                                .toList(growable: false);
                                            // Play audio cue when a new hand raise arrives.
                                            if (isHost && pendingRequests.length > _lastPendingMicRequestCount) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                RoomAudioCues.instance.playHandRaised();
                                              });
                                            }
                                            _lastPendingMicRequestCount = pendingRequests.length;
                                            if (pendingRequests.isEmpty) {
                                              return const Text(
                                                'No pending mic requests.',
                                              );
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: pendingRequests
                                                  .map((request) {
                                                    return Card(
                                                      child: ListTile(
                                                        title: Text(
                                                          'Mic request from ${request.requesterId}',
                                                        ),
                                                        subtitle: Text(
                                                          'Approve for stage audio access • Priority ${request.priority}',
                                                        ),
                                                        trailing: Wrap(
                                                          spacing: 8,
                                                          children: [
                                                            IconButton(
                                                              onPressed: () =>
                                                                  micAccessController
                                                                      .bumpPriority(
                                                                        widget
                                                                            .roomId,
                                                                        request
                                                                            .id,
                                                                      ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .arrow_upward,
                                                              ),
                                                              tooltip:
                                                                  'Bump priority',
                                                            ),
                                                            IconButton(
                                                              onPressed: () =>
                                                                  micAccessController
                                                                      .lowerPriority(
                                                                        widget
                                                                            .roomId,
                                                                        request
                                                                            .id,
                                                                      ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .arrow_downward,
                                                              ),
                                                              tooltip:
                                                                  'Lower priority',
                                                            ),
                                                            IconButton(
                                                              onPressed: () =>
                                                                  micAccessController
                                                                      .approveRequest(
                                                                        widget
                                                                            .roomId,
                                                                        request,
                                                                      ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .check_circle_outline,
                                                              ),
                                                              tooltip:
                                                                  'Approve',
                                                            ),
                                                            IconButton(
                                                              onPressed: () =>
                                                                  micAccessController
                                                                      .denyRequest(
                                                                        widget
                                                                            .roomId,
                                                                        request
                                                                            .id,
                                                                      ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .cancel_outlined,
                                                              ),
                                                              tooltip: 'Deny',
                                                            ),
                                                            IconButton(
                                                              onPressed: () =>
                                                                  micAccessController
                                                                      .expireNow(
                                                                        widget
                                                                            .roomId,
                                                                        request
                                                                            .id,
                                                                      ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .timer_off_outlined,
                                                              ),
                                                              tooltip:
                                                                  'Expire now',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .toList(growable: false),
                                            );
                                          },
                                          loading: () =>
                                              const LinearProgressIndicator(),
                                          error: (e, _) => Text(
                                            'Could not load mic requests: $e',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!isHost) ...[
                          if (!isCohost && !isModerator)
                            Card(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stage & camera access',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Any member can publish their camera.',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _cameraAccessHint(
                                        role: role,
                                        camRequestStatus: null,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _micAccessHint(
                                        role: role,
                                        micRequestStatus: micRequestStatus,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Presence header and avatar strip
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                participantCountAsync.when(
                                  data: (participantCount) => Text(
                                    '$participantCount total joined',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  loading: () => const SizedBox(
                                    width: 60,
                                    child: LinearProgressIndicator(),
                                  ),
                                  error: (e, _) => const Text('—'),
                                ),
                                const Spacer(),
                                presenceAsync.when(
                                  data: (presence) {
                                    final activeCutoff = DateTime.now()
                                        .subtract(const Duration(seconds: 50));
                                    final onlineCount = presence
                                        .where(
                                          (entry) =>
                                              entry.isOnline &&
                                              (entry.lastHeartbeatAt == null ||
                                                  entry.lastHeartbeatAt!
                                                      .isAfter(activeCutoff)),
                                        )
                                        .length;
                                    return Chip(
                                      avatar: const Icon(
                                        Icons.circle,
                                        color: Colors.green,
                                        size: 10,
                                      ),
                                      label: Text('$onlineCount online'),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'People in room',
                                  onPressed: participantsInRoom.isEmpty
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
                                              presenceAsync.valueOrNull ??
                                              const [],
                                        ),
                                  icon: const Icon(Icons.people_outline),
                                ),
                                hostAsync.when(
                                  data: (host) => host != null
                                      ? CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.amber,
                                          child: Text(
                                            'H',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  loading: () => const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey,
                                  ),
                                  error: (e, _) => const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 8),
                                coHostsAsync.when(
                                  data: (cohosts) => Row(
                                    children: cohosts
                                        .map(
                                          (cohost) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 2.0,
                                            ),
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.blue,
                                              child: Text(
                                                'C',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  loading: () => const SizedBox(
                                    width: 32,
                                    child: LinearProgressIndicator(),
                                  ),
                                  error: (e, _) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (topGifters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('🏆', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Top Gifters',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 44,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: topGifters.length,
                                    separatorBuilder: (_, idx) =>
                                        const SizedBox(width: 6),
                                    itemBuilder: (ctx, i) {
                                      const medals = ['🥇', '🥈', '🥉'];
                                      final gifter = topGifters[i];
                                      final medal = i < 3 ? medals[i] : '${i + 1}';
                                      final isFirst = i == 0;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
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
                                          color: isFirst
                                              ? null
                                              : Theme.of(ctx)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(22),
                                          border: isFirst
                                              ? null
                                              : Border.all(
                                                  color: Theme.of(ctx)
                                                      .colorScheme
                                                      .outlineVariant,
                                                ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(medal,
                                                style: const TextStyle(fontSize: 14)),
                                            const SizedBox(width: 4),
                                            Text(
                                              gifter.displayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isFirst
                                                    ? Colors.white
                                                    : Theme.of(ctx)
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '🪙${gifter.totalCoins}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isFirst
                                                    ? Colors.white70
                                                    : Theme.of(ctx)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                              ],
                            ),
                          ),
                        ),
                        if (!isDesktopLayout) ...[
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                              child: messageStreamAsync.when(
                              data: (messages) {
                                if (messages.length !=
                                    _lastRenderedMessageCount) {
                                  _lastRenderedMessageCount = messages.length;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (scrollController.hasClients) {
                                      scrollController.jumpTo(
                                        scrollController
                                            .position
                                            .maxScrollExtent,
                                      );
                                    }
                                  });
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
                                      senderVipLevel: _senderVipLevelById[msg.senderId] ?? 0,
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(child: Text('Error: $e')),
                            ),
                            ),
                          ),
                          participantsAsync.when(
                            data: (participants) {
                              final hasBlockedParticipant = participants.any((
                                p,
                              ) {
                                final participantId = p.userId.trim();
                                if (participantId.isEmpty ||
                                    participantId == user.id) {
                                  return false;
                                }
                                return _excludedUserIds.contains(participantId);
                              });

                              if (!hasBlockedParticipant) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Blocked relationship detected in this room. Leave to continue safely.',
                                  style: Theme.of(context).textTheme.bodySmall
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
                          if (cooldownMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                cooldownMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (_showEmojiTray) _buildEmojiTray(),
                          if (_firestore != null)
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestore!
                                .collection('rooms')
                                .doc(widget.roomId)
                                .collection('typing')
                                .snapshots(),
                            builder: (context, snapshot) {
                              final docs = snapshot.data?.docs ?? [];
                              final currentUid = _joinedUserId ?? '';
                              final names = docs
                                  .where((d) =>
                                      d.id != currentUid &&
                                      (d.data()['isTyping'] as bool? ?? false))
                                  .map((d) =>
                                      _senderDisplayNameById[d.id] ??
                                      'Someone')
                                  .toList(growable: false);
                              if (names.isEmpty) return const SizedBox.shrink();
                              final label = names.length == 1
                                  ? '${names[0]} is typing…'
                                  : '${names.join(', ')} are typing…';
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                ),
                              );
                            },
                          ),
                          SafeArea(
                            top: false,
                            minimum: const EdgeInsets.only(bottom: 90),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  if (allowGifts &&
                                      !isHost &&
                                      hostId.isNotEmpty &&
                                      hostId != user.id)
                                    IconButton(
                                      tooltip: 'Send a gift',
                                      icon: const Icon(Icons.card_giftcard),
                                      onPressed: () => _showGiftSheet(
                                        hostId: hostId,
                                        hostName: 'Host',
                                        senderName: user.username,
                                        coinBalance:
                                            walletAsync
                                                .valueOrNull
                                                ?.coinBalance ??
                                            0,
                                      ),
                                    ),
                                  // Raise hand button for audience members
                                  if (!isHost && !isCohost && !isModerator && allowMicRequests)
                                    _HandRaiseButton(
                                      status: micRequestStatus,
                                      onRaise: () => micAccessController.requestAccess(
                                        roomId: widget.roomId,
                                        requesterId: user.id,
                                        hostId: hostId,
                                      ),
                                      onCancel: () => micAccessController.expireNow(
                                        widget.roomId,
                                        '${user.id}_$hostId',
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: 'Emojis',
                                    icon: Icon(
                                      _showEmojiTray
                                          ? Icons.emoji_emotions
                                          : Icons.emoji_emotions_outlined,
                                    ),
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        _showEmojiTray = !_showEmojiTray;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: messageController,
                                      onChanged: (_) => _onTypingInput(),
                                      enabled:
                                          !isSending &&
                                          participant?.isMuted != true &&
                                          participant?.isBanned != true &&
                                          !hasBlockedParticipantInRoom,
                                      decoration: InputDecoration(
                                        hintText: participant?.isMuted == true
                                            ? 'You are muted'
                                            : participant?.isBanned == true
                                            ? 'You are banned'
                                            : hasBlockedParticipantInRoom
                                            ? 'Blocked relationship in room'
                                            : !allowChat
                                            ? 'Chat disabled by host'
                                            : 'Type your message...',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          isSending ||
                                              participant?.isMuted == true ||
                                              participant?.isBanned == true ||
                                              !allowChat ||
                                              hasBlockedParticipantInRoom
                                          ? null
                                          : () async {
                                              if (messageController.text
                                                  .trim()
                                                  .isEmpty) {
                                                return;
                                              }
                                              if (slowModeSeconds > 0 &&
                                                  lastMessageTime != null) {
                                                final secondsSinceLastMessage =
                                                    DateTime.now()
                                                        .difference(
                                                          lastMessageTime!,
                                                        )
                                                        .inSeconds;
                                                if (secondsSinceLastMessage <
                                                    slowModeSeconds) {
                                                  setState(() {
                                                    cooldownMessage =
                                                        'Slow mode is on. Wait ${slowModeSeconds - secondsSinceLastMessage}s.';
                                                  });
                                                  return;
                                                }
                                              }

                                              setState(() => isSending = true);
                                              try {
                                                await sendMessage(
                                                  messageController.text.trim(),
                                                );
                                                lastMessageTime =
                                                    DateTime.now();
                                                cooldownMessage = '';
                                                messageController.clear();
                                                _showEmojiTray = false;

                                                if (!_hasTrackedFirstMessage) {
                                                  _hasTrackedFirstMessage =
                                                      true;
                                                  await AnalyticsService()
                                                      .logEvent(
                                                        'first_message_sent',
                                                        params: {
                                                          'room_id':
                                                              widget.roomId,
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
                                                      content: Text(
                                                        e.toString(),
                                                      ),
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isDesktopLayout)
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: 420,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  6,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Room Chat',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${participantsInRoom.length} joined',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: messageStreamAsync.when(
                                  data: (messages) {
                                    if (messages.isEmpty) {
                                      return const Center(
                                        child: Text('No messages yet.'),
                                      );
                                    }
                                    return ListView.builder(
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
                                          senderVipLevel: _senderVipLevelById[msg.senderId] ?? 0,
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
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (_showEmojiTray)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    8,
                                    4,
                                  ),
                                  child: _buildEmojiTray(),
                                ),
                              if (_firestore != null)
                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: _firestore!
                                    .collection('rooms')
                                    .doc(widget.roomId)
                                    .collection('typing')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final docs = snapshot.data?.docs ?? [];
                                  final currentUid = _joinedUserId ?? '';
                                  final names = docs
                                      .where((d) =>
                                          d.id != currentUid &&
                                          (d.data()['isTyping'] as bool? ?? false))
                                      .map((d) =>
                                          _senderDisplayNameById[d.id] ??
                                          'Someone')
                                      .toList(growable: false);
                                  if (names.isEmpty) return const SizedBox.shrink();
                                  final label = names.length == 1
                                      ? '${names[0]} is typing…'
                                      : '${names.join(', ')} are typing…';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    child: Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                    ),
                                  );
                                },
                              ),
                              SafeArea(
                                top: false,
                                minimum: const EdgeInsets.fromLTRB(8, 0, 8, 88),
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
                                        setState(() {
                                          _showEmojiTray = !_showEmojiTray;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: messageController,
                                        onChanged: (_) => _onTypingInput(),
                                        enabled:
                                            !isSending &&
                                            participant?.isMuted != true &&
                                            participant?.isBanned != true &&
                                            !hasBlockedParticipantInRoom,
                                        decoration: InputDecoration(
                                          hintText: participant?.isMuted == true
                                              ? 'You are muted'
                                              : participant?.isBanned == true
                                              ? 'You are banned'
                                              : hasBlockedParticipantInRoom
                                              ? 'Blocked relationship in room'
                                              : !allowChat
                                              ? 'Chat disabled by host'
                                              : 'Type your message...',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed:
                                          isSending ||
                                              participant?.isMuted == true ||
                                              participant?.isBanned == true ||
                                              !allowChat ||
                                              hasBlockedParticipantInRoom
                                          ? null
                                          : () async {
                                              if (messageController.text
                                                  .trim()
                                                  .isEmpty) {
                                                return;
                                              }
                                              if (slowModeSeconds > 0 &&
                                                  lastMessageTime != null) {
                                                final secondsSinceLastMessage =
                                                    DateTime.now()
                                                        .difference(
                                                          lastMessageTime!,
                                                        )
                                                        .inSeconds;
                                                if (secondsSinceLastMessage <
                                                    slowModeSeconds) {
                                                  setState(() {
                                                    cooldownMessage =
                                                        'Slow mode is on. Wait ${slowModeSeconds - secondsSinceLastMessage}s.';
                                                  });
                                                  return;
                                                }
                                              }
                                              setState(() => isSending = true);
                                              try {
                                                await sendMessage(
                                                  messageController.text.trim(),
                                                );
                                                lastMessageTime =
                                                    DateTime.now();
                                                cooldownMessage = '';
                                                messageController.clear();
                                                _showEmojiTray = false;
                                              } finally {
                                                if (context.mounted) {
                                                  setState(
                                                    () => isSending = false,
                                                  );
                                                }
                                              }
                                            },
                                      child: const Text('Send'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                                color: Colors.black.withValues(alpha: 0.75),
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
                  // Floating emoji particles (gift animations)
                  Positioned.fill(
                    child: FloatingGiftOverlay(key: _floatingGiftKey),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
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
class _HandRaiseButton extends StatelessWidget {
  const _HandRaiseButton({
    required this.status,
    required this.onRaise,
    required this.onCancel,
  });

  final String? status;
  final VoidCallback onRaise;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return IconButton(
      tooltip: isPending ? 'Cancel hand raise' : 'Raise hand to speak',
      icon: Icon(
        isPending ? Icons.front_hand : Icons.front_hand_outlined,
        color: isPending ? Colors.orange : null,
      ),
      onPressed: isPending ? () => onCancel() : onRaise,
    );
  }
}
