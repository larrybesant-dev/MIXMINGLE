// lib/core/services/room_permission_service.dart
//
// Single source of truth for "can this user moderate this room?"
//
// Permission hierarchy (highest wins):
//   1. SuperAdmin  — global override (role == 'superadmin' in users/{uid})
//   2. Owner       — rooms/{roomId}.ownerId == uid
//   3. Room Admin  — rooms/{roomId}.admins contains uid
//
// Usage:
//   final ok = await RoomPermissionService().canModerate(roomId);
//   final ok = await RoomPermissionService().canModerate(roomId, userId: otherUid);

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomPermissionService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Core check ──────────────────────────────────────────────────────────────

  /// Returns `true` if [uid] (defaults to current user) can moderate [roomId].
  Future<bool> canModerate(String roomId, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return false;

    // 1. SuperAdmin check (Firestore role field)
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.data()?['role'] == 'superadmin') return true;

    // 2. Room owner / admin check
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) return false;

    final data = roomDoc.data()!;
    final ownerId = (data['ownerId'] ?? data['hostId'] ?? '') as String;
    final admins = List<String>.from(data['admins'] ?? []);

    return uid == ownerId || admins.contains(uid);
  }

  /// Returns `true` if [uid] is the room owner.
  Future<bool> isOwner(String roomId, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    return uid == (data['ownerId'] ?? data['hostId'] ?? '');
  }

  // ── Admin list management ────────────────────────────────────────────────────

  /// Promotes [targetUid] to room admin. Caller must already have moderation rights.
  Future<void> addRoomAdmin(String roomId, String targetUid) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'admins': FieldValue.arrayUnion([targetUid]),
    });
    await _writeModerationLog(
      roomId: roomId,
      action: 'admin_added',
      targetUserId: targetUid,
    );
  }

  /// Removes [targetUid] from room admins.
  Future<void> removeRoomAdmin(String roomId, String targetUid) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'admins': FieldValue.arrayRemove([targetUid]),
    });
    await _writeModerationLog(
      roomId: roomId,
      action: 'admin_removed',
      targetUserId: targetUid,
    );
  }

  // ── Logging ──────────────────────────────────────────────────────────────────

  Future<void> _writeModerationLog({
    required String roomId,
    required String action,
    required String targetUserId,
    String? reason,
  }) async {
    final performedBy = _auth.currentUser?.uid ?? 'system';
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('moderation_logs')
        .add({
      'action': action,
      'performedBy': performedBy,
      'targetUser': targetUserId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

// ── Riverpod providers ────────────────────────────────────────────────────────

final roomPermissionServiceProvider = Provider<RoomPermissionService>(
  (_) => RoomPermissionService(),
);

/// `AsyncValue<bool>` — true when the current user can moderate [roomId].
/// Auto-disposes when the room screen is closed.
final canModerateProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, roomId) {
  return ref.read(roomPermissionServiceProvider).canModerate(roomId);
});
