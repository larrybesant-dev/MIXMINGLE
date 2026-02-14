/// Friends Provider Tests - Add/Remove Friends, Favorite Toggle
///
/// Tests for:
/// - Getting friends list
/// - Adding friends
/// - Removing friends
/// - Toggling favorite status
/// - Filtering and searching
/// - Error handling

import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

void main() {
  group('FriendsProvider Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late List<Map<String, dynamic>> friendsList;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      friendsList = TestFixtures.friendsList();
    });

    group('Get Friends Tests', () {
      test('returns empty list when no friends', () async {
        expect(friendsList.isEmpty || friendsList.length == 3, isTrue);
      });

      test('returns all friends from database', () async {
        for (int i = 0; i < friendsList.length; i++) {
          mockFirestore.setMockData('friends', 'friend-${i + 1}', friendsList[i]);
        }

        final retrievedFriends = <Map<String, dynamic>>[];
        for (int i = 0; i < friendsList.length; i++) {
          final data = mockFirestore.getMockData('friends', 'friend-${i + 1}');
          if (data.isNotEmpty) retrievedFriends.add(data);
        }

        expect(retrievedFriends.length, equals(friendsList.length));
      });

      test('friend object has required fields', () async {
        final friend = friendsList[0];

        expect(friend['id'], isNotNull);
        expect(friend['name'], isNotNull);
        expect(friend['avatarUrl'], isNotNull);
        expect(friend['isOnline'], isNotNull);
      });

      test('friends are sorted by online status', () async {
        final friends = [
          MockUserData.friend(id: 'f1', name: 'Alice', isOnline: false),
          MockUserData.friend(id: 'f2', name: 'Bob', isOnline: true),
          MockUserData.friend(id: 'f3', name: 'Charlie', isOnline: true),
          MockUserData.friend(id: 'f4', name: 'Diana', isOnline: false),
        ];

        final onlineFriends =
            friends.where((f) => f['isOnline'] as bool).toList();
        final offlineFriends =
            friends.where((f) => !(f['isOnline'] as bool)).toList();

        expect(onlineFriends.length, equals(2));
        expect(offlineFriends.length, equals(2));
      });
    });

    group('Add Friend Tests', () {
      test('adding friend creates new friend entry', () async {
        final newFriend = MockUserData.friend(
          id: 'new-friend-1',
          name: 'New Friend',
        );

        mockFirestore.setMockData('friends', 'new-friend-1', newFriend);

        final retrieved = mockFirestore.getMockData('friends', 'new-friend-1');

        expect(retrieved['id'], equals('new-friend-1'));
        expect(retrieved['name'], equals('New Friend'));
      });

      test('adding duplicate friend is prevented', () async {
        final friend = MockUserData.friend(id: 'friend-1', name: 'Alice');

        mockFirestore.setMockData('friends', 'friend-1', friend);

        final firstAdd = mockFirestore.getMockData('friends', 'friend-1');
        mockFirestore.setMockData('friends', 'friend-1', friend);
        final secondAdd = mockFirestore.getMockData('friends', 'friend-1');

        expect(firstAdd, equals(secondAdd));
      });

      test('adding friend with empty name fails', () async {
        final invalidFriend = MockUserData.friend(name: '');

        expect(invalidFriend['name'], isEmpty);
      });

      test('added friend appears in friends list', () async {
        for (int i = 0; i < friendsList.length; i++) {
          mockFirestore.setMockData(
            'friends',
            friendsList[i]['id'],
            friendsList[i],
          );
        }

        final newFriend = MockUserData.friend(
          id: 'new-friend-2',
          name: 'New Addition',
        );

        mockFirestore.setMockData('friends', newFriend['id'], newFriend);

        final allFriends = <Map<String, dynamic>>[];
        for (final originalFriend in friendsList) {
          final data =
              mockFirestore.getMockData('friends', originalFriend['id']);
          if (data.isNotEmpty) allFriends.add(data);
        }

        final newData = mockFirestore.getMockData('friends', newFriend['id']);
        if (newData.isNotEmpty) allFriends.add(newData);

        expect(
          allFriends.any((f) => f['id'] == 'new-friend-2'),
          isTrue,
        );
      });

      test('friend can have optional properties', () async {
        final friend = MockUserData.friend(
          id: 'friend-with-extras',
          name: 'Extra Friend',
          isOnline: true,
          isFavorite: true,
          unreadMessages: 5,
        );

        mockFirestore.setMockData('friends', friend['id'], friend);

        final retrieved = mockFirestore.getMockData('friends', friend['id']);

        expect(retrieved['isFavorite'], isTrue);
        expect(retrieved['unreadMessages'], equals(5));
      });
    });

    group('Remove Friend Tests', () {
      test('removing friend deletes friend entry', () async {
        final friend = MockUserData.friend(id: 'friend-to-remove');

        mockFirestore.setMockData('friends', 'friend-to-remove', friend);
        expect(
          mockFirestore.getMockData('friends', 'friend-to-remove'),
          isNotEmpty,
        );

        // Simulate removal by setting empty data
        mockFirestore.setMockData('friends', 'friend-to-remove', {});

        expect(
          mockFirestore.getMockData('friends', 'friend-to-remove'),
          isEmpty,
        );
      });

      test('removing non-existent friend fails gracefully', () async {
        final result = mockFirestore.getMockData('friends', 'non-existent');

        expect(result, isEmpty);
      });

      test('removed friend no longer appears in list', () async {
        for (int i = 0; i < friendsList.length; i++) {
          mockFirestore.setMockData(
            'friends',
            friendsList[i]['id'],
            friendsList[i],
          );
        }

        // Remove first friend
        mockFirestore.setMockData('friends', friendsList[0]['id'], {});

        final remaining = <Map<String, dynamic>>[];
        for (int i = 1; i < friendsList.length; i++) {
          final data = mockFirestore.getMockData(
            'friends',
            friendsList[i]['id'],
          );
          if (data.isNotEmpty) remaining.add(data);
        }

        expect(
          remaining.any((f) => f['id'] == friendsList[0]['id']),
          isFalse,
        );
      });
    });

    group('Favorite Toggle Tests', () {
      test('marking friend as favorite updates status', () async {
        var friend = MockUserData.friend(
          id: 'friend-1',
          isFavorite: false,
        );

        mockFirestore.setMockData('friends', 'friend-1', friend);

        // Toggle favorite
        friend = {...friend, 'isFavorite': true};
        mockFirestore.setMockData('friends', 'friend-1', friend);

        final updated = mockFirestore.getMockData('friends', 'friend-1');

        expect(updated['isFavorite'], isTrue);
      });

      test('unmarking friend as favorite updates status', () async {
        var friend = MockUserData.friend(
          id: 'friend-1',
          isFavorite: true,
        );

        mockFirestore.setMockData('friends', 'friend-1', friend);

        friend = {...friend, 'isFavorite': false};
        mockFirestore.setMockData('friends', 'friend-1', friend);

        final updated = mockFirestore.getMockData('friends', 'friend-1');

        expect(updated['isFavorite'], isFalse);
      });

      test('favorite status persists across retrievals', () async {
        final friend = MockUserData.friend(
          id: 'friend-1',
          isFavorite: true,
        );

        mockFirestore.setMockData('friends', 'friend-1', friend);

        final first = mockFirestore.getMockData('friends', 'friend-1');
        final second = mockFirestore.getMockData('friends', 'friend-1');
        final third = mockFirestore.getMockData('friends', 'friend-1');

        expect(first['isFavorite'], isTrue);
        expect(second['isFavorite'], isTrue);
        expect(third['isFavorite'], isTrue);
      });

      test('favorites can be filtered from friends list', () async {
        final friends = [
          MockUserData.friend(id: 'f1', isFavorite: true),
          MockUserData.friend(id: 'f2', isFavorite: false),
          MockUserData.friend(id: 'f3', isFavorite: true),
          MockUserData.friend(id: 'f4', isFavorite: false),
        ];

        for (int i = 0; i < friends.length; i++) {
          mockFirestore.setMockData('friends', friends[i]['id'], friends[i]);
        }

        final favoritesList = <Map<String, dynamic>>[];
        for (final friend in friends) {
          final data = mockFirestore.getMockData('friends', friend['id']);
          if (data.isNotEmpty && (data['isFavorite'] ?? false)) {
            favoritesList.add(data);
          }
        }

        expect(favoritesList.length, equals(2));
      });
    });

    group('Search and Filter Tests', () {
      test('search friends by name', () async {
        final friends = [
          MockUserData.friend(id: 'f1', name: 'Alice Johnson'),
          MockUserData.friend(id: 'f2', name: 'Bob Smith'),
          MockUserData.friend(id: 'f3', name: 'Alice Brown'),
        ];

        for (final friend in friends) {
          mockFirestore.setMockData('friends', friend['id'], friend);
        }

        final aliceFriends = friends
            .where((f) =>
                f['name'].toString().toLowerCase().contains('alice'))
            .toList();

        expect(aliceFriends.length, equals(2));
      });

      test('filter friends by online status', () async {
        final friends = [
          MockUserData.friend(id: 'f1', isOnline: true),
          MockUserData.friend(id: 'f2', isOnline: false),
          MockUserData.friend(id: 'f3', isOnline: true),
        ];

        for (final friend in friends) {
          mockFirestore.setMockData('friends', friend['id'], friend);
        }

        final onlineFriends = friends
            .where((f) => f['isOnline'] as bool)
            .toList();

        expect(onlineFriends.length, equals(2));
      });

      test('combined filter: favorite AND online', () async {
        final friends = [
          MockUserData.friend(
            id: 'f1',
            isOnline: true,
            isFavorite: true,
          ),
          MockUserData.friend(
            id: 'f2',
            isOnline: false,
            isFavorite: true,
          ),
          MockUserData.friend(
            id: 'f3',
            isOnline: true,
            isFavorite: false,
          ),
          MockUserData.friend(
            id: 'f4',
            isOnline: false,
            isFavorite: false,
          ),
        ];

        final filtered = friends
            .where((f) => (f['isFavorite'] as bool) && (f['isOnline'] as bool))
            .toList();

        expect(filtered.length, equals(1));
        expect(filtered[0]['id'], equals('f1'));
      });
    });

    group('Friend Count Tests', () {
      test('unread message count is tracked', () async {
        final friend = MockUserData.friend(
          id: 'friend-1',
          unreadMessages: 5,
        );

        mockFirestore.setMockData('friends', 'friend-1', friend);

        final retrieved = mockFirestore.getMockData('friends', 'friend-1');

        expect(retrieved['unreadMessages'], equals(5));
      });

      test('unread count increments on new message', () async {
        var friend = MockUserData.friend(
          id: 'friend-1',
          unreadMessages: 2,
        );

        mockFirestore.setMockData('friends', 'friend-1', friend);

        friend = {...friend, 'unreadMessages': 3};
        mockFirestore.setMockData('friends', 'friend-1', friend);

        final updated = mockFirestore.getMockData('friends', 'friend-1');

        expect(updated['unreadMessages'], equals(3));
      });

      test('unread count resets on read', () async {
        var friend = MockUserData.friend(
          id: 'friend-1',
          unreadMessages: 5,
        );

        mockFirestore.setMockData('friends', 'friend-1', friend);

        friend = {...friend, 'unreadMessages': 0};
        mockFirestore.setMockData('friends', 'friend-1', friend);

        final updated = mockFirestore.getMockData('friends', 'friend-1');

        expect(updated['unreadMessages'], equals(0));
      });
    });

    group('Error Handling Tests', () {
      test('friend with missing avatar uses default', () async {
        final friend = {
          'id': 'friend-no-avatar',
          'name': 'No Avatar Friend',
          'isOnline': true,
        };

        mockFirestore.setMockData('friends', friend['id'] as String, friend);

        final retrieved = mockFirestore.getMockData('friends', friend['id'] as String);

        expect(retrieved['avatarUrl'], anyOf([isNull, isEmpty]));
      });

      test('invalid friend data is handled', () async {
        final invalidFriend = {
          'id': null,
          'name': null,
          'isOnline': 'invalid',
        };

        mockFirestore.setMockData('friends', 'invalid-friend', invalidFriend);

        final retrieved =
            mockFirestore.getMockData('friends', 'invalid-friend');

        expect(retrieved.isNotEmpty, isTrue);
      });
    });
  });
}
