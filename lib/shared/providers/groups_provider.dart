
// Groups Provider - Manages video groups/rooms with participants and state
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_models.dart';

/// Mock groups generator
List<VideoGroup> _generateMockGroups() {
  return [
    VideoGroup(
      id: 'group1',
      name: 'Daily Standup',
      description: 'Team sync every morning',
      imageUrl: 'https://i.pravatar.cc/150?u=standup',
      maxParticipants: 20,
      participantIds: ['1', '2', '3', '4'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      unreadMessages: 0,
      ownerId: '1',
    ),
    VideoGroup(
      id: 'group2',
      name: 'Game Night',
      description: 'Weekly gaming session',
      imageUrl: 'https://i.pravatar.cc/150?u=games',
      maxParticipants: 10,
      participantIds: ['2', '3', '5', '6'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      unreadMessages: 3,
      ownerId: '2',
    ),
    VideoGroup(
      id: 'group3',
      name: 'Creative Studio',
      description: 'For artists and creators',
      imageUrl: 'https://i.pravatar.cc/150?u=creative',
      maxParticipants: 15,
      participantIds: ['1', '4', '6'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      unreadMessages: 5,
      ownerId: '4',
    ),
    VideoGroup(
      id: 'group4',
      name: 'Language Exchange',
      description: 'Practice different languages',
      imageUrl: 'https://i.pravatar.cc/150?u=language',
      maxParticipants: 8,
      participantIds: ['3', '5'],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      unreadMessages: 0,
      ownerId: '3',
    ),
    VideoGroup(
      id: 'group5',
      name: 'Fitness Buddies',
      description: 'Workout accountability group',
      imageUrl: 'https://i.pravatar.cc/150?u=fitness',
      maxParticipants: 12,
      participantIds: ['1', '2', '4', '5', '6'],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      unreadMessages: 2,
      ownerId: '5',
    ),
  ];
}

/// Groups notifier
class GroupsNotifier extends Notifier<List<VideoGroup>> {
  @override
  List<VideoGroup> build() {
    return _generateMockGroups();
  }

  /// Join a group
  void joinGroup(String groupId, String userId) {
    state = state.map((group) {
      if (group.id == groupId && !group.participantIds.contains(userId)) {
        return group.copyWith(
          participantIds: [...group.participantIds, userId],
        );
      }
      return group;
    }).toList();
  }

  /// Leave a group
  void leaveGroup(String groupId, String userId) {
    state = state.map((group) {
      if (group.id == groupId) {
        return group.copyWith(
          participantIds: group.participantIds
              .where((id) => id != userId)
              .toList(),
        );
      }
      return group;
    }).toList();
  }

  /// Mark messages as read
  void markMessagesAsRead(String groupId) {
    state = state.map((group) {
      if (group.id == groupId) {
        return group.copyWith(unreadMessages: 0);
      }
      return group;
    }).toList();
  }

  /// Add unread message
  void addUnreadMessage(String groupId) {
    state = state.map((group) {
      if (group.id == groupId) {
        return group.copyWith(
          unreadMessages: group.unreadMessages + 1,
        );
      }
      return group;
    }).toList();
  }

  /// Create new group (mock)
  void createGroup(VideoGroup newGroup) {
    state = [...state, newGroup];
  }
}

/// Groups provider
final groupsProvider = NotifierProvider<GroupsNotifier, List<VideoGroup>>(
  () => GroupsNotifier(),
);

/// Current user ID (mock)
final currentUserIdProvider = Provider<String>((ref) => '1');

/// User's joined groups
final userJoinedGroupsProvider = Provider<List<VideoGroup>>((ref) {
  final groups = ref.watch(groupsProvider);
  final userId = ref.watch(currentUserIdProvider);
  return groups.where((group) => group.participantIds.contains(userId)).toList();
});

/// Active groups (with participants)
final activeGroupsProvider = Provider<List<VideoGroup>>((ref) {
  final groups = ref.watch(groupsProvider);
  return groups.where((group) => group.participantIds.isNotEmpty).toList();
});

/// Groups with unread messages
final groupsWithUnreadProvider = Provider<List<VideoGroup>>((ref) {
  final groups = ref.watch(groupsProvider);
  return groups.where((group) => group.unreadMessages > 0).toList();
});

/// Total unread messages in groups
final totalGroupUnreadProvider = Provider<int>((ref) {
  final groups = ref.watch(groupsProvider);
  return groups.fold<int>(0, (sum, group) => sum + group.unreadMessages);
});

/// Group search
class GroupSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final groupSearchQueryProvider = NotifierProvider<GroupSearchQueryNotifier, String>(
  () => GroupSearchQueryNotifier(),
);

final filteredGroupsProvider = FutureProvider<List<VideoGroup>>((ref) {
  final groups = ref.watch(groupsProvider);
  final query = ref.watch(groupSearchQueryProvider);

  return Future.value(
    groups
        .where((group) =>
            group.name.toLowerCase().contains(query.toLowerCase()) ||
            group.description.toLowerCase().contains(query.toLowerCase()))
        .toList(),
  );
});




