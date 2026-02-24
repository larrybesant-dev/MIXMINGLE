import 'package:cloud_firestore/cloud_firestore.dart';
import './report.dart';

/// Read receipt for messages
class ReadReceipt {
  final String messageId;
  final String userId;
  final DateTime readAt;

  ReadReceipt({
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  factory ReadReceipt.fromMap(Map<String, dynamic> map) {
    return ReadReceipt(
      messageId: map['messageId'] ?? '',
      userId: map['userId'] ?? '',
      readAt: (map['readAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'userId': userId,
      'readAt': Timestamp.fromDate(readAt),
    };
  }
}

/// User blocking model
class UserBlock {
  final String blockerId;
  final String blockedUserId;
  final DateTime blockedAt;
  final String? reason;

  UserBlock({
    required this.blockerId,
    required this.blockedUserId,
    required this.blockedAt,
    this.reason,
  });

  factory UserBlock.fromMap(Map<String, dynamic> map) {
    return UserBlock(
      blockerId: map['blockerId'] ?? '',
      blockedUserId: map['blockedUserId'] ?? '',
      blockedAt: (map['blockedAt'] as Timestamp).toDate(),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'blockedAt': Timestamp.fromDate(blockedAt),
      'reason': reason,
    };
  }
}

/// User report model
class UserReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? reportedMessageId;
  final String? reportedRoomId;
  final ReportType type;
  final String description;
  final DateTime createdAt;
  final String status; // pending, reviewed, resolved
  final String? reviewedBy;
  final DateTime? reviewedAt;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.reportedMessageId,
    this.reportedRoomId,
    required this.type,
    required this.description,
    required this.createdAt,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
  });

  factory UserReport.fromMap(Map<String, dynamic> map) {
    return UserReport(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reportedMessageId: map['reportedMessageId'],
      reportedRoomId: map['reportedRoomId'],
      type: ReportType.values.firstWhere(
        (e) => e.toString() == 'ReportType.${map['type']}',
        orElse: () => ReportType.other,
      ),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedMessageId': reportedMessageId,
      'reportedRoomId': reportedRoomId,
      'type': type.toString().split('.').last,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}

/// Room category model
class RoomCategory {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int roomCount;
  final List<String> popularTags;

  const RoomCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.roomCount,
    required this.popularTags,
  });

  factory RoomCategory.fromMap(Map<String, dynamic> map) {
    return RoomCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      roomCount: map['roomCount'] ?? 0,
      popularTags: List<String>.from(map['popularTags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'roomCount': roomCount,
      'popularTags': popularTags,
    };
  }
}
