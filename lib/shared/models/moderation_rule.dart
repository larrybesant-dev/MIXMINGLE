import 'package:cloud_firestore/cloud_firestore.dart';

enum ModerationAction {
  warning, // Send warning
  mute, // Temporary mute
  shadowBan, // User can't see/chat
  kick, // Remove from room
  ban, // Permanent ban
}

class ModerationRule {
  final String ruleId;
  final List<String> keywords;
  final bool enabled;
  final int severity; // 1-5
  final ModerationAction action;
  final int? durationMinutes; // For temp mutes

  ModerationRule({
    required this.ruleId,
    required this.keywords,
    required this.enabled,
    required this.severity,
    required this.action,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'keywords': keywords,
        'enabled': enabled,
        'severity': severity,
        'action': action.name,
        'durationMinutes': durationMinutes,
      };

  factory ModerationRule.fromJson(Map<String, dynamic> json) => ModerationRule(
        ruleId: json['ruleId'] as String,
        keywords: List<String>.from(json['keywords'] as List<dynamic>),
        enabled: json['enabled'] as bool,
        severity: json['severity'] as int,
        action: ModerationAction.values.byName(json['action'] as String),
        durationMinutes: json['durationMinutes'] as int?,
      );
}

class ModerationLog {
  final String logId;
  final String roomId;
  final ModerationAction action;
  final String targetUserId;
  final String? targetUserName;
  final String moderatorId;
  final String? reason;
  final DateTime timestamp;
  final int? durationMinutes;

  ModerationLog({
    required this.logId,
    required this.roomId,
    required this.action,
    required this.targetUserId,
    this.targetUserName,
    required this.moderatorId,
    this.reason,
    required this.timestamp,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'logId': logId,
        'roomId': roomId,
        'action': action.name,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'moderatorId': moderatorId,
        'reason': reason,
        'timestamp': timestamp,
        'durationMinutes': durationMinutes,
      };

  factory ModerationLog.fromJson(Map<String, dynamic> json) => ModerationLog(
        logId: json['logId'] as String,
        roomId: json['roomId'] as String,
        action: ModerationAction.values.byName(json['action'] as String),
        targetUserId: json['targetUserId'] as String,
        targetUserName: json['targetUserName'] as String?,
        moderatorId: json['moderatorId'] as String,
        reason: json['reason'] as String?,
        timestamp:
            (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        durationMinutes: json['durationMinutes'] as int?,
      );
}
