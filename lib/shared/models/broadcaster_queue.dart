import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking broadcaster requests and queue
class BroadcasterQueue {
  final String id; // Document ID = userId
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'broadcasting', 'cancelled'
  final int queuePosition; // Position in queue
  final DateTime? approvedAt;
  final DateTime? broadcastStartedAt;
  final DateTime? broadcastEndedAt;

  const BroadcasterQueue({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.requestedAt,
    required this.status,
    required this.queuePosition,
    this.approvedAt,
    this.broadcastStartedAt,
    this.broadcastEndedAt,
  });

  factory BroadcasterQueue.fromJson(Map<String, dynamic> json) {
    final requestedAtValue = json['requestedAt'];
    final DateTime requestedAt = requestedAtValue is Timestamp
        ? requestedAtValue.toDate()
        : requestedAtValue is String
            ? DateTime.parse(requestedAtValue)
            : DateTime.now();

    final approvedAtValue = json['approvedAt'];
    final DateTime? approvedAt = approvedAtValue is Timestamp
        ? approvedAtValue.toDate()
        : approvedAtValue is String
            ? DateTime.parse(approvedAtValue)
            : null;

    final broadcastStartedAtValue = json['broadcastStartedAt'];
    final DateTime? broadcastStartedAt = broadcastStartedAtValue is Timestamp
        ? broadcastStartedAtValue.toDate()
        : broadcastStartedAtValue is String
            ? DateTime.parse(broadcastStartedAtValue)
            : null;

    final broadcastEndedAtValue = json['broadcastEndedAt'];
    final DateTime? broadcastEndedAt = broadcastEndedAtValue is Timestamp
        ? broadcastEndedAtValue.toDate()
        : broadcastEndedAtValue is String
            ? DateTime.parse(broadcastEndedAtValue)
            : null;

    return BroadcasterQueue(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      userPhotoUrl: json['userPhotoUrl'],
      requestedAt: requestedAt,
      status: json['status'] ?? 'pending',
      queuePosition: json['queuePosition'] ?? 0,
      approvedAt: approvedAt,
      broadcastStartedAt: broadcastStartedAt,
      broadcastEndedAt: broadcastEndedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
      'queuePosition': queuePosition,
      'approvedAt': approvedAt?.toIso8601String(),
      'broadcastStartedAt': broadcastStartedAt?.toIso8601String(),
      'broadcastEndedAt': broadcastEndedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status,
      'queuePosition': queuePosition,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'broadcastStartedAt': broadcastStartedAt != null
          ? Timestamp.fromDate(broadcastStartedAt!)
          : null,
      'broadcastEndedAt': broadcastEndedAt != null
          ? Timestamp.fromDate(broadcastEndedAt!)
          : null,
    };
  }

  /// Check if user is currently allowed to broadcast
  bool get isApproved => status == 'approved' || status == 'broadcasting';

  /// Check if broadcast is currently active
  bool get isBroadcasting => status == 'broadcasting';
}
