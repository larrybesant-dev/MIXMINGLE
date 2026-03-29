import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';

class GroupsScreen extends ConsumerWidget {
  final String userId;

  const GroupsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final userGroupsAsync = ref.watch(userGroupsProvider(userId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Groups'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Discover'),
              Tab(text: 'My Groups'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/create-group?userId=$userId'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Discover tab
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(child: Text('No groups yet'));
                }
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isMember = group.isMember(userId);
                    return ListTile(
                      title: Text(group.name),
                      subtitle: Text('${group.memberCount} members'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          if (isMember) {
                            ref.read(groupsControllerProvider).leaveGroup(
                                  groupId: group.id,
                                  userId: userId,
                                );
                          } else {
                            ref.read(groupsControllerProvider).joinGroup(
                                  groupId: group.id,
                                  userId: userId,
                                );
                          }
                        },
                        child: Text(isMember ? 'Leave' : 'Join'),
                      ),
                      onTap: () => context.push('/group/${group.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
            // My Groups tab
            userGroupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(child: Text('You have not joined any groups'));
                }
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      title: Text(group.name),
                      subtitle: Text('${group.memberCount} members'),
                      onTap: () => context.push('/group/${group.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }
}
