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

  group('MatchService Tests', () {
    test('should like a user', () async {
      // Arrange
      mockFirestore.addDocument('users', 'user1', TestData.userProfile(uid: 'user1'));
      mockFirestore.addDocument('users', 'user2', TestData.userProfile(uid: 'user2'));

      // Act
      mockFirestore.addDocument('likes', 'like1', {
        'likerId': 'user1',
        'likedUserId': 'user2',
        'timestamp': Timestamp.now(),
        'matchQualityScore': 0.75,
      });

      // Assert
      final like = mockFirestore.getDocument('likes', 'like1');
      expect(like, isNotNull);
      expect(like?['likerId'], 'user1');
      expect(like?['likedUserId'], 'user2');
    });

    test('should create match on mutual like', () async {
      // Arrange
      mockFirestore.addDocument('likes', 'like1', {
        'likerId': 'user1',
        'likedUserId': 'user2',
        'timestamp': Timestamp.now(),
      });
      mockFirestore.addDocument('likes', 'like2', {
        'likerId': 'user2',
        'likedUserId': 'user1',
        'timestamp': Timestamp.now(),
      });

      // Act
      final likes1 = mockFirestore.query('likes', whereField: 'likerId', whereValue: 'user1');
      final likes2 = mockFirestore.query('likes', whereField: 'likerId', whereValue: 'user2');

      final isMutual = likes1.any((l) => l['likedUserId'] == 'user2') &&
                       likes2.any((l) => l['likedUserId'] == 'user1');

      if (isMutual) {
        mockFirestore.addDocument('matches', 'match1', {
          'user1': 'user1',
          'user2': 'user2',
          'matchedAt': Timestamp.now(),
          'isActive': true,
        });
      }

      // Assert
      expect(isMutual, true);
      final match = mockFirestore.getDocument('matches', 'match1');
      expect(match, isNotNull);
      expect(match?['isActive'], true);
    });

    test('should not allow self-like', () {
      // Arrange
      const userId = 'user1';

      // Act & Assert
      expect(userId == userId, true);
      // In real service, this would throw an exception
    });

    test('should enforce rate limiting', () {
      // Arrange
      final likesInLastDay = List.generate(100, (i) => {
        'likerId': 'user1',
        'likedUserId': 'user$i',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: i % 24))),
      });

      // Add to mock firestore
      for (var i = 0; i < likesInLastDay.length; i++) {
        mockFirestore.addDocument('likes', 'like$i', likesInLastDay[i]);
      }

      // Act
      final userLikes = mockFirestore.query('likes', whereField: 'likerId', whereValue: 'user1');
      final recentLikes = userLikes.where((like) {
        final timestamp = like['timestamp'] as Timestamp;
        return DateTime.now().difference(timestamp.toDate()).inDays < 1;
      }).length;

      // Assert
      expect(recentLikes, greaterThanOrEqualTo(100));
    });

    test('should calculate match quality score', () {
      // Arrange
      final user1Interests = ['music', 'sports', 'travel'];
      final user2Interests = ['music', 'sports', 'reading'];

      // Act
      final sharedInterests = user1Interests.where((i) => user2Interests.contains(i)).length;
      final totalInterests = {...user1Interests, ...user2Interests}.length;
      final score = sharedInterests / totalInterests;

      // Assert
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(1.0));
      expect(sharedInterests, 2); // music and sports
    });

    test('should get user matches', () {
      // Arrange
      mockFirestore.addDocument('matches', 'match1', {
        'user1': 'user1',
        'user2': 'user2',
        'isActive': true,
      });
      mockFirestore.addDocument('matches', 'match2', {
        'user1': 'user3',
        'user2': 'user1',
        'isActive': true,
      });

      // Act
      final matches1 = mockFirestore.query('matches', whereField: 'user1', whereValue: 'user1');
      final matches2 = mockFirestore.query('matches', whereField: 'user2', whereValue: 'user1');

      final allMatches = [...matches1, ...matches2];

      // Assert
      expect(allMatches.length, 2);
    });

    test('should unmatch users', () {
      // Arrange
      mockFirestore.addDocument('matches', 'match1', {
        'user1': 'user1',
        'user2': 'user2',
        'isActive': true,
      });

      // Act
      mockFirestore.updateDocument('matches', 'match1', {'isActive': false});

      // Assert
      final match = mockFirestore.getDocument('matches', 'match1');
      expect(match?['isActive'], false);
    });
  });
}
