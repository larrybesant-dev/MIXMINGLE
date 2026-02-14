import 'package:cloud_firestore/cloud_firestore.dart';

enum ModerationType {
  kick,
  ban,
  tempBan,
  shadowBan,
  timeout,
  unmute,
  warn,
  lockdown,
  unlock,
}

enum BanDuration {
  fiveMinutes,
  oneHour,
  twentyFourHours,
  permanent,
}

class ModerationAction {
  final String id;
  final String roomId;
  final ModerationType type;
  final String targetUserId;
  final String targetUserName;
  final String moderatorId;
  final String moderatorName;
  final String reason;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final bool isAutoModerated;
  final Map<String, dynamic>? metadata;

  const ModerationAction({
    required this.id,
    required this.roomId,
    required this.type,
    required this.targetUserId,
    required this.targetUserName,
    required this.moderatorId,
    required this.moderatorName,
    required this.reason,
    required this.timestamp,
    this.expiresAt,
    this.isAutoModerated = false,
    this.metadata,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => expiresAt == null || !isExpired;

  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    if (isExpired) return Duration.zero;
    return expiresAt!.difference(DateTime.now());
  }

  factory ModerationAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationAction(
      id: doc.id,
      roomId: data['roomId'] as String,
      type: ModerationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ModerationType.warn,
      ),
      targetUserId: data['targetUserId'] as String,
      targetUserName: data['targetUserName'] as String? ?? 'Unknown',
      moderatorId: data['moderatorId'] as String,
      moderatorName: data['moderatorName'] as String? ?? 'Unknown',
      reason: data['reason'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      isAutoModerated: data['isAutoModerated'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'type': type.name,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isAutoModerated': isAutoModerated,
      'metadata': metadata,
    };
  }

  static DateTime getExpiryTime(BanDuration duration) {
    final now = DateTime.now();
    switch (duration) {
      case BanDuration.fiveMinutes:
        return now.add(const Duration(minutes: 5));
      case BanDuration.oneHour:
        return now.add(const Duration(hours: 1));
      case BanDuration.twentyFourHours:
        return now.add(const Duration(hours: 24));
      case BanDuration.permanent:
        return now.add(const Duration(days: 36500)); // 100 years
    }
  }

  static String formatDuration(BanDuration duration) {
    switch (duration) {
      case BanDuration.fiveMinutes:
        return '5 minutes';
      case BanDuration.oneHour:
        return '1 hour';
      case BanDuration.twentyFourHours:
        return '24 hours';
      case BanDuration.permanent:
        return 'Permanent';
    }
  }
}
