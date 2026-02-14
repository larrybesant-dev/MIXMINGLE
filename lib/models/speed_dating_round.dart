import 'package:cloud_firestore/cloud_firestore.dart';

class SpeedDatingRound {
  final String id;
  final String eventId;
  final List<String> participants;
  final DateTime startTime;
  final int roundDurationMinutes;
  final int currentRound;
  final int totalRounds;
  final Map<String, List<String>> matches;
  final bool isActive;
  final DateTime createdAt;

  SpeedDatingRound({
    required this.id,
    required this.eventId,
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
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      participants: (map['participants'] as List<dynamic>).cast<String>(),
      startTime: (map['startTime'] as Timestamp).toDate(),
      roundDurationMinutes: map['roundDurationMinutes'] as int,
      currentRound: map['currentRound'] as int,
      totalRounds: map['totalRounds'] as int,
      matches: (map['matches'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
      isActive: map['isActive'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
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
}
