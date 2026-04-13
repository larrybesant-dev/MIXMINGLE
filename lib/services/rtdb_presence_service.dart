import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Manages per-session presence in Firebase Realtime Database.
///
/// RTDB is the ONLY Firebase product with a reliable server-side
/// `onDisconnect()` hook. We track one node per app session so a second
/// device does not clobber status for another active device.
///
/// Structure:
/// ```
///   /status/{userId}/sessions/{sessionId}
///     online:    bool
///     last_seen: timestamp (ms since epoch, set with ServerValue.timestamp)
///     in_room:   string|null
///     cam_on:    bool
///     mic_on:    bool
/// ```
class RtdbPresenceService {
  RtdbPresenceService(this._rtdb);

  final FirebaseDatabase _rtdb;
  String? _sessionId;

  DatabaseReference _userRef(String userId) => _rtdb.ref('status/$userId');

  DatabaseReference _sessionsRef(String userId) =>
      _userRef(userId).child('sessions');

  DatabaseReference _sessionRef(String userId) {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.trim().isEmpty) {
      throw StateError('RTDB presence session is not initialized. Call connect() first.');
    }
    return _sessionsRef(userId).child(sessionId);
  }

  String _buildSessionId() {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return 's_${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  Future<void> connect(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      _sessionId ??= _buildSessionId();
      final ref = _sessionRef(userId);
      final offlinePayload = {
        'online': false,
        'last_seen': ServerValue.timestamp,
        'in_room': null,
        'cam_on': false,
        'mic_on': false,
      };
      await ref.onDisconnect().set(offlinePayload);
      await ref.update({
        'online': true,
        'last_seen': ServerValue.timestamp,
        'session_id': _sessionId,
      });
    } catch (e, st) {
      debugPrint('[RTDB] connect error (non-fatal): $e\n$st');
    }
  }

  Future<void> heartbeat(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      await _sessionRef(userId).update({'last_seen': ServerValue.timestamp});
    } catch (_) {
      // Best-effort. Silently ignore if RTDB is unavailable.
    }
  }

  Future<void> setInRoom(String userId, String roomId) async {
    if (userId.trim().isEmpty) return;
    try {
      final ref = _sessionRef(userId);
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

  Future<void> clearInRoom(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      await _sessionRef(userId).update({
        'in_room': null,
        'cam_on': false,
        'mic_on': false,
      });
    } catch (e) {
      debugPrint('[RTDB] clearInRoom error (non-fatal): $e');
    }
  }

  Future<void> setCamOn(String userId, {required bool camOn}) async {
    if (userId.trim().isEmpty) return;
    try {
      await _sessionRef(userId).update({'cam_on': camOn});
    } catch (_) {}
  }

  Future<void> setMicOn(String userId, {required bool micOn}) async {
    if (userId.trim().isEmpty) return;
    try {
      await _sessionRef(userId).update({'mic_on': micOn});
    } catch (_) {}
  }

  Future<void> disconnect(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      final ref = _sessionRef(userId);
      await ref.onDisconnect().cancel();
      await ref.remove();
    } catch (e) {
      debugPrint('[RTDB] disconnect error (non-fatal): $e');
    } finally {
      _sessionId = null;
    }
  }

  Stream<bool> watchOnline(String userId) {
    if (userId.trim().isEmpty) return Stream.value(false);
    try {
      return _sessionsRef(userId).onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return false;
        for (final value in raw.values) {
          if (value is Map && value['online'] == true) {
            return true;
          }
        }
        return false;
      }).handleError((_) => false);
    } catch (_) {
      return Stream.value(false);
    }
  }

  Future<String?> getInRoom(String userId) async {
    if (userId.trim().isEmpty) return null;
    try {
      final snap = await _sessionsRef(userId).get();
      final raw = snap.value;
      if (raw is! Map) return null;
      for (final value in raw.values) {
        if (value is Map) {
          final inRoom = value['in_room'];
          if (inRoom is String && inRoom.trim().isNotEmpty) {
            return inRoom;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
