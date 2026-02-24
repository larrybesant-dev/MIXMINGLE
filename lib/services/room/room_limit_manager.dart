import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/feature_flags.dart';
import '../../core/utils/app_logger.dart';

/// Manages room capacity enforcement for Agora video publishers
///
/// Ensures that the 12-concurrent-publisher limit is enforced across:
/// - Room join logic
/// - Go Live button state
/// - Firestore room data
/// - Multi-cam grid subscriptions
/// - Graceful stream degradation
///
/// Architecture:
/// - Agora RTC mode (not Live Streaming)
/// - Flutter Web + Web SDK
/// - 12 stable video publishers per channel
class RoomLimitManager extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  // Cache of active publishers per room
  final Map<String, List<String>> _roomPublishers = {};

  // Limit constant (architecturally correct)
  int get maxPublishers => FeatureFlags.maxConcurrentAgoraConnections;

  RoomLimitManager({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // PUBLIC INTERFACE
  // ============================================================================

  /// Check if a room is at capacity (has max publishers)
  Future<bool> isRoomAtCapacity(String roomId) async {
    try {
      final activePublishers = await getActivePublishers(roomId);
      final isAtCapacity = activePublishers.length >= maxPublishers;

      if (isAtCapacity) {
        AppLogger.warning(
          'ðŸ”´ Room $roomId is at capacity: '
          '${activePublishers.length}/$maxPublishers publishers'
        );
      }

      return isAtCapacity;
    } catch (e) {
      AppLogger.error('Error checking room capacity: $e');
      return false;
    }
  }

  /// Get count of active publishers in a room
  Future<int> getPublisherCount(String roomId) async {
    try {
      final publishers = await getActivePublishers(roomId);
      return publishers.length;
    } catch (e) {
      AppLogger.error('Error getting publisher count: $e');
      return 0;
    }
  }

  /// Get list of active publisher user IDs in a room
  Future<List<String>> getActivePublishers(String roomId) async {
    try {
      // Check cache first
      if (_roomPublishers.containsKey(roomId)) {
        return _roomPublishers[roomId]!;
      }

      // Fetch from Firestore
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();

      if (!roomDoc.exists) {
        AppLogger.warning('Room $roomId does not exist');
        return [];
      }

      final activeBroadcasters =
        List<String>.from(roomDoc.data()?['activeBroadcasters'] ?? []);

      // Cache the result
      _roomPublishers[roomId] = activeBroadcasters;

      return activeBroadcasters;
    } catch (e) {
      AppLogger.error('Error fetching active publishers: $e');
      return [];
    }
  }

  /// Check if a specific user is a publisher in a room
  Future<bool> isUserPublishing(String roomId, String userId) async {
    try {
      final publishers = await getActivePublishers(roomId);
      return publishers.contains(userId);
    } catch (e) {
      AppLogger.error('Error checking user publisher status: $e');
      return false;
    }
  }

  /// Add a user as an active publisher (called when they "Go Live")
  /// Returns true if successfully added, false if room at capacity
  Future<bool> addPublisher(String roomId, String userId) async {
    try {
      final currentPublishers = await getActivePublishers(roomId);

      // Check if already publishing
      if (currentPublishers.contains(userId)) {
        AppLogger.info('User $userId is already publishing in room $roomId');
        return true;
      }

      // Check if at capacity
      if (currentPublishers.length >= maxPublishers) {
        AppLogger.warning(
          'âŒ Cannot add publisher: room at capacity '
          '(${currentPublishers.length}/$maxPublishers)'
        );
        return false;
      }

      // Add publisher to Firestore
      final updatedPublishers = [...currentPublishers, userId];
      await _firestore.collection('rooms').doc(roomId).update({
        'activeBroadcasters': updatedPublishers,
        'broadcastersUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update cache
      _roomPublishers[roomId] = updatedPublishers;
      notifyListeners();

      AppLogger.info(
        'âœ… Added publisher: $userId '
        '(${updatedPublishers.length}/$maxPublishers)'
      );

      return true;
    } catch (e) {
      AppLogger.error('Error adding publisher: $e');
      return false;
    }
  }

  /// Remove a user from active publishers (called when they stop streaming)
  Future<void> removePublisher(String roomId, String userId) async {
    try {
      final currentPublishers = await getActivePublishers(roomId);

      if (!currentPublishers.contains(userId)) {
        AppLogger.info('User $userId is not publishing in room $roomId');
        return;
      }

      // Remove from Firestore
      final updatedPublishers = currentPublishers
          .where((id) => id != userId)
          .toList();

      await _firestore.collection('rooms').doc(roomId).update({
        'activeBroadcasters': updatedPublishers,
        'broadcastersUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update cache
      _roomPublishers[roomId] = updatedPublishers;
      notifyListeners();

      AppLogger.info(
        'âœ… Removed publisher: $userId '
        '(${updatedPublishers.length}/$maxPublishers)'
      );
    } catch (e) {
      AppLogger.error('Error removing publisher: $e');
    }
  }

  /// Get available slots for new publishers
  Future<int> getAvailableSlots(String roomId) async {
    try {
      final publisherCount = await getPublisherCount(roomId);
      return max(0, maxPublishers - publisherCount);
    } catch (e) {
      AppLogger.error('Error getting available slots: $e');
      return 0;
    }
  }

  /// Check if a user CAN start publishing (not at limit and not already publishing)
  Future<bool> canUserGoLive(String roomId, String userId) async {
    try {
      // Already publishing?
      final isPublishing = await isUserPublishing(roomId, userId);
      if (isPublishing) {
        AppLogger.info('User $userId is already publishing');
        return false;
      }

      // Room at capacity?
      final atCapacity = await isRoomAtCapacity(roomId);
      if (atCapacity) {
        AppLogger.warning('Room $roomId is at capacity');
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('Error checking if user can go live: $e');
      return false;
    }
  }

  // ============================================================================
  // GRACEFUL DEGRADATION - Stream Quality Management
  // ============================================================================

  /// Calculate available bandwidth based on publisher count
  /// Used to adjust video quality when approaching capacity
  Map<String, int> getBandwidthAllocationByPublisherCount(int publisherCount) {
    // As publishers increase, allocate less bandwidth per stream
    // This prevents degradation when approaching the 12-publisher limit

    final videoBitrate = <String, int>{
      'high': 2500,    // > 8 publishers: 2.5 Mbps per stream
      'medium': 1500,  // 5-8 publishers: 1.5 Mbps per stream
      'low': 800,      // < 5 publishers: 800 kbps per stream
    }[_getBandwidthTier(publisherCount)] ?? 1500;

    return {
      'video': videoBitrate,
      'audio': 64, // Audio stays constant
    };
  }

  String _getBandwidthTier(int publisherCount) {
    if (publisherCount <= 4) return 'high';
    if (publisherCount <= 8) return 'medium';
    return 'low';
  }

  /// Check if we should enable adaptive bitrate
  /// When closer to capacity, enable adaptive bitrate to maintain stability
  bool shouldEnableAdaptiveBitrate(int publisherCount) {
    // Enable adaptive bitrate at 75% capacity
    return publisherCount >= (maxPublishers * 0.75).ceil();
  }

  /// Calculate which remote streams to downgrade for stability
  /// Returns list of UIDs that should be downgraded to lower quality
  Future<List<int>> getStreamsToDowngrade(
    String roomId,
    List<int> allRemoteUids,
  ) async {
    try {
      final publisherCount = await getPublisherCount(roomId);

      // At or near capacity? Downgrade lowest-quality streams
      if (publisherCount >= (maxPublishers * 0.9).ceil()) {
        // Downgrade the last 1/3 of streams to lower resolution
        final downgradeCount = (allRemoteUids.length / 3).ceil();
        return allRemoteUids.skip(allRemoteUids.length - downgradeCount).toList();
      }

      return [];
    } catch (e) {
      AppLogger.error('Error calculating streams to downgrade: $e');
      return [];
    }
  }

  // ============================================================================
  // MONITORING & ANALYTICS
  // ============================================================================

  /// Log room capacity metrics (for analytics)
  Future<void> logRoomMetrics(String roomId) async {
    try {
      final publisherCount = await getPublisherCount(roomId);
      final utilizationPercent = (publisherCount / maxPublishers * 100).toStringAsFixed(1);

      AppLogger.info(
        'ðŸ“Š Room $roomId capacity: $publisherCount/$maxPublishers ($utilizationPercent%)'
      );
    } catch (e) {
      AppLogger.error('Error logging room metrics: $e');
    }
  }

  /// Listen to room capacity changes in real-time
  /// Returns a stream of publisher counts for a room
  Stream<int> watchRoomCapacity(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final activeBroadcasters =
        List<String>.from(doc.data()?['activeBroadcasters'] ?? []);

      // Update cache
      _roomPublishers[roomId] = activeBroadcasters;
      notifyListeners();

      return activeBroadcasters.length;
    });
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Invalidate cache for a room (called on leave)
  void invalidateRoomCache(String roomId) {
    _roomPublishers.remove(roomId);
    notifyListeners();
  }

  /// Clear all caches
  void clearAllCaches() {
    _roomPublishers.clear();
    notifyListeners();
  }
}

// Helper to maintain max
int max(int a, int b) => a > b ? a : b;
