import '../../services/room/room_limit_manager.dart';
import '../feature_flags.dart';
import '../utils/app_logger.dart';

/// Enforcement utilities for the 12-publisher room limit
///
/// Provides reusable functions for enforcing the limit across:
/// - Room join prevention
/// - Go Live button state
/// - Firestore room data validation
/// - Real-time capacity monitoring

class RoomLimitEnforcement {
  static final RoomLimitManager _limitManager = RoomLimitManager();

  // ============================================================================
  // ROOM JOIN ENFORCEMENT
  // ============================================================================

  /// Check if a user can join a room as a publisher
  /// Called BEFORE attempting to start camera/mic
  static Future<RoomJoinCheckResult> canUserJoinAsPublisher(
    String roomId,
    String userId,
  ) async {
    try {
      final isPublishing = await _limitManager.isUserPublishing(roomId, userId);
      if (isPublishing) {
        return RoomJoinCheckResult(
          canJoin: false,
          reason: 'User is already publishing in this room',
          limit: FeatureFlags.maxConcurrentAgoraConnections,
        );
      }

      final atCapacity = await _limitManager.isRoomAtCapacity(roomId);
      if (atCapacity) {
        final activeCount = await _limitManager.getPublisherCount(roomId);
        return RoomJoinCheckResult(
          canJoin: false,
          reason:
              'Room is full ($activeCount/${FeatureFlags.maxConcurrentAgoraConnections} publishers). '
              'Try joining as audience or wait for a publisher to leave.',
          limit: FeatureFlags.maxConcurrentAgoraConnections,
          currentCount: activeCount,
        );
      }

      final availableSlots = await _limitManager.getAvailableSlots(roomId);
      return RoomJoinCheckResult(
        canJoin: true,
        reason: 'Slot available',
        limit: FeatureFlags.maxConcurrentAgoraConnections,
        currentCount:
            FeatureFlags.maxConcurrentAgoraConnections - availableSlots,
        availableSlots: availableSlots,
      );
    } catch (e) {
      AppLogger.error('Error checking if user can join: $e');
      return RoomJoinCheckResult(
        canJoin: false,
        reason: 'Error checking room capacity: $e',
        limit: FeatureFlags.maxConcurrentAgoraConnections,
      );
    }
  }

  /// Register a user as a publisher when they join/go live
  /// Returns true if successfully registered, false if room at capacity
  static Future<bool> registerPublisher(String roomId, String userId) async {
    try {
      final success = await _limitManager.addPublisher(roomId, userId);
      if (success) {
        AppLogger.info('âœ… Registered publisher: $userId in room $roomId');
      } else {
        AppLogger.warning('âŒ Failed to register publisher: room at capacity');
      }
      return success;
    } catch (e) {
      AppLogger.error('Error registering publisher: $e');
      return false;
    }
  }

  /// Unregister a publisher when they stop streaming
  /// Always succeeds even if user wasn't publishing
  static Future<void> unregisterPublisher(String roomId, String userId) async {
    try {
      await _limitManager.removePublisher(roomId, userId);
      AppLogger.info('âœ… Unregistered publisher: $userId from room $roomId');
    } catch (e) {
      AppLogger.error('Error unregistering publisher: $e');
    }
  }

  // ============================================================================
  // GO LIVE BUTTON STATE
  // ============================================================================

  /// Determine if "Go Live" button should be enabled
  /// Returns state enum for UI
  static Future<GoLiveButtonState> getGoLiveButtonState(
    String roomId,
    String userId,
  ) async {
    try {
      final canGoLive = await _limitManager.canUserGoLive(roomId, userId);
      if (!canGoLive) {
        final isPublishing =
            await _limitManager.isUserPublishing(roomId, userId);
        if (isPublishing) {
          return GoLiveButtonState.alreadyLive;
        }
        return GoLiveButtonState.roomAtCapacity;
      }
      return GoLiveButtonState.enabled;
    } catch (e) {
      AppLogger.error('Error getting go live button state: $e');
      return GoLiveButtonState.error;
    }
  }

  /// Get human-readable message for Go Live button state
  static String getGoLiveButtonMessage(GoLiveButtonState state) {
    switch (state) {
      case GoLiveButtonState.enabled:
        return 'Go Live! Start streaming video';
      case GoLiveButtonState.alreadyLive:
        return 'You are already streaming. Stop before starting again.';
      case GoLiveButtonState.roomAtCapacity:
        return 'Room is full (${FeatureFlags.maxConcurrentAgoraConnections}/12 publishers). '
            'Wait for a publisher to leave.';
      case GoLiveButtonState.error:
        return 'Error checking room capacity. Try again.';
    }
  }

  // ============================================================================
  // CAPACITY MONITORING
  // ============================================================================

  /// Get detailed capacity info for a room
  static Future<RoomCapacityInfo> getRoomCapacityInfo(String roomId) async {
    try {
      final count = await _limitManager.getPublisherCount(roomId);
      const limit = FeatureFlags.maxConcurrentAgoraConnections;
      final available = await _limitManager.getAvailableSlots(roomId);
      final publishers = await _limitManager.getActivePublishers(roomId);

      final utilizationPercent = ((count / limit) * 100).toInt();
      final isNearCapacity = count >= (limit * 0.75).ceil();

      return RoomCapacityInfo(
        currentPublishers: count,
        maxPublishers: limit,
        availableSlots: available,
        publicationIds: publishers,
        utilizationPercent: utilizationPercent,
        isAtCapacity: count >= limit,
        isNearCapacity: isNearCapacity,
      );
    } catch (e) {
      AppLogger.error('Error getting room capacity info: $e');
      return RoomCapacityInfo(
        currentPublishers: 0,
        maxPublishers: FeatureFlags.maxConcurrentAgoraConnections,
        availableSlots: FeatureFlags.maxConcurrentAgoraConnections,
        publicationIds: [],
        utilizationPercent: 0,
        isAtCapacity: false,
        isNearCapacity: false,
      );
    }
  }

  /// Watch room capacity in real-time
  static Stream<int> watchRoomCapacity(String roomId) {
    return _limitManager.watchRoomCapacity(roomId);
  }

  // ============================================================================
  // GRACEFUL DEGRADATION
  // ============================================================================

  /// Check if we should enable adaptive bitrate based on current load
  /// When close to capacity, adaptive bitrate helps maintain stability
  static Future<bool> shouldEnableAdaptiveBitrate(String roomId) async {
    try {
      final count = await _limitManager.getPublisherCount(roomId);
      return _limitManager.shouldEnableAdaptiveBitrate(count);
    } catch (e) {
      AppLogger.error('Error checking adaptive bitrate: $e');
      return false;
    }
  }

  /// Get bandwidth allocation recommendations based on publisher count
  static Future<BandwidthAllocation> getBandwidthAllocation(
      String roomId) async {
    try {
      final count = await _limitManager.getPublisherCount(roomId);
      final allocation =
          _limitManager.getBandwidthAllocationByPublisherCount(count);
      return BandwidthAllocation(
        videoBitrate: allocation['video']!,
        audioBitrate: allocation['audio']!,
        publisherCount: count,
      );
    } catch (e) {
      AppLogger.error('Error getting bandwidth allocation: $e');
      return BandwidthAllocation(
        videoBitrate: 1500,
        audioBitrate: 64,
        publisherCount: 0,
      );
    }
  }

  /// Get list of remote streams that should be downgraded
  /// Used for multi-cam grid to reduce quality when at capacity
  static Future<List<int>> getStreamsToDowngrade(
    String roomId,
    List<int> allRemoteUids,
  ) async {
    try {
      return await _limitManager.getStreamsToDowngrade(roomId, allRemoteUids);
    } catch (e) {
      AppLogger.error('Error getting streams to downgrade: $e');
      return [];
    }
  }

  // ============================================================================
  // VALIDATION & CLEANUP
  // ============================================================================

  /// Validate that a room's Firestore data is consistent
  /// Can be called periodically to ensure data integrity
  static Future<void> validateRoomData(String roomId) async {
    try {
      final info = await getRoomCapacityInfo(roomId);
      if (info.isAtCapacity) {
        AppLogger.info(
            'Room $roomId at capacity: ${info.currentPublishers}/${info.maxPublishers}');
      }
    } catch (e) {
      AppLogger.error('Error validating room data: $e');
    }
  }

  /// Invalidate local cache for a room (call on leave)
  static void invalidateRoomCache(String roomId) {
    _limitManager.invalidateRoomCache(roomId);
  }

  /// Clear all cached room data
  static void clearAllCaches() {
    _limitManager.clearAllCaches();
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Result of checking if user can join a room
class RoomJoinCheckResult {
  final bool canJoin;
  final String reason;
  final int limit;
  final int currentCount;
  final int availableSlots;

  RoomJoinCheckResult({
    required this.canJoin,
    required this.reason,
    required this.limit,
    this.currentCount = 0,
    this.availableSlots = 0,
  });

  @override
  String toString() => 'RoomJoinCheckResult(canJoin=$canJoin, reason=$reason, '
      'current=$currentCount/$limit, available=$availableSlots)';
}

/// Detailed capacity information for a room
class RoomCapacityInfo {
  final int currentPublishers;
  final int maxPublishers;
  final int availableSlots;
  final List<String> publicationIds;
  final int utilizationPercent;
  final bool isAtCapacity;
  final bool isNearCapacity;

  RoomCapacityInfo({
    required this.currentPublishers,
    required this.maxPublishers,
    required this.availableSlots,
    required this.publicationIds,
    required this.utilizationPercent,
    required this.isAtCapacity,
    required this.isNearCapacity,
  });

  @override
  String toString() =>
      'RoomCapacityInfo(current=$currentPublishers/$maxPublishers, '
      'util=$utilizationPercent%, near=$isNearCapacity, at=$isAtCapacity)';
}

/// Bandwidth allocation for video/audio
class BandwidthAllocation {
  final int videoBitrate;
  final int audioBitrate;
  final int publisherCount;

  BandwidthAllocation({
    required this.videoBitrate,
    required this.audioBitrate,
    required this.publisherCount,
  });

  @override
  String toString() =>
      'BandwidthAllocation(video=$videoBitrate, audio=$audioBitrate, '
      'publishers=$publisherCount)';
}

/// State of the Go Live button
enum GoLiveButtonState {
  enabled,
  alreadyLive,
  roomAtCapacity,
  error,
}
