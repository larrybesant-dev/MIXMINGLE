/// Friend Presence Monitoring Service
///
/// Tracks friend presence changes and triggers notifications
/// Throttles updates to 10-15 seconds per design
/// Reference: DESIGN_BIBLE.md Section G (Backend Integration)
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_presence.dart';
import '../core/utils/app_logger.dart';
import 'fcm_notification_service.dart';

/// Tracks presence of a single friend for notification purposes
class FriendPresenceTracker {
  final String friendId;
  final String friendName;
  PresenceState lastSeenState = PresenceState.offline;
  DateTime lastNotificationTime = DateTime.now();
  static const Duration throttleDuration = Duration(seconds: 15);

  FriendPresenceTracker({
    required this.friendId,
    required this.friendName,
  });

  /// Check if presence state changed significantly
  bool hasStateChanged(PresenceState newState) {
    // Notify only on online/offline transitions, not idle/away
    final significantChange = (lastSeenState == PresenceState.offline &&
            newState == PresenceState.online) ||
        (lastSeenState == PresenceState.online &&
            newState == PresenceState.offline);

    if (!significantChange) return false;

    // Throttle notifications (max 1 per 15 seconds)
    final timeSinceLastNotification =
        DateTime.now().difference(lastNotificationTime);
    if (timeSinceLastNotification < throttleDuration) {
      return false;
    }

    lastSeenState = newState;
    lastNotificationTime = DateTime.now();
    return true;
  }
}

/// Service for monitoring and reacting to friend presence changes
class PresenceNotificationService {
  final FcmNotificationService _fcm;
  final String _currentUserId;

  // Track friends to monitor
  final Map<String, FriendPresenceTracker> _trackedFriends = {};

  // Firestore listener subscriptions
  final Map<String, StreamSubscription> _presenceListeners = {};

  PresenceNotificationService({
    required FcmNotificationService fcm,
    required String currentUserId,
  })  : _fcm = fcm,
        _currentUserId = currentUserId;

  /// Start monitoring friend presence
  Future<void> initialize({
    required List<String> friendIds,
    required Map<String, String> friendNamesMap,
  }) async {
    try {
      AppLogger.info(
        '[PresenceNotification] Starting monitoring for ${friendIds.length} friends',
      );

      for (final friendId in friendIds) {
        final friendName = friendNamesMap[friendId] ?? 'Friend';
        _trackedFriends[friendId] =
            FriendPresenceTracker(friendId: friendId, friendName: friendName);

        // Start listening to this friend's presence
        _startPresenceListener(friendId);
      }
    } catch (e) {
      AppLogger.error('[PresenceNotification] Initialization failed: $e');
    }
  }

  /// Start listening to a friend's presence changes
  void _startPresenceListener(String friendId) {
    // Cancel existing listener if any
    _presenceListeners[friendId]?.cancel();

    try {
      _presenceListeners[friendId] = FirebaseFirestore.instance
          .collection('presence')
          .doc(friendId)
          .snapshots()
          .listen(
        (snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data() ?? {};
          final stateStr = data['state'] as String? ?? 'offline';
          final newState = presenceStateFromString(stateStr);

          _handlePresenceChange(friendId, newState);
        },
        onError: (e) {
          AppLogger.error(
            '[PresenceNotification] Listener error for $friendId: $e',
          );
        },
      );

      AppLogger.info('[PresenceNotification] Listener started for $friendId');
    } catch (e) {
      AppLogger.error(
        '[PresenceNotification] Failed to start listener for $friendId: $e',
      );
    }
  }

  /// Handle presence state change for a friend
  Future<void> _handlePresenceChange(
    String friendId,
    PresenceState newState,
  ) async {
    final tracker = _trackedFriends[friendId];
    if (tracker == null) return;

    // Check if this is a significant change worth notifying about
    if (!tracker.hasStateChanged(newState)) return;

    try {
      if (newState == PresenceState.online) {
        // Send "friend online" notification via FCM
        await _fcm.notifyFriendOnline(
          recipientUserId: _currentUserId,
          friendUserId: friendId,
          friendName: tracker.friendName,
        );

        AppLogger.info(
          '[PresenceNotification] Notified: ${tracker.friendName} is online',
        );
      } else if (newState == PresenceState.offline) {
        // Send "friend offline" notification via FCM
        await _fcm.notifyFriendOffline(
          recipientUserId: _currentUserId,
          friendUserId: friendId,
          friendName: tracker.friendName,
        );

        AppLogger.info(
          '[PresenceNotification] Notified: ${tracker.friendName} went offline',
        );
      }
    } catch (e) {
      AppLogger.error(
        '[PresenceNotification] Failed to send notification for $friendId: $e',
      );
    }
  }

  /// Update the list of friends to monitor
  Future<void> updateFriendsList({
    required List<String> friendIds,
    required Map<String, String> friendNamesMap,
  }) async {
    try {
      // Remove listeners for friends no longer in the list
      final friendsToRemove = _trackedFriends.keys
          .where((friendId) => !friendIds.contains(friendId))
          .toList();

      for (final friendId in friendsToRemove) {
        _presenceListeners[friendId]?.cancel();
        _presenceListeners.remove(friendId);
        _trackedFriends.remove(friendId);
      }

      // Add listeners for new friends
      for (final friendId in friendIds) {
        if (!_trackedFriends.containsKey(friendId)) {
          final friendName = friendNamesMap[friendId] ?? 'Friend';
          _trackedFriends[friendId] = FriendPresenceTracker(
            friendId: friendId,
            friendName: friendName,
          );
          _startPresenceListener(friendId);
        }
      }

      AppLogger.info(
        '[PresenceNotification] Updated friends list: ${friendIds.length} friends',
      );
    } catch (e) {
      AppLogger.error('[PresenceNotification] Failed to update friends list: $e');
    }
  }

  /// Cleanup all listeners
  void cleanup() {
    AppLogger.info('[PresenceNotification] Cleaning up all listeners');
    for (final listener in _presenceListeners.values) {
      listener.cancel();
    }
    _presenceListeners.clear();
    _trackedFriends.clear();
  }

  /// Get debug info about tracked friends
  Map<String, dynamic> getDebugInfo() {
    return {
      'trackedFriendsCount': _trackedFriends.length,
      'activeListenersCount': _presenceListeners.length,
      'trackedFriends': _trackedFriends.entries.map((e) {
        return {
          'friendId': e.key,
          'friendName': e.value.friendName,
          'lastSeenState': e.value.lastSeenState.displayText,
          'lastNotificationTime': e.value.lastNotificationTime.toIso8601String(),
        };
      }).toList(),
    };
  }
}

/// Presence notification service provider (requires FCM and userId)
final presenceNotificationServiceProvider =
    Provider.family<PresenceNotificationService, String>((ref, userId) {
  final fcm = ref.watch(fcmNotificationServiceProvider);

  return PresenceNotificationService(
    fcm: fcm,
    currentUserId: userId,
  );
});

/// Watch and manage friend presence notifications (for use in UI)
final managedFriendPresenceNotificationsProvider =
    FutureProvider.family<void, String>((ref, userId) async {
  // This is typically initialized from your main app widget
  // Example usage:
  // ref.watch(managedFriendPresenceNotificationsProvider(userId));

  // In practice, you'd call the service's initialize() and updateFriendsList()
  // from your main app widget when the friend list changes

  return Future.value(null);
});




