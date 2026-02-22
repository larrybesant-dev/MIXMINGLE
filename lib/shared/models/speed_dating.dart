
import 'package:cloud_firestore/cloud_firestore.dart';

enum SpeedDatingStatus {
  waiting,
  active,
  matched,
  inProgress,
  completed,
  cancelled,
}

enum SpeedDatingDecision {
  like,
  pass,
  pending,
}

class SpeedDatingSession {
  final String id;
  final String userId1;
  final String userId2;
  final String roomId;
  final SpeedDatingStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final SpeedDatingDecision user1Decision;
  final SpeedDatingDecision user2Decision;
  final bool isMatch;

  SpeedDatingSession({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.roomId,
    this.status = SpeedDatingStatus.waiting,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.durationMinutes = 10,
    this.user1Decision = SpeedDatingDecision.pending,
    this.user2Decision = SpeedDatingDecision.pending,
    this.isMatch = false,
  });

  // Backward compatibility getter
  List<String> get participants => [userId1, userId2];

  factory SpeedDatingSession.fromMap(Map<String, dynamic> map) {
    return SpeedDatingSession(
      id: map['id'] ?? '',
      userId1: map['userId1'] ?? '',
      userId2: map['userId2'] ?? '',
      roomId: map['roomId'] ?? '',
      status: SpeedDatingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SpeedDatingStatus.waiting,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      durationMinutes: map['durationMinutes'] ?? 10,
      user1Decision: SpeedDatingDecision.values.firstWhere(
        (e) => e.name == map['user1Decision'],
        orElse: () => SpeedDatingDecision.pending,
      ),
      user2Decision: SpeedDatingDecision.values.firstWhere(
        (e) => e.name == map['user2Decision'],
        orElse: () => SpeedDatingDecision.pending,
      ),
      isMatch: map['isMatch'] ?? false,
    );
  }

  factory SpeedDatingSession.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return SpeedDatingSession.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'roomId': roomId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'durationMinutes': durationMinutes,
      'user1Decision': user1Decision.name,
      'user2Decision': user2Decision.name,
      'isMatch': isMatch,
    };
  }

  SpeedDatingSession copyWith({
    String? id,
    String? userId1,
    String? userId2,
    String? roomId,
    SpeedDatingStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    SpeedDatingDecision? user1Decision,
    SpeedDatingDecision? user2Decision,
    bool? isMatch,
  }) {
    return SpeedDatingSession(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      user1Decision: user1Decision ?? this.user1Decision,
      user2Decision: user2Decision ?? this.user2Decision,
      isMatch: isMatch ?? this.isMatch,
    );
  }

  bool involvesUser(String userId) {
    return userId1 == userId || userId2 == userId;
  }

  SpeedDatingDecision getDecisionForUser(String userId) {
    if (userId == userId1) return user1Decision;
    if (userId == userId2) return user2Decision;
    return SpeedDatingDecision.pending;
  }

  String getOtherUserId(String userId) {
    if (userId == userId1) return userId2;
    if (userId == userId2) return userId1;
    return '';
  }
}

class SpeedDatingMatch {
  final String id;
  final String userId1;
  final String userId2;
  final String sessionId;
  final DateTime matchedAt;
  final bool isActive;

  SpeedDatingMatch({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.sessionId,
    required this.matchedAt,
    this.isActive = true,
  });

  factory SpeedDatingMatch.fromMap(Map<String, dynamic> map) {
    return SpeedDatingMatch(
      id: map['id'] ?? '',
      userId1: map['userId1'] ?? '',
      userId2: map['userId2'] ?? '',
      sessionId: map['sessionId'] ?? '',
      matchedAt: (map['matchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  factory SpeedDatingMatch.fromDocument(DocumentSnapshot doc) {
    return SpeedDatingMatch.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'sessionId': sessionId,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'isActive': isActive,
    };
  }

  bool involvesUser(String userId) {
    return userId1 == userId || userId2 == userId;
  }

  String getOtherUserId(String userId) {
    if (userId == userId1) return userId2;
    if (userId == userId2) return userId1;
    return '';
  }
}


