enum ReportTargetType {
  user,
  room,
  message,
  cam,
}

enum ModerationStatus {
  open,
  reviewing,
  actioned,
  dismissed,
}

class BlockRecordModel {
  const BlockRecordModel({
    required this.id,
    required this.blockerUserId,
    required this.blockedUserId,
    this.createdAt,
  });

  final String id;
  final String blockerUserId;
  final String blockedUserId;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockerUserId': blockerUserId,
      'blockedUserId': blockedUserId,
      'createdAt': createdAt?.toIso8601String(),
      'participantIds': [blockerUserId, blockedUserId],
    };
  }

  factory BlockRecordModel.fromJson(Map<String, dynamic> json) {
    return BlockRecordModel(
      id: json['id'] as String? ?? '',
      blockerUserId: json['blockerUserId'] as String? ?? '',
      blockedUserId: json['blockedUserId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class ReportRecordModel {
  const ReportRecordModel({
    required this.id,
    required this.reporterUserId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.details,
    this.status = ModerationStatus.open,
    this.createdAt,
  });

  final String id;
  final String reporterUserId;
  final String targetId;
  final ReportTargetType targetType;
  final String reason;
  final String? details;
  final ModerationStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterUserId': reporterUserId,
      'targetId': targetId,
      'targetType': targetType.name,
      'reason': reason,
      'details': details,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ReportRecordModel.fromJson(Map<String, dynamic> json) {
    return ReportRecordModel(
      id: json['id'] as String? ?? '',
      reporterUserId: json['reporterUserId'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      targetType: ReportTargetType.values.firstWhere(
        (value) => value.name == json['targetType'],
        orElse: () => ReportTargetType.user,
      ),
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String?,
      status: ModerationStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ModerationStatus.open,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}