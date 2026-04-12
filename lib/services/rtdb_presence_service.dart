import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Manages per-user presence in Firebase Realtime Database.
///
/// RTDB is the ONLY Firebase product with a reliable server-side
/// `onDisconnect()` hook — when a device drops its TCP connection (tab close,
/// network loss, app kill) Firebase automatically executes the queued write
/// within seconds.  Firestore has no equivalent.
///
/// Structure:
/// ```
///   /status/{userId}
///     online:    bool
///     last_seen: timestamp (ms since epoch, set with ServerValue.timestamp)
///     in_room:   string|null
///     cam_on:    bool
///     mic_on:    bool
/// ```
///
/// Usage:
///  1. Call [connect] once the user signs in.
///  2. Call [setInRoom] / [clearInRoom] on room join / leave.
///  3. Call [setCamOn] / [setMicOn] when the user toggles media.
///  4. Call [disconnect] on sign-out.
///
/// All methods silently swallow errors so a broken RTDB config (e.g. not yet
/// enabled in the Firebase Console) never crashes the app.
class RtdbPresenceService {
  RtdbPresenceService(this._rtdb);

  final FirebaseDatabase _rtdb;

  DatabaseReference _ref(String userId) =>
      _rtdb.ref('status/$userId');

  /// Mark the user online and register an [onDisconnect] write that fires
  /// automatically when the client loses its RTDB connection.
  Future<void> connect(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      final ref = _ref(userId);
      final offlinePayload = {
        'online': false,
        'last_seen': ServerValue.timestamp,
        'in_room': null,
        'cam_on': false,
        'mic_on': false,
      };
      // Register disconnect BEFORE setting online=true so there is no window
      // where the node is online but has no onDisconnect handler.
      await ref.onDisconnect().update(offlinePayload);
      await ref.update({
        'online': true,
        'last_seen': ServerValue.timestamp,
      });
    } catch (e, st) {
      debugPrint('[RTDB] connect error (non-fatal): $e\n$st');
    }
  }

  /// Heartbeat — update last_seen every N seconds so stale detection works
  /// even when the TCP connection stays open longer than normal.
  Future<void> heartbeat(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      await _ref(userId).update({'last_seen': ServerValue.timestamp});
    } catch (_) {
      // Best-effort. Silently ignore if RTDB is unavailable.
    }
  }

  /// Record that the user joined [roomId].
  Future<void> setInRoom(String userId, String roomId) async {
    if (userId.trim().isEmpty) return;
    try {
      final ref = _ref(userId);
      await ref.onDisconnect().update({
        'online': false,
        'last_seen': ServerValue.timestamp,
        'in_room': null,
        'cam_on': false,
        'mic_on': false,
      });
      await ref.update({'in_room': roomId});
    } catch (e) {
      debugPrint('[RTDB] setInRoom error (non-fatal): $e');
    }
  }

  /// Record that the user left their room.
  Future<void> clearInRoom(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      await _ref(userId).update({
        'in_room': null,
        'cam_on': false,
        'mic_on': false,
      });
    } catch (e) {
      debugPrint('[RTDB] clearInRoom error (non-fatal): $e');
    }
  }

  /// Sync camera state to RTDB so onDisconnect clears it automatically.
  Future<void> setCamOn(String userId, {required bool camOn}) async {
    if (userId.trim().isEmpty) return;
    try {
      await _ref(userId).update({'cam_on': camOn});
    } catch (_) {}
  }

  /// Sync mic state to RTDB so onDisconnect clears it automatically.
  Future<void> setMicOn(String userId, {required bool micOn}) async {
    if (userId.trim().isEmpty) return;
    try {
      await _ref(userId).update({'mic_on': micOn});
    } catch (_) {}
  }

  /// Mark the user offline and cancel any pending onDisconnect handlers.
  Future<void> disconnect(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      final ref = _ref(userId);
      await ref.onDisconnect().cancel();
      await ref.update({
        'online': false,
        'last_seen': ServerValue.timestamp,
        'in_room': null,
        'cam_on': false,
        'mic_on': false,
      });
    } catch (e) {
      debugPrint('[RTDB] disconnect error (non-fatal): $e');
    }
  }

  /// Stream the online flag for a single user from RTDB.
  /// Emits `false` on any error (RTDB unavailable / rules deny).
  Stream<bool> watchOnline(String userId) {
    if (userId.trim().isEmpty) return Stream.value(false);
    try {
      return _ref(userId)
          .child('online')
          .onValue
          .map((event) => (event.snapshot.value as bool?) ?? false)
          .handleError((_) => false);
    } catch (_) {
      return Stream.value(false);
    }
  }

  /// One-shot read of `in_room` for a user.
  Future<String?> getInRoom(String userId) async {
    if (userId.trim().isEmpty) return null;
    try {
      final snap = await _ref(userId).child('in_room').get();
      return snap.value as String?;
    } catch (_) {
      return null;
    }
  }
}
