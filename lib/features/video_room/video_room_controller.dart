import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../core/utils/app_logger.dart';
import 'video_room_state.dart';
import 'video_room_lifecycle.dart';

/// Reference: DESIGN_BIBLE.md Section G (Complete Integration)
/// Notifier pattern for video room - manages state transitions and side effects
/// ðŸ”„ RIVERPOD V3 MIGRATION: Using Notifier instead of StateNotifier
class VideoRoomNotifier extends Notifier<VideoRoomState> {
  late final VideoRoomLifecycle _lifecycle;
  final String _appId;
  final String _roomId;
  final String _userId;

  VideoRoomNotifier({
    required String appId,
    required String roomId,
    required String userId,
  })  : _appId = appId,
        _roomId = roomId,
        _userId = userId;

  @override
  VideoRoomState build() {
    // Initialize lifecycle here
    _lifecycle = VideoRoomLifecycle(appId: _appId, userId: _userId);
    return VideoRoomState(roomId: _roomId, userId: _userId);
  }

  /// Initialize the video system
  /// Must be called after auth and before joining a room
  Future<void> initializeVideo() async {
    // Prevent re-initialization
    if (state.isInitialized || state.isInitializing) {
      debugPrint('[VIDEO_NOTIFIER] Already initialized, skipping');
      return;
    }

    try {
      state = state.copyWith(isInitializing: true, error: null);
      AppLogger.info('ðŸ“± Initializing video system...');

      // Initialize Agora SDK
      await _lifecycle.initialize();

      // Request permissions
      final permGranted = await _lifecycle.requestPermissions();
      if (!permGranted) {
        throw Exception('Camera/microphone permissions denied');
      }

      state = state.copyWith(
        isInitializing: false,
        isInitialized: true,
        cameraEnabled: true,
        micEnabled: true,
      );

      AppLogger.info('âœ… Video system initialized');
    } catch (e) {
      debugPrint('[VIDEO_NOTIFIER] Initialization error: $e');
      state = state.copyWith(
        isInitializing: false,
        error: 'Failed to initialize video: $e',
      );
      AppLogger.error('âŒ Video initialization failed: $e');
      rethrow;
    }
  }

  /// Join a video room/channel
  /// Prerequisites: initializeVideo() must have been called successfully
  Future<void> joinRoom({
    required String roomName,
    required String token,
  }) async {
    // Prevent joining if not initialized
    if (!state.isInitialized) {
      throw Exception('Video system not initialized. Call initializeVideo() first.');
    }

    // Prevent re-joining
    if (state.isJoined || state.isJoining) {
      debugPrint('[VIDEO_NOTIFIER] Already joined, skipping');
      return;
    }

    try {
      state = state.copyWith(isJoining: true, error: null);
      AppLogger.info('ðŸ”— Joining room: $roomName...');

      await _lifecycle.joinChannel(
        roomId: state.roomId,
        roomName: roomName,
        token: token,
      );

      state = state.copyWith(
        isJoining: false,
        isJoined: true,
        joinedAt: DateTime.now(),
      );

      AppLogger.info('âœ… Joined room successfully');
    } catch (e) {
      debugPrint('[VIDEO_NOTIFIER] Join error: $e');
      state = state.copyWith(
        isJoining: false,
        error: 'Failed to join room: $e',
      );
      AppLogger.error('âŒ Failed to join room: $e');
      rethrow;
    }
  }

  /// Leave the video room and cleanup
  Future<void> leaveRoom() async {
    if (!state.isJoined && !state.isJoining) {
      debugPrint('[VIDEO_NOTIFIER] Not in a room, skipping leave');
      return;
    }

    try {
      state = state.copyWith(isLeaving: true, error: null);
      AppLogger.info('ðŸ‘‹ Leaving room...');

      await _lifecycle.leaveChannel();

      state = state.copyWith(
        isLeaving: false,
        isJoined: false,
        cameraEnabled: false,
        micEnabled: false,
        remoteUserCount: 0,
        remoteUserIds: const [],
      );

      AppLogger.info('âœ… Left room');
    } catch (e) {
      debugPrint('[VIDEO_NOTIFIER] Leave error: $e');
      state = state.copyWith(
        isLeaving: false,
        error: 'Error during cleanup: $e',
      );
      AppLogger.warning('âš ï¸ Cleanup error: $e');
      // Don't rethrow - we want to allow app closing even if cleanup fails
    }
  }

  /// Toggle microphone
  /// Enforces DESIGN_BIBLE.md tone: "Mute your mic" not "Toggle input state"
  Future<void> toggleMicrophone() async {
    if (!state.isJoined) return;

    try {
      await _lifecycle.setMicMuted(!state.micEnabled);
      state = state.copyWith(micEnabled: !state.micEnabled);
      AppLogger.info(state.micEnabled ? 'ðŸŽ¤ Mic enabled' : 'ðŸ”‡ Mic muted');
    } catch (e) {
      AppLogger.error('âŒ Microphone control failed: $e');
      rethrow;
    }
  }

  /// Toggle camera
  /// Enforces DESIGN_BIBLE.md tone: "Turn off your camera" not "Toggle video state"
  Future<void> toggleCamera() async {
    if (!state.isJoined) return;

    try {
      await _lifecycle.setVideoMuted(!state.cameraEnabled);
      state = state.copyWith(cameraEnabled: !state.cameraEnabled);
      AppLogger.info(state.cameraEnabled ? 'ðŸ“¹ Camera on' : 'ðŸ“¹ Camera off');
    } catch (e) {
      AppLogger.error('âŒ Camera control failed: $e');
      rethrow;
    }
  }

  /// Update remote user count (called from stream listeners)
  void updateRemoteUsers(List<String> userIds) {
    state = state.copyWith(
      remoteUserIds: userIds,
      remoteUserCount: userIds.length,
    );
  }

  /// Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Get debug state from bridge
  Map<String, dynamic> getDebugState() {
    return _lifecycle.getState();
  }

  /// Enable debug logging
  void enableDebugLogging() {
    _lifecycle.enableDebugLogging();
  }
}

/// Provider for video room controller
/// RIVERPOD V3: Using family modifier for room ID parameter
final videoRoomProvider = NotifierProvider.family<
    VideoRoomNotifier,
    VideoRoomState,
    ({String appId, String roomId, String userId})>(
  (params) => VideoRoomNotifier(
    appId: params.appId,
    roomId: params.roomId,
    userId: params.userId,
  ),
);

/// Convenience provider selector for video room state
/// Usage: ref.watch(videoRoomStateSelector(roomId))
final videoRoomStateSelector = Provider.family<
    VideoRoomState,
    ({String appId, String roomId, String userId})>((ref, params) {
  return ref.watch(videoRoomProvider(params));
});
