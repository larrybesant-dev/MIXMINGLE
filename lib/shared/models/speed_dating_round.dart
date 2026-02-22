
import 'package:cloud_firestore/cloud_firestore.dart';

class SpeedDatingRound {
  final String id;
  final String eventId;
  final String hostId;
  final List<String> participants;
  final DateTime startTime;
  final int roundDurationMinutes;
  final int currentRound;
  final int totalRounds;
  final Map<String, List<String>> matches;
  final bool isActive;
  final DateTime createdAt;

  // Computed property for roundDuration (used in speed_dating_service)
  int get roundDuration => roundDurationMinutes;

  SpeedDatingRound({
    required this.id,
    required this.eventId,
    required this.hostId,
    required this.participants,
    required this.startTime,
    required this.roundDurationMinutes,
    required this.currentRound,
    required this.totalRounds,
    required this.matches,
    required this.isActive,
    required this.createdAt,
  });

  factory SpeedDatingRound.fromMap(Map<String, dynamic> map) {
    return SpeedDatingRound(
      id: map['id'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      hostId: map['hostId'] as String? ?? '',
      participants: (map['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      startTime: map['startTime'] != null
          ? (map['startTime'] is Timestamp
              ? (map['startTime'] as Timestamp).toDate()
              : DateTime.tryParse(map['startTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      roundDurationMinutes: map['roundDurationMinutes'] as int? ?? 5,
      currentRound: map['currentRound'] as int? ?? 1,
      totalRounds: map['totalRounds'] as int? ?? 3,
      matches: (map['matches'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as List<dynamic>?)?.cast<String>() ?? []),
          ) ??
          {},
      isActive: map['isActive'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Alias for fromMap to support JSON conversion
  factory SpeedDatingRound.fromJson(Map<String, dynamic> json) {
    return SpeedDatingRound.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'hostId': hostId,
      'participants': participants,
      'startTime': Timestamp.fromDate(startTime),
      'roundDurationMinutes': roundDurationMinutes,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'matches': matches,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SpeedDatingRound copyWith({
    String? id,
    String? eventId,
    String? hostId,
    List<String>? participants,
    DateTime? startTime,
    int? roundDurationMinutes,
    int? currentRound,
    int? totalRounds,
    Map<String, List<String>>? matches,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SpeedDatingRound(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      hostId: hostId ?? this.hostId,
      participants: participants ?? this.participants,
      startTime: startTime ?? this.startTime,
      roundDurationMinutes: roundDurationMinutes ?? this.roundDurationMinutes,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      matches: matches ?? this.matches,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeedDatingRound &&
        other.id == id &&
        other.eventId == eventId &&
        other.participants == participants &&
        other.startTime == startTime &&
        other.roundDurationMinutes == roundDurationMinutes &&
        other.currentRound == currentRound &&
        other.totalRounds == totalRounds &&
        other.matches == matches &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        participants.hashCode ^
        startTime.hashCode ^
        roundDurationMinutes.hashCode ^
        currentRound.hashCode ^
        totalRounds.hashCode ^
        matches.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'SpeedDatingRound(id: $id, eventId: $eventId, currentRound: $currentRound/$totalRounds, participants: ${participants.length}, isActive: $isActive)';
  }
}


