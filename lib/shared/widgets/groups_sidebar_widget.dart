// Groups Sidebar Widget - Shows groups with active users and join/leave controls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_models.dart';
import '../../shared/providers/groups_provider.dart';
import '../../shared/providers/ui_provider.dart';
import '../../core/design_system/design_constants.dart';

class GroupsSidebarWidget extends ConsumerStatefulWidget {
  final VoidCallback onCollapse;

  const GroupsSidebarWidget({
    required this.onCollapse,
    super.key,
  });

  @override
  ConsumerState<GroupsSidebarWidget> createState() =>
      _GroupsSidebarWidgetState();
}

class _GroupsSidebarWidgetState extends ConsumerState<GroupsSidebarWidget> {
  late TextEditingController _searchController;
  bool _showAllGroups = true;
  bool _showJoinedOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    final groups = ref.watch(groupsProvider);
    final userGroups = ref.watch(userJoinedGroupsProvider);
    final filteredGroups = ref.watch(filteredGroupsProvider);
    final unreadCount = ref.watch(totalGroupUnreadProvider);

    // Filter displayed groups
    final displayedGroups = filteredGroups.when(
      data: (filtered) {
        if (_showJoinedOnly) {
          return filtered
              .where((g) => userGroups.any((u) => u.id == g.id))
              .toList();
        }
        return filtered;
      },
      loading: () => const [],
      error: (_, __) => const [],
    );

    return Container(
      width: 320,
      color: darkMode ? DesignColors.accent : DesignColors.accent,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: darkMode ? DesignColors.accent : DesignColors.accent,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DesignSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: darkMode ? DesignColors.accent : DesignColors.accent,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.group,
                          size: 20,
                          color: DesignColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DesignColors.textPrimary,
                          ),
                        ),
                        if (groups.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              groups.length.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DesignColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$unreadCount unread',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DesignColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        _showCreateGroupDialog(context, ref);
                      },
                      iconSize: 20,
                      color: DesignColors.textSecondary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCollapse,
                      iconSize: 20,
                      color: DesignColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(groupSearchQueryProvider.notifier).setQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: TextStyle(
                  color: darkMode ? DesignColors.accent : DesignColors.accent,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: darkMode ? DesignColors.accent : DesignColors.accent,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                filled: true,
                fillColor: darkMode ? DesignColors.accent : DesignColors.accent,
              ),
              style: TextStyle(
                color: darkMode ? DesignColors.accent : DesignColors.accent,
              ),
            ),
          ),
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _showAllGroups,
                  onSelected: (selected) {
                    setState(() {
                      _showAllGroups = true;
                      _showJoinedOnly = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('My Groups'),
                  selected: _showJoinedOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showJoinedOnly = true;
                      _showAllGroups = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Groups list
          Expanded(
            child: displayedGroups.isEmpty
                ? const Center(
                    child: Text(
                      'No groups found',
                      style: TextStyle(
                        color: DesignColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: displayedGroups.length,
                    itemBuilder: (context, index) {
                      final group = displayedGroups[index];
                      final isJoined = userGroups.any((u) => u.id == group.id);
                      return _GroupTile(
                        group: group,
                        isJoined: isJoined,
                        onJoin: () {
                          ref.read(groupsProvider.notifier).joinGroup(
                                group.id,
                                ref.read(currentUserIdProvider),
                              );
                        },
                        onLeave: () {
                          ref.read(groupsProvider.notifier).leaveGroup(
                                group.id,
                                ref.read(currentUserIdProvider),
                              );
                        },
                        onOpenGroup: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening group: ${group.name}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter group description',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newGroup = VideoGroup(
                  id: 'group_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  description: descriptionController.text,
                  imageUrl: 'https://i.pravatar.cc/150?u=${nameController.text}',
                  maxParticipants: 20,
                  participantIds: [ref.read(currentUserIdProvider)],
                  createdAt: DateTime.now(),
                  unreadMessages: 0,
                  ownerId: ref.read(currentUserIdProvider),
                );
                ref.read(groupsProvider.notifier).createGroup(newGroup);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group created!')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final VideoGroup group;
  final bool isJoined;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onOpenGroup;

  const _GroupTile({
    required this.group,
    required this.isJoined,
    required this.onJoin,
    required this.onLeave,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(group.imageUrl),
          radius: 20,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              group.description,
              style: const TextStyle(
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Row(
          children: [
            const Icon(
              Icons.people_outline,
              size: 14,
              color: DesignColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${group.participantIds.length}/${group.maxParticipants}',
              style: const TextStyle(
                fontSize: 12,
                color: DesignColors.textSecondary,
              ),
            ),
            if (group.unreadMessages > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  group.unreadMessages.toString(),
                  style: const TextStyle(
                    color: DesignColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isJoined
            ? IconButton(
               icon: const Icon(Icons.exit_to_app),
                onPressed: onLeave,
                color: DesignColors.textSecondary,
              )
            : ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignColors.accent,
                ),
                child: const Text('Join'),
              ),
        onTap: isJoined ? onOpenGroup : null,
        hoverColor: DesignColors.surfaceLight,
      ),
    );
  }
}
