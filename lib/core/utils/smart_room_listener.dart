import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Manages active Firestore listeners to prevent excessive subscriptions
/// Only listens to rooms/data the user is actively using
class ActiveListenerManager {
  static final ActiveListenerManager _instance =
      ActiveListenerManager._internal();
  factory ActiveListenerManager() => _instance;
  ActiveListenerManager._internal();

  // Track active listeners: key = listener ID, value = unsubscribe function
  final Map<String, StreamSubscription> _activeListeners = {};
  final Map<String, String> _listenerMeta = {}; // For debugging

  /// Register a new listener
  void registerListener({
    required String listenerId,
    required StreamSubscription subscription,
    required String description,
  }) {
    _activeListeners[listenerId] = subscription;
    _listenerMeta[listenerId] = description;

    if (kDebugMode) {
      debugPrint('[ListenerManager] Registered: $listenerId - $description');
      debugPrint('[ListenerManager] Total active: ${_activeListeners.length}');
    }
  }

  /// Unregister a listener
  void unregisterListener(String listenerId) {
    final subscription = _activeListeners.remove(listenerId);
    _listenerMeta.remove(listenerId);

    if (subscription != null) {
      subscription.cancel();
      if (kDebugMode) {
        debugPrint('[ListenerManager] Unregistered: $listenerId');
        debugPrint(
            '[ListenerManager] Total active: ${_activeListeners.length}');
      }
    }
  }

  /// Unregister all listeners matching a pattern
  void unregisterPattern(String pattern) {
    final toRemove =
        _activeListeners.keys.where((id) => id.contains(pattern)).toList();

    for (final id in toRemove) {
      unregisterListener(id);
    }

    if (kDebugMode) {
      debugPrint(
          '[ListenerManager] Unregistered $pattern: removed ${toRemove.length} listeners');
    }
  }

  /// Get active listener count
  int get activeCount => _activeListeners.length;

  /// Get listener details
  List<String> getListenerDetails() {
    return _listenerMeta.entries.map((e) => '${e.key}: ${e.value}').toList();
  }

  /// Dispose all listeners
  void dispose() {
    for (final subscription in _activeListeners.values) {
      subscription.cancel();
    }
    _activeListeners.clear();
    _listenerMeta.clear();

    if (kDebugMode) {
      debugPrint('[ListenerManager] All listeners disposed');
    }
  }

  /// Debug info
  String get debugInfo {
    return 'Active listeners: ${_activeListeners.length}\n${getListenerDetails().join('\n')}';
  }
}

/// Smart room listener that automatically manages subscriptions
class SmartRoomListener {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActiveListenerManager _manager = ActiveListenerManager();

  // Track which rooms we're listening to
  final Set<String> _listeningRooms = {};

  /// Listen to a specific room (only if not already listening)
  StreamSubscription<DocumentSnapshot> listenToRoom(
    String roomId, {
    required Function(Map<String, dynamic>?) onUpdate,
  }) {
    // Skip if already listening - return dummy subscription
    if (_listeningRooms.contains(roomId)) {
      if (kDebugMode) {
        debugPrint('[SmartRoomListener] Already listening to room: $roomId');
      }
      // Return a dummy subscription that does nothing
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .take(0)
          .listen((_) {});
    }

    _listeningRooms.add(roomId);

    final subscription =
        _firestore.collection('rooms').doc(roomId).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          onUpdate(snapshot.data());
        }
      },
      onError: (error) {
        debugPrint(
            '[SmartRoomListener] Error listening to room $roomId: $error');
      },
    );

    // Register with manager
    _manager.registerListener(
      listenerId: 'room_$roomId',
      subscription: subscription,
      description: 'Room data: $roomId',
    );

    if (kDebugMode) {
      debugPrint('[SmartRoomListener] Started listening to room: $roomId');
    }

    return subscription;
  }

  /// Stop listening to a room
  void stopListeningToRoom(String roomId) {
    _listeningRooms.remove(roomId);
    _manager.unregisterListener('room_$roomId');

    if (kDebugMode) {
      debugPrint('[SmartRoomListener] Stopped listening to room: $roomId');
    }
  }

  /// Listen to room participants (only active room)
  StreamSubscription<QuerySnapshot> listenToParticipants(
    String roomId, {
    required Function(List<DocumentSnapshot>) onUpdate,
  }) {
    final subscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .snapshots()
        .listen(
      (snapshot) => onUpdate(snapshot.docs),
      onError: (error) {
        debugPrint(
            '[SmartRoomListener] Error listening to participants $roomId: $error');
      },
    );

    _manager.registerListener(
      listenerId: 'participants_$roomId',
      subscription: subscription,
      description: 'Participants: $roomId',
    );

    return subscription;
  }

  /// Stop listening to participants
  void stopListeningToParticipants(String roomId) {
    _manager.unregisterListener('participants_$roomId');
  }

  /// Clean up all listeners
  void dispose() {
    _listeningRooms.clear();
    _manager.dispose();
  }

  /// Get listener stats
  Map<String, dynamic> getStats() {
    return {
      'activeRooms': _listeningRooms.length,
      'totalListeners': _manager.activeCount,
      'rooms': _listeningRooms.toList(),
    };
  }
}
