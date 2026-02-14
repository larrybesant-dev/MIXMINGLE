import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/shared/models/speed_dating_round.dart';

void main() {
  group('SpeedDatingRound', () {
    test('fromMap populates fields with sensible defaults', () {
      final map = {
        'id': 'round123',
        'eventId': 'event123',
        'hostId': 'host123',
        'isActive': true,
        'currentRound': 2,
        'totalRounds': 5,
        'roundDurationMinutes': 7,
        'participants': ['user1', 'user2'],
        'matches': {
          'user1': ['user2'],
        },
        'startTime': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      };

      final round = SpeedDatingRound.fromMap(map);

      expect(round.id, 'round123');
      expect(round.eventId, 'event123');
      expect(round.hostId, 'host123');
      expect(round.roundDurationMinutes, 7);
      expect(round.roundDuration, 7);
      expect(round.currentRound, 2);
      expect(round.totalRounds, 5);
      expect(round.participants, ['user1', 'user2']);
      expect(round.matches['user1'], ['user2']);
      expect(round.startTime, DateTime(2024, 1, 1));
      expect(round.createdAt, DateTime(2024, 1, 2));
    });

    test('toMap emits firestore-friendly types', () {
      final round = SpeedDatingRound(
        id: 'round999',
        eventId: 'event999',
        hostId: 'host1',
        participants: const ['a', 'b'],
        startTime: DateTime(2024, 2, 2),
        roundDurationMinutes: 10,
        currentRound: 1,
        totalRounds: 3,
        matches: const {
          'a': ['b']
        },
        isActive: false,
        createdAt: DateTime(2024, 2, 3),
      );

      final map = round.toMap();

      expect(map['id'], 'round999');
      expect(map['eventId'], 'event999');
      expect(map['roundDurationMinutes'], 10);
      expect(map['participants'], ['a', 'b']);
      expect(map['matches'], {
        'a': ['b']
      });
      expect(map['startTime'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('copyWith updates fields while keeping originals', () {
      final round = SpeedDatingRound(
        id: 'round1',
        eventId: 'event1',
        hostId: 'host1',
        participants: const ['a'],
        startTime: DateTime(2024, 3, 1),
        roundDurationMinutes: 5,
        currentRound: 1,
        totalRounds: 3,
        matches: const {},
        isActive: true,
        createdAt: DateTime(2024, 3, 2),
      );

      final updated = round.copyWith(currentRound: 2, matches: {
        'a': ['b']
      });

      expect(updated.currentRound, 2);
      expect(updated.matches['a'], ['b']);
      expect(updated.id, 'round1');
      expect(updated.eventId, 'event1');
    });
  });
}
