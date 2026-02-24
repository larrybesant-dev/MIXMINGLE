import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/camera_permission.dart';

class CameraPermissionException implements Exception {
  final String message;
  CameraPermissionException(this.message);
  @override
  String toString() => message;
}

class CameraPermissionService {
  static final CameraPermissionService _instance = CameraPermissionService._internal();
  factory CameraPermissionService() => _instance;
  CameraPermissionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request permission to view another user's camera
  Future<String> requestCameraPermission({
    required String ownerId,
    String? channelId,
    Duration? duration,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw CameraPermissionException('User not authenticated');
    }

    if (currentUser.uid == ownerId) {
      throw CameraPermissionException('Cannot request permission from self');
    }

    try {
      // Check if there's already a pending or active request
      final existing = await _firestore
          .collection('camera_permissions')
          .where('requesterId', isEqualTo: currentUser.uid)
          .where('ownerId', isEqualTo: ownerId)
          .where('status', whereIn: ['pending', 'granted']).get();

      if (existing.docs.isNotEmpty) {
        final permission = CameraPermission.fromMap(existing.docs.first.data());
        if (permission.isActive) {
          throw CameraPermissionException('You already have an active permission');
        } else if (permission.status == CameraPermissionStatus.pending) {
          throw CameraPermissionException('Request already pending');
        }
      }

      // Create new permission request
      final permissionRef = _firestore.collection('camera_permissions').doc();
      final permission = CameraPermission(
        id: permissionRef.id,
        requesterId: currentUser.uid,
        ownerId: ownerId,
        status: CameraPermissionStatus.pending,
        requestedAt: DateTime.now(),
        channelId: channelId,
        expiresAt: duration != null ? DateTime.now().add(duration) : null,
      );

      await permissionRef.set(permission.toMap());

      // Create notification for owner
      await _createNotification(
        userId: ownerId,
        title: 'Camera Permission Request',
        body: '${currentUser.displayName ?? 'Someone'} wants to view your camera',
        data: {
          'type': 'camera_permission_request',
          'permissionId': permissionRef.id,
          'requesterId': currentUser.uid,
        },
      );

      debugPrint('âœ… Camera permission requested: ${currentUser.uid} -> $ownerId');
      return permissionRef.id;
    } catch (e) {
      debugPrint('âŒ Error requesting camera permission: $e');
      throw CameraPermissionException('Failed to request permission: $e');
    }
  }

  /// Grant camera permission
  Future<void> grantPermission(String permissionId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw CameraPermissionException('User not authenticated');
    }

    try {
      final permissionDoc = await _firestore.collection('camera_permissions').doc(permissionId).get();

      if (!permissionDoc.exists) {
        throw CameraPermissionException('Permission request not found');
      }

      final permission = CameraPermission.fromMap(permissionDoc.data()!);

      if (permission.ownerId != currentUser.uid) {
        throw CameraPermissionException('You can only grant your own permissions');
      }

      await permissionDoc.reference.update({
        'status': 'granted',
        'respondedAt': Timestamp.now(),
      });

      // Notify requester
      await _createNotification(
        userId: permission.requesterId,
        title: 'Camera Permission Granted',
        body: '${currentUser.displayName ?? 'User'} granted you camera access',
        data: {
          'type': 'camera_permission_granted',
          'permissionId': permissionId,
          'ownerId': currentUser.uid,
        },
      );

      debugPrint('âœ… Camera permission granted: $permissionId');
    } catch (e) {
      debugPrint('âŒ Error granting camera permission: $e');
      throw CameraPermissionException('Failed to grant permission: $e');
    }
  }

  /// Deny camera permission
  Future<void> denyPermission(String permissionId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw CameraPermissionException('User not authenticated');
    }

    try {
      final permissionDoc = await _firestore.collection('camera_permissions').doc(permissionId).get();

      if (!permissionDoc.exists) {
        throw CameraPermissionException('Permission request not found');
      }

      final permission = CameraPermission.fromMap(permissionDoc.data()!);

      if (permission.ownerId != currentUser.uid) {
        throw CameraPermissionException('You can only deny your own permissions');
      }

      await permissionDoc.reference.update({
        'status': 'denied',
        'respondedAt': Timestamp.now(),
      });

      debugPrint('âœ… Camera permission denied: $permissionId');
    } catch (e) {
      debugPrint('âŒ Error denying camera permission: $e');
      throw CameraPermissionException('Failed to deny permission: $e');
    }
  }

  /// Revoke granted permission
  Future<void> revokePermission(String permissionId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw CameraPermissionException('User not authenticated');
    }

    try {
      final permissionDoc = await _firestore.collection('camera_permissions').doc(permissionId).get();

      if (!permissionDoc.exists) {
        throw CameraPermissionException('Permission not found');
      }

      final permission = CameraPermission.fromMap(permissionDoc.data()!);

      if (permission.ownerId != currentUser.uid) {
        throw CameraPermissionException('You can only revoke your own permissions');
      }

      await permissionDoc.reference.update({
        'status': 'revoked',
        'respondedAt': Timestamp.now(),
      });

      // Notify requester
      await _createNotification(
        userId: permission.requesterId,
        title: 'Camera Permission Revoked',
        body: '${currentUser.displayName ?? 'User'} revoked your camera access',
        data: {
          'type': 'camera_permission_revoked',
          'permissionId': permissionId,
          'ownerId': currentUser.uid,
        },
      );

      debugPrint('âœ… Camera permission revoked: $permissionId');
    } catch (e) {
      debugPrint('âŒ Error revoking camera permission: $e');
      throw CameraPermissionException('Failed to revoke permission: $e');
    }
  }

  /// Check if user has permission to view camera
  Future<bool> hasPermission({
    required String ownerId,
    String? channelId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // User can always view their own camera
    if (currentUser.uid == ownerId) return true;

    try {
      var query = _firestore
          .collection('camera_permissions')
          .where('requesterId', isEqualTo: currentUser.uid)
          .where('ownerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'granted');

      // If channelId provided, filter by it
      if (channelId != null) {
        query = query.where('channelId', isEqualTo: channelId);
      }

      final permissions = await query.get();

      for (var doc in permissions.docs) {
        final permission = CameraPermission.fromMap(doc.data());
        if (permission.isActive) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('âŒ Error checking camera permission: $e');
      return false;
    }
  }

  /// Get pending permission requests for current user
  Stream<List<CameraPermission>> getPendingRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('camera_permissions')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CameraPermission.fromMap(doc.data())).toList());
  }

  /// Get granted permissions for current user (permissions they've given)
  Stream<List<CameraPermission>> getGrantedPermissions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('camera_permissions')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'granted')
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CameraPermission.fromMap(doc.data())).where((p) => p.isActive).toList());
  }

  /// Get my permissions (permissions I have to view others' cameras)
  Stream<List<CameraPermission>> getMyPermissions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('camera_permissions')
        .where('requesterId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'granted')
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CameraPermission.fromMap(doc.data())).where((p) => p.isActive).toList());
  }

  /// Create notification helper
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': Timestamp.now(),
        'read': false,
      });
    } catch (e) {
      debugPrint('âŒ Error creating notification: $e');
    }
  }
}
