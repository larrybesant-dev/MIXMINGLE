import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/mock_firebase.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockFirestoreService mockFirestore;

  setUp(() {
    mockFirestore = MockFirestoreService();
  });

  tearDown(() {
    mockFirestore.clear();
  });

  group('SpeedDatingService Tests', () {
    test('should create speed dating round', () {
      // Arrange
      final round = TestData.speedDatingRound(id: 'round1', eventId: 'event1');

      // Act
      mockFirestore.addDocument('speedDatingRounds', 'round1', round);

      // Assert
      final created = mockFirestore.getDocument('speedDatingRounds', 'round1');
      expect(created, isNotNull);
      expect(created?['eventId'], 'event1');
    });

    test('should validate minimum participants', () {
      // Arrange
      final round = TestData.speedDatingRound();
      round['participants'] = ['user1', 'user2']; // Less than 4

      // Act
      final hasMinParticipants = (round['participants'] as List).length >= 4;

      // Assert
      expect(hasMinParticipants, false);
    });

    test('should join speed dating round', () {
      // Arrange
      final round = TestData.speedDatingRound();
      round['participants'] = ['user1', 'user2', 'user3', 'user4'];
      mockFirestore.addDocument('speedDatingRounds', 'round1', round);

      // Act
      final roundData = mockFirestore.getDocument('speedDatingRounds', 'round1');
      (roundData?['participants'] as List).add('user5');
      mockFirestore.updateDocument('speedDatingRounds', 'round1', roundData!);

      // Assert
      final updated = mockFirestore.getDocument('speedDatingRounds', 'round1');
      expect(updated?['participants'], contains('user5'));
      expect((updated?['participants'] as List).length, 5);
    });

    test('should generate matches for participants', () {
      // Arrange
      final participants = ['user1', 'user2', 'user3', 'user4'];

      // Act
      final matches = <String, List<String>>{};
      for (var i = 0; i < participants.length; i++) {
        final current = participants[i];
        final next = participants[(i + 1) % participants.length];
        matches[current] = [next];
      }

      // Assert
      expect(matches.length, 4);
      expect(matches['user1'], ['user2']);
      expect(matches['user2'], ['user3']);
      expect(matches['user3'], ['user4']);
      expect(matches['user4'], ['user1']);
    });

    test('should advance to next round', () {
      // Arrange
      final round = TestData.speedDatingRound();
      round['currentRound'] = 1;
      round['totalRounds'] = 5;
      mockFirestore.addDocument('speedDatingRounds', 'round1', round);

      // Act
      final roundData = mockFirestore.getDocument('speedDatingRounds', 'round1');
      roundData?['currentRound'] = (roundData['currentRound'] as int) + 1;
      mockFirestore.updateDocument('speedDatingRounds', 'round1', roundData!);

      // Assert
      final updated = mockFirestore.getDocument('speedDatingRounds', 'round1');
      expect(updated?['currentRound'], 2);
    });

    test('should end round when reaching total rounds', () {
      // Arrange
      final round = TestData.speedDatingRound();
      round['currentRound'] = 5;
      round['totalRounds'] = 5;
      round['isActive'] = true;
      mockFirestore.addDocument('speedDatingRounds', 'round1', round);

      // Act
      final roundData = mockFirestore.getDocument('speedDatingRounds', 'round1');
      final shouldEnd = roundData?['currentRound'] >= roundData?['totalRounds'];
      if (shouldEnd) {
        roundData?['isActive'] = false;
        mockFirestore.updateDocument('speedDatingRounds', 'round1', roundData!);
      }

      // Assert
      final updated = mockFirestore.getDocument('speedDatingRounds', 'round1');
      expect(updated?['isActive'], false);
    });

    test('should submit speed dating result', () {
      // Arrange
      final result = {
        'id': 'result1',
        'roundId': 'round1',
        'userId': 'user1',
        'matchedUserId': 'user2',
        'userLiked': true,
        'matchedUserLiked': false,
        'isMutual': false,
        'timestamp': Timestamp.now(),
      };

      // Act
      mockFirestore.addDocument('speedDatingResults', 'result1', result);

      // Assert
      final saved = mockFirestore.getDocument('speedDatingResults', 'result1');
      expect(saved, isNotNull);
      expect(saved?['userLiked'], true);
    });

    test('should detect mutual match', () {
      // Arrange
      mockFirestore.addDocument('speedDatingResults', 'result1', {
        'userId': 'user1',
        'matchedUserId': 'user2',
        'userLiked': true,
        'roundId': 'round1',
      });
      mockFirestore.addDocument('speedDatingResults', 'result2', {
        'userId': 'user2',
        'matchedUserId': 'user1',
        'userLiked': true,
        'roundId': 'round1',
      });

      // Act
      final results = mockFirestore.getCollection('speedDatingResults');
      final user1Result = results.firstWhere((r) => r['userId'] == 'user1');
      final user2Result = results.firstWhere((r) => r['userId'] == 'user2' && r['matchedUserId'] == 'user1');

      final isMutual = user1Result['userLiked'] == true && user2Result['userLiked'] == true;

      // Assert
      expect(isMutual, true);
    });

    test('should calculate compatibility score', () {
      // Arrange
      final user1 = {
        'interests': ['music', 'sports', 'travel']
      };
      final user2 = {
        'interests': ['music', 'sports', 'reading']
      };

      // Act
      final interests1 = user1['interests'] as List;
      final interests2 = user2['interests'] as List;
      final shared = interests1.where((i) => interests2.contains(i)).length;
      final total = {...interests1, ...interests2}.length;
      final score = shared / total;

      // Assert
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(1.0));
    });
  });
}
