// lib/core/services/role_service.dart
//
// Reads and writes the `role` field on a user's Firestore document.
// Global roles: "user" | "admin" | "superadmin"
//
// Usage:
//   final role = await RoleService().getUserRole();
//   await RoleService().setUserRole(targetUid, 'admin'); // superadmin only

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents the global role assigned to a user.
enum UserRole {
  user('user'),
  admin('admin'),
  superadmin('superadmin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

class RoleService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Returns the [UserRole] of the currently signed-in user.
  Future<UserRole> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return UserRole.user;
    return getUserRole(uid);
  }

  /// Returns the [UserRole] for any user by UID.
  Future<UserRole> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final raw = doc.data()?['role'] as String?;
    return UserRole.fromString(raw);
  }

  /// Stream of the current user's role, live-updating.
  Stream<UserRole> currentUserRoleStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(UserRole.user);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserRole.fromString(doc.data()?['role'] as String?));
  }

  // ── Write (superadmin-only; enforced by Firestore rules) ────────────────────

  /// Assigns a global role to a user. Caller must be a superadmin.
  Future<void> setUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.value,
      'roleUpdatedAt': FieldValue.serverTimestamp(),
      'roleUpdatedBy': _auth.currentUser?.uid,
    });
  }
}
