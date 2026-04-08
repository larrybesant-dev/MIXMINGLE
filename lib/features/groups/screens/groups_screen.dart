import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../../core/theme.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isMember = group.isMember(userId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: NeonPulse.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/group/${group.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        color: NeonPulse.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${group.memberCount} members',
                                      style: const TextStyle(
                                        color: NeonPulse.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: ElevatedButton(
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isMember
                                        ? NeonPulse.surfaceBright
                                        : NeonPulse.primaryDim,
                                    foregroundColor: NeonPulse.onSurface,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    isMember ? 'Leave' : 'Join',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: NeonPulse.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            color: NeonPulse.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${group.memberCount} members',
                          style: const TextStyle(color: NeonPulse.onSurfaceVariant),
                        ),
                        onTap: () => context.push('/group/${group.id}'),
                      ),
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
