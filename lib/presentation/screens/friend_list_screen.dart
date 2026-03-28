import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../providers/friend_provider.dart';
import '../../widgets/mixvy_drawer.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  late final TextEditingController _searchController;
  final Set<String> _pendingFriendActions = <String>{};

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
    final currentUserId = ref.watch(currentFriendUserIdProvider);
    final friendsAsync = ref.watch(friendsListProvider);
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsProvider);
    final pendingOutgoingIdsAsync = ref.watch(pendingOutgoingFriendRequestIdsProvider);
    final candidateAsync = ref.watch(friendCandidateSearchProvider);
    final friendService = ref.read(friendServiceProvider);

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        drawer: const MixVyDrawer(),
        body: const Center(child: Text('Please log in to manage friends.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      drawer: const MixVyDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Find people',
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by username or email',
            ),
            onChanged: (value) {
              ref.read(friendSearchQueryProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 16),
          Text('Pending requests', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          incomingRequestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.mark_email_read_outlined),
                    title: Text('No pending requests'),
                    subtitle: Text('Incoming friend requests will show up here.'),
                  ),
                );
              }

              return Column(
                children: requests
                    .map(
                      (entry) => _IncomingFriendRequestTile(
                        requestId: entry.request.id,
                        user: entry.fromUser,
                        isBusy: _pendingFriendActions.contains(entry.request.id),
                        onAccept: () async {
                          setState(() => _pendingFriendActions.add(entry.request.id));
                          try {
                            await friendService.acceptFriendRequest(entry.request.id);
                            ref.invalidate(currentFriendIdsProvider);
                            ref.invalidate(friendsListProvider);
                            ref.invalidate(friendCandidateSearchProvider);
                          } finally {
                            if (mounted) {
                              setState(() => _pendingFriendActions.remove(entry.request.id));
                            }
                          }
                        },
                        onDecline: () async {
                          setState(() => _pendingFriendActions.add(entry.request.id));
                          try {
                            await friendService.declineFriendRequest(entry.request.id);
                            ref.invalidate(friendCandidateSearchProvider);
                          } finally {
                            if (mounted) {
                              setState(() => _pendingFriendActions.remove(entry.request.id));
                            }
                          }
                        },
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Could not load friend requests'),
                subtitle: Text(error.toString()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Your friends', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          friendsAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.people_outline),
                    title: Text('No friends yet'),
                    subtitle: Text('Search for people below to send your first friend request.'),
                  ),
                );
              }

              return Column(
                children: friends
                    .map(
                      (friend) => _FriendUserTile(
                        user: friend,
                        actionLabel: 'Remove',
                        actionIcon: Icons.person_remove_outlined,
                        isBusy: _pendingFriendActions.contains(friend.id),
                        onAction: () async {
                          setState(() => _pendingFriendActions.add(friend.id));
                          try {
                            await friendService.removeFriend(currentUserId, friend.id);
                            ref.invalidate(currentFriendIdsProvider);
                            ref.invalidate(friendsListProvider);
                            ref.invalidate(friendCandidateSearchProvider);
                          } finally {
                            if (mounted) {
                              setState(() => _pendingFriendActions.remove(friend.id));
                            }
                          }
                        },
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (error, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Could not load friends'),
                subtitle: Text(error.toString()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('People you may know', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          candidateAsync.when(
            data: (users) {
              final pendingOutgoingIds = pendingOutgoingIdsAsync.valueOrNull ?? const <String>{};

              if (users.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.travel_explore_outlined),
                    title: Text('No matches right now'),
                    subtitle: Text('Try a different name or email search.'),
                  ),
                );
              }

              return Column(
                children: users
                    .map(
                      (user) => _FriendUserTile(
                        user: user,
                        actionLabel: pendingOutgoingIds.contains(user.id) ? 'Requested' : 'Add',
                        actionIcon: pendingOutgoingIds.contains(user.id)
                            ? Icons.schedule
                            : Icons.person_add_alt_1,
                        isBusy: _pendingFriendActions.contains(user.id),
                        onAction: pendingOutgoingIds.contains(user.id)
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _pendingFriendActions.add(user.id));
                                try {
                                  await friendService.sendFriendRequest(currentUserId, user.id);
                                  ref.invalidate(friendCandidateSearchProvider);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Friend request sent to ${user.username}.')),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _pendingFriendActions.remove(user.id));
                                  }
                                }
                              },
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (error, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Could not search users'),
                subtitle: Text(error.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendUserTile extends StatelessWidget {
  const _FriendUserTile({
    required this.user,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.isBusy,
  });

  final UserModel user;
  final String actionLabel;
  final IconData actionIcon;
  final Future<void> Function()? onAction;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final initials = user.username.trim().isEmpty ? '?' : user.username.trim()[0].toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(initials)),
        title: Text(user.username.isEmpty ? user.email : user.username),
        subtitle: Text(user.bio?.isNotEmpty == true ? user.bio! : user.email),
        trailing: FilledButton.tonalIcon(
          onPressed: isBusy ? null : onAction,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(actionIcon),
          label: Text(actionLabel),
        ),
      ),
    );
  }
}

class _IncomingFriendRequestTile extends StatelessWidget {
  const _IncomingFriendRequestTile({
    required this.requestId,
    required this.user,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final String requestId;
  final UserModel? user;
  final bool isBusy;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.username.isNotEmpty == true ? user!.username : user?.email ?? 'Unknown user';
    final initials = displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(initials)),
        title: Text(displayName),
        subtitle: const Text('Sent you a friend request'),
        trailing: Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: isBusy ? null : onDecline,
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: isBusy ? null : onAccept,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}
