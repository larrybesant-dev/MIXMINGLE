import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/test_helpers.dart';

/// Phase 12: Social Graph Tests
/// Tests for follow/unfollow, friends, and social interactions

void main() {
  group('Social Graph Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    const String userId1 = 'user_1';
    const String userId2 = 'user_2';
    const String userId3 = 'user_3';

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();

      // Create test users
      await fakeFirestore.collection('users').doc(userId1).set(
            TestData.userProfile(uid: userId1, displayName: 'User 1'),
          );
      await fakeFirestore.collection('users').doc(userId2).set(
            TestData.userProfile(uid: userId2, displayName: 'User 2'),
          );
      await fakeFirestore.collection('users').doc(userId3).set(
            TestData.userProfile(uid: userId3, displayName: 'User 3'),
          );
    });

    group('Follow/Unfollow', () {
      test('should follow user', () async {
        // Act
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId2)
            .collection('followers')
            .doc(userId1)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Assert
        final followingDoc =
            await fakeFirestore.collection('users').doc(userId1).collection('following').doc(userId2).get();

        final followerDoc =
            await fakeFirestore.collection('users').doc(userId2).collection('followers').doc(userId1).get();

        expect(followingDoc.exists, isTrue);
        expect(followerDoc.exists, isTrue);
      });

      test('should unfollow user', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act
        await fakeFirestore.collection('users').doc(userId1).collection('following').doc(userId2).delete();

        await fakeFirestore.collection('users').doc(userId2).collection('followers').doc(userId1).delete();

        // Assert
        final followingDoc =
            await fakeFirestore.collection('users').doc(userId1).collection('following').doc(userId2).get();

        expect(followingDoc.exists, isFalse);
      });

      test('should get followers list', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('followers')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('followers')
            .doc(userId3)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act
        final snapshot = await fakeFirestore.collection('users').doc(userId1).collection('followers').get();

        // Assert
        expect(snapshot.docs.length, 2);
      });

      test('should get following list', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId3)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act
        final snapshot = await fakeFirestore.collection('users').doc(userId1).collection('following').get();

        // Assert
        expect(snapshot.docs.length, 2);
      });

      test('should count followers', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('followers')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('followers')
            .doc(userId3)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act
        final snapshot = await fakeFirestore.collection('users').doc(userId1).collection('followers').get();

        final count = snapshot.docs.length;

        // Assert
        expect(count, 2);
      });
    });

    group('Friends', () {
      test('should detect mutual follow (friendship)', () async {
        // Arrange - User 1 follows User 2
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // User 2 follows User 1
        await fakeFirestore
            .collection('users')
            .doc(userId2)
            .collection('following')
            .doc(userId1)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act - Check if both follow each other
        final user1FollowsUser2 =
            await fakeFirestore.collection('users').doc(userId1).collection('following').doc(userId2).get();

        final user2FollowsUser1 =
            await fakeFirestore.collection('users').doc(userId2).collection('following').doc(userId1).get();

        final areFriends = user1FollowsUser2.exists && user2FollowsUser1.exists;

        // Assert
        expect(areFriends, isTrue);
      });

      test('should get friends list', () async {
        // Arrange - Create mutual follows
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId2)
            .collection('following')
            .doc(userId1)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId3)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId3)
            .collection('following')
            .doc(userId1)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act - Get all following
        final followingSnapshot = await fakeFirestore.collection('users').doc(userId1).collection('following').get();

        // Check which are mutual
        final List<String> friends = [];
        for (final doc in followingSnapshot.docs) {
          final otherId = doc.id;
          final followsBack =
              await fakeFirestore.collection('users').doc(otherId).collection('following').doc(userId1).get();

          if (followsBack.exists) {
            friends.add(otherId);
          }
        }

        // Assert
        expect(friends.length, 2);
        expect(friends, contains(userId2));
        expect(friends, contains(userId3));
      });
    });

    group('Presence', () {
      test('should update online status', () async {
        // Act
        await fakeFirestore.collection('users').doc(userId1).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });

        // Assert
        final doc = await fakeFirestore.collection('users').doc(userId1).get();
        expect(doc.data()?['isOnline'], isTrue);
      });

      test('should update offline status', () async {
        // Act
        await fakeFirestore.collection('users').doc(userId1).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });

        // Assert
        final doc = await fakeFirestore.collection('users').doc(userId1).get();
        expect(doc.data()?['isOnline'], isFalse);
        expect(doc.data()?['lastSeen'], isNotNull);
      });

      test('should get online users', () async {
        // Arrange
        await fakeFirestore.collection('users').doc(userId1).update({'isOnline': true});
        await fakeFirestore.collection('users').doc(userId2).update({'isOnline': true});
        await fakeFirestore.collection('users').doc(userId3).update({'isOnline': false});

        // Act
        final snapshot = await fakeFirestore.collection('users').where('isOnline', isEqualTo: true).get();

        // Assert
        expect(snapshot.docs.length, 2);
      });
    });

    group('Block/Unblock', () {
      test('should block user', () async {
        // Act
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('blocked')
            .doc(userId2)
            .set({'blockedAt': FieldValue.serverTimestamp()});

        // Assert
        final doc = await fakeFirestore.collection('users').doc(userId1).collection('blocked').doc(userId2).get();

        expect(doc.exists, isTrue);
      });

      test('should unblock user', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('blocked')
            .doc(userId2)
            .set({'blockedAt': FieldValue.serverTimestamp()});

        // Act
        await fakeFirestore.collection('users').doc(userId1).collection('blocked').doc(userId2).delete();

        // Assert
        final doc = await fakeFirestore.collection('users').doc(userId1).collection('blocked').doc(userId2).get();

        expect(doc.exists, isFalse);
      });

      test('should check if user is blocked', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('blocked')
            .doc(userId2)
            .set({'blockedAt': FieldValue.serverTimestamp()});

        // Act
        final doc = await fakeFirestore.collection('users').doc(userId1).collection('blocked').doc(userId2).get();

        final isBlocked = doc.exists;

        // Assert
        expect(isBlocked, isTrue);
      });

      test('should remove follow relationships when blocking', () async {
        // Arrange - Create mutual follow
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('following')
            .doc(userId2)
            .set({'followedAt': FieldValue.serverTimestamp()});

        await fakeFirestore
            .collection('users')
            .doc(userId2)
            .collection('following')
            .doc(userId1)
            .set({'followedAt': FieldValue.serverTimestamp()});

        // Act - Block user
        await fakeFirestore
            .collection('users')
            .doc(userId1)
            .collection('blocked')
            .doc(userId2)
            .set({'blockedAt': FieldValue.serverTimestamp()});

        // Remove follow relationships
        await fakeFirestore.collection('users').doc(userId1).collection('following').doc(userId2).delete();

        await fakeFirestore.collection('users').doc(userId2).collection('following').doc(userId1).delete();

        // Assert
        final followingDoc =
            await fakeFirestore.collection('users').doc(userId1).collection('following').doc(userId2).get();

        expect(followingDoc.exists, isFalse);
      });
    });
  });
}
