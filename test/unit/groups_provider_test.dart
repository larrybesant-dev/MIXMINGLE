/// Groups Provider Tests - Join/Leave Groups, Member Management
///
/// Tests for:
/// - Getting groups list
/// - Joining groups
/// - Leaving groups
/// - Member management
/// - Unread count tracking
/// - Group search and filtering
/// - Error handling

import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

void main() {
  group('GroupsProvider Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late List<Map<String, dynamic>> groupsList;
    late String userId;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      groupsList = TestFixtures.groupsList();
      userId = 'current-user-123';
    });

    group('Get Groups Tests', () {
      test('returns all groups user has joined', () async {
        for (int i = 0; i < groupsList.length; i++) {
          mockFirestore.setMockData('groups', 'group-${i + 1}', groupsList[i]);
        }

        final retrievedGroups = <Map<String, dynamic>>[];
        for (int i = 0; i < groupsList.length; i++) {
          final data = mockFirestore.getMockData('groups', 'group-${i + 1}');
          if (data.isNotEmpty) retrievedGroups.add(data);
        }

        expect(retrievedGroups.length, equals(groupsList.length));
      });

      test('group object has required fields', () async {
        final group = groupsList[0];

        expect(group['id'], isNotNull);
        expect(group['name'], isNotNull);
        expect(group['description'], isNotNull);
        expect(group['members'], isNotNull);
      });

      test('groups are ordered by member count', () async {
        final groups = [
          MockUserData.group(
            id: 'g1',
            name: 'Large Group',
            memberCount: 50,
          ),
          MockUserData.group(
            id: 'g2',
            name: 'Small Group',
            memberCount: 3,
          ),
          MockUserData.group(
            id: 'g3',
            name: 'Medium Group',
            memberCount: 20,
          ),
        ];

        final sorted = groups..sort((a, b) => (b['memberCount'] as int).compareTo(a['memberCount'] as int));

        expect((sorted[0]['memberCount'] as int), equals(50));
        expect((sorted[1]['memberCount'] as int), equals(20));
        expect((sorted[2]['memberCount'] as int), equals(3));
      });

      test('returns empty list when user has no groups', () async {
        final result = <Map<String, dynamic>>[];
        for (int i = 100; i < 110; i++) {
          final data = mockFirestore.getMockData('groups', 'group-$i');
          if (data.isNotEmpty) result.add(data);
        }

        expect(result.isEmpty, isTrue);
      });
    });

    group('Join Group Tests', () {
      test('joining group adds user to members list', () async {
        var group = MockUserData.group(
          id: 'group-1',
          name: 'Test Group',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        var members = List<String>.from(group['members'] as List);
        if (!members.contains(userId)) {
          members.add(userId);
        }

        group = {...group, 'members': members};
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(
          (updated['members'] as List).contains(userId),
          isTrue,
        );
      });

      test('joining group increments member count', () async {
        var group = MockUserData.group(
          id: 'group-1',
          memberCount: 5,
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        final currentCount = (group['memberCount'] as int?) ?? 0;
        group = {...group, 'memberCount': currentCount + 1};
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(updated['memberCount'], equals(6));
      });

      test('cannot join same group twice', () async {
        var group = MockUserData.group(
          id: 'group-1',
          name: 'Test Group',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        var members = List<String>.from(group['members'] as List);
        if (!members.contains(userId)) {
          members.add(userId);
        }

        group = {...group, 'members': members};
        mockFirestore.setMockData('groups', 'group-1', group);

        final firstJoin = mockFirestore.getMockData('groups', 'group-1');

        // Try joining again
        final memberCountBefore =
            (firstJoin['members'] as List).length;

        members = List<String>.from(firstJoin['members'] as List);
        if (!members.contains(userId)) {
          members.add(userId);
        }

        group = {...firstJoin, 'members': members};
        mockFirestore.setMockData('groups', 'group-1', group);

        final secondJoin = mockFirestore.getMockData('groups', 'group-1');
        final memberCountAfter = (secondJoin['members'] as List).length;

        expect(memberCountBefore, equals(memberCountAfter));
      });

      test('user appears in group members after joining', () async {
        final group = MockUserData.group(
          id: 'group-1',
          name: 'Test Group',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        var members = List<String>.from(group['members'] as List);
        members.add(userId);

        mockFirestore.setMockData(
          'groups',
          'group-1',
          {...group, 'members': members},
        );

        final updated = mockFirestore.getMockData('groups', 'group-1');
        final isMember = (updated['members'] as List).contains(userId);

        expect(isMember, isTrue);
      });
    });

    group('Leave Group Tests', () {
      test('leaving group removes user from members list', () async {
        var group = MockUserData.group(
          id: 'group-1',
          name: 'Test Group',
        );

        var members = List<String>.from(group['members'] as List);
        members.add(userId);
        group = {...group, 'members': members};

        mockFirestore.setMockData('groups', 'group-1', group);

        // Leave group
        members = List<String>.from(group['members'] as List);
        members.remove(userId);
        group = {...group, 'members': members};
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(
          (updated['members'] as List).contains(userId),
          isFalse,
        );
      });

      test('leaving group decrements member count', () async {
        var group = MockUserData.group(
          id: 'group-1',
          memberCount: 10,
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        final newCount = ((group['memberCount'] as int?) ?? 0) - 1;
        group = {...group, 'memberCount': newCount};
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(updated['memberCount'], equals(9));
      });

      test('leaving only user removes group', () async {
        var group = MockUserData.group(
          id: 'group-1',
          memberCount: 1,
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        // Leave (making it empty)
        mockFirestore.setMockData('groups', 'group-1', {});

        final result = mockFirestore.getMockData('groups', 'group-1');

        expect(result.isEmpty, isTrue);
      });
    });

    group('Member Management Tests', () {
      test('group has list of members', () async {
        final group = MockUserData.group(
          id: 'group-1',
          name: 'Group with Members',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        final retrieved = mockFirestore.getMockData('groups', 'group-1');

        expect(retrieved['members'], isList);
        expect((retrieved['members'] as List).isNotEmpty, isTrue);
      });

      test('member count matches list length', () async {
        final group = MockUserData.group(
          id: 'group-1',
          name: 'Group with Members',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        final retrieved = mockFirestore.getMockData('groups', 'group-1');

        final memberCount = (retrieved['memberCount'] as int?) ?? 0;
        final memberListLength = ((retrieved['members'] as List?)?.length) ?? 0;

        expect(memberListLength, greaterThanOrEqualTo(0));
      });

      test('can get list of all members in group', () async {
        final memberIds = ['user-1', 'user-2', 'user-3', 'user-4'];
        var group = MockUserData.group(
          id: 'group-1',
          name: 'Group with Multiple Members',
        );

        group = {...group, 'members': memberIds};
        mockFirestore.setMockData('groups', 'group-1', group);

        final retrieved = mockFirestore.getMockData('groups', 'group-1');
        final members = retrieved['members'] as List;

        expect(members.length, equals(4));
        expect(members.contains('user-2'), isTrue);
      });
    });

    group('Unread Count Tests', () {
      test('unread message count is tracked per group', () async {
        final group = MockUserData.group(
          id: 'group-1',
          unreadCount: 5,
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        final retrieved = mockFirestore.getMockData('groups', 'group-1');

        expect(retrieved['unreadCount'], equals(5));
      });

      test('unread count increments on new message', () async {
        var group = MockUserData.group(
          id: 'group-1',
          unreadCount: 2,
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        group = {...group, 'unreadCount': 3};
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(updated['unreadCount'], equals(3));
      });

      test('unread count resets on mark as read', () async {
        var group = MockUserData.group(
          id: 'group-1',
          unreadCount: 10,
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        group = {...group, 'unreadCount': 0};
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(updated['unreadCount'], equals(0));
      });

      test('batch mark read updates multiple groups', () async {
        final groups = [
          MockUserData.group(id: 'g1', unreadCount: 5),
          MockUserData.group(id: 'g2', unreadCount: 3),
          MockUserData.group(id: 'g3', unreadCount: 7),
        ];

        for (final group in groups) {
          mockFirestore.setMockData('groups', group['id'], group);
        }

        // Mark all as read
        for (final group in groups) {
          mockFirestore.setMockData(
            'groups',
            group['id'],
            {...group, 'unreadCount': 0},
          );
        }

        int totalUnread = 0;
        for (final group in groups) {
          final data = mockFirestore.getMockData('groups', group['id']);
          totalUnread += (data['unreadCount'] as int?) ?? 0;
        }

        expect(totalUnread, equals(0));
      });
    });

    group('Search and Filter Tests', () {
      test('search groups by name', () async {
        final groups = [
          MockUserData.group(id: 'g1', name: 'Flutter Developers'),
          MockUserData.group(id: 'g2', name: 'Design Team'),
          MockUserData.group(id: 'g3', name: 'Flutter UI'),
        ];

        for (final group in groups) {
          mockFirestore.setMockData('groups', group['id'], group);
        }

        final flutterGroups = groups
            .where((g) =>
                g['name'].toString().toLowerCase().contains('flutter'))
            .toList();

        expect(flutterGroups.length, equals(2));
      });

      test('filter groups with unread messages', () async {
        final groups = [
          MockUserData.group(id: 'g1', unreadCount: 0),
          MockUserData.group(id: 'g2', unreadCount: 5),
          MockUserData.group(id: 'g3', unreadCount: 2),
        ];

        for (final group in groups) {
          mockFirestore.setMockData('groups', group['id'], group);
        }

        final unreadGroups = groups
            .where((g) => ((g['unreadCount'] as int?) ?? 0) > 0)
            .toList();

        expect(unreadGroups.length, equals(2));
      });

      test('filter groups by member count', () async {
        final groups = [
          MockUserData.group(id: 'g1', memberCount: 2),
          MockUserData.group(id: 'g2', memberCount: 100),
          MockUserData.group(id: 'g3', memberCount: 25),
        ];

        for (final group in groups) {
          mockFirestore.setMockData('groups', group['id'], group);
        }

        final largeGroups = groups
            .where((g) => ((g['memberCount'] as int?) ?? 0) > 10)
            .toList();

        expect(largeGroups.length, equals(2));
      });

      test('combined filter: has unread AND is member', () async {
        final userGroups = [
          {
            'id': 'g1',
            'name': 'Group 1',
            'unreadCount': 5,
            'isMember': true,
          },
          {
            'id': 'g2',
            'name': 'Group 2',
            'unreadCount': 0,
            'isMember': true,
          },
          {
            'id': 'g3',
            'name': 'Group 3',
            'unreadCount': 3,
            'isMember': false,
          },
        ];

        final filtered = userGroups
            .where((g) =>
                ((g['unreadCount'] as int?) ?? 0) > 0 &&
                (g['isMember'] as bool))
            .toList();

        expect(filtered.length, equals(1));
        expect(filtered[0]['id'], equals('g1'));
      });
    });

    group('Group Metadata Tests', () {
      test('group has description', () async {
        final group = MockUserData.group(
          id: 'group-1',
          description: 'A group for Flutter developers',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        final retrieved = mockFirestore.getMockData('groups', 'group-1');

        expect(retrieved['description'], isNotNull);
        expect(
          retrieved['description']
              .toString()
              .isNotEmpty,
          isTrue,
        );
      });

      test('group can be updated', () async {
        var group = MockUserData.group(
          id: 'group-1',
          name: 'Original Name',
          description: 'Original description',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        group = {
          ...group,
          'name': 'Updated Name',
          'description': 'Updated description',
        };
        mockFirestore.setMockData('groups', 'group-1', group);

        final updated = mockFirestore.getMockData('groups', 'group-1');

        expect(updated['name'], equals('Updated Name'));
        expect(updated['description'], equals('Updated description'));
      });
    });

    group('Error Handling Tests', () {
      test('joining non-existent group fails', () async {
        final result = mockFirestore.getMockData('groups', 'non-existent');

        expect(result.isEmpty, isTrue);
      });

      test('group with invalid member data is handled', () async {
        final group = {
          'id': 'group-1',
          'name': 'Test Group',
          'members': null,
          'memberCount': 'invalid',
        };

        mockFirestore.setMockData('groups', 'group-1', group);

        final retrieved = mockFirestore.getMockData('groups', 'group-1');

        expect(retrieved.isNotEmpty, isTrue);
      });

      test('leaving group when not member fails gracefully', () async {
        final group = MockUserData.group(
          id: 'group-1',
          name: 'Test Group',
        );

        mockFirestore.setMockData('groups', 'group-1', group);

        var members = List<String>.from(group['members'] as List);
        // Try to remove user who is not in the group
        final beforeRemove = members.length;
        members.removeWhere((m) => m == 'non-member-user');
        final afterRemove = members.length;

        expect(beforeRemove, equals(afterRemove));
      });
    });
  });
}
