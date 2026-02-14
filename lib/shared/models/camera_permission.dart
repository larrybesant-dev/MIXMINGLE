import 'package:cloud_firestore/cloud_firestore.dart';

enum CameraPermissionStatus {
  pending,
  granted,
  denied,
  revoked,
}

class CameraPermission {
  final String id;
  final String requesterId; // User requesting to view
  final String ownerId; // User who owns the camera
  final CameraPermissionStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? channelId; // Optional: limit to specific channel
  final DateTime? expiresAt; // Optional: temporary permission

  CameraPermission({
    required this.id,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
    this.channelId,
    this.expiresAt,
  });

  factory CameraPermission.fromMap(Map<String, dynamic> map) {
    return CameraPermission(
      id: map['id'] as String,
      requesterId: map['requesterId'] as String,
      ownerId: map['ownerId'] as String,
      status: CameraPermissionStatus.values.firstWhere(
        (e) => e.toString() == 'CameraPermissionStatus.${map['status']}',
        orElse: () => CameraPermissionStatus.pending,
      ),
      requestedAt: map['requestedAt'] != null
          ? (map['requestedAt'] is Timestamp
              ? (map['requestedAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['requestedAt'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] is Timestamp
              ? (map['respondedAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['respondedAt'].toString()))
          : null,
      channelId: map['channelId'] as String?,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] is Timestamp
              ? (map['expiresAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['expiresAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'status': status.toString().split('.').last,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'channelId': channelId,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => status == CameraPermissionStatus.granted && !isExpired;
}
