// lib/models/participant_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String uid;
  final String role; // 'host', 'coHost', 'guest'
  final bool isMuted;
  final bool isCameraOn;
  final DateTime joinedAt;
  final bool isScreenSharing;
  final bool isSpotlighted;
  final bool hasError;

  ParticipantModel({
    required this.uid,
    required this.role,
    required this.isMuted,
    required this.isCameraOn,
    required this.joinedAt,
    this.isScreenSharing = false,
    this.isSpotlighted = false,
    this.hasError = false,
  });

  factory ParticipantModel.fromMap(String uid, Map<String, dynamic> map) {
    return ParticipantModel(
      uid: uid,
      role: map['role'] ?? 'guest',
      isMuted: map['isMuted'] ?? false,
      isCameraOn: map['isCameraOn'] ?? true,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isScreenSharing: map['isScreenSharing'] ?? false,
      isSpotlighted: map['isSpotlighted'] ?? false,
      hasError: map['hasError'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'role': role,
    'isMuted': isMuted,
    'isCameraOn': isCameraOn,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isScreenSharing': isScreenSharing,
    'isSpotlighted': isSpotlighted,
    'hasError': hasError,
  };
}
