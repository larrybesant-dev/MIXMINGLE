import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../models/presence_model.dart';
import '../providers/friend_provider.dart';
import '../../widgets/mixvy_drawer.dart';
import '../../features/feed/widgets/feed_empty_state.dart';
import '../../widgets/user_profile_popup.dart';

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
    final favoritesAsync = ref.watch(favoriteFriendIdsProvider);

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
              hintText: 'Search by username',
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
                return const FeedEmptyState(
                  emoji: '📬',
                  heading: 'No pending requests',
                  message: 'Incoming friend requests will show up here.',
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
                return const FeedEmptyState(
                  emoji: '👥',
                  heading: 'No friends yet',
                  message: 'Search for people below to send your first friend request.',
                );
              }

              return Column(
                children: friends
                    .map(
                      (friend) {
                        final isFavorite = favoritesAsync.valueOrNull?.contains(friend.id) ?? false;
                        return _FriendUserTile(
                          user: friend,
                          isFavorite: isFavorite,
                          actionLabel: 'Remove',
                          actionIcon: Icons.person_remove_outlined,
                          isBusy: _pendingFriendActions.contains(friend.id),
                          onToggleFavorite: () async {
                            await friendService.setFavorite(
                              currentUserId,
                              friend.id,
                              isFavorite: !isFavorite,
                            );
                            ref.invalidate(favoriteFriendIdsProvider);
                            ref.invalidate(friendsListProvider);
                          },
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
                        );
                      })
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
                // Show friends-of-friends when there's no active search.
                final suggestionsAsync = ref.watch(friendSuggestionsProvider);
                return suggestionsAsync.when(
                  data: (suggestions) {
                    if (suggestions.isEmpty) {
                      return const FeedEmptyState(
                        emoji: '🔍',
                        heading: 'No matches right now',
                        message: 'Try a different name or email search.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Suggested — friends of your friends',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ),
                        ...suggestions.map(
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
                                      ref.invalidate(friendSuggestionsProvider);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Friend request sent to ${user.username}.')),
                                      );
                                    } finally {
                                      if (mounted) setState(() => _pendingFriendActions.remove(user.id));
                                    }
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                  error: (_, _) => const SizedBox.shrink(),
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

class _FriendUserTile extends ConsumerWidget {
  const _FriendUserTile({
    required this.user,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.isBusy,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final UserModel user;
  final String actionLabel;
  final IconData actionIcon;
  final Future<void> Function()? onAction;
  final bool isBusy;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  Color _statusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online: return const Color(0xFF22C55E);
      case UserStatus.away: return const Color(0xFFF59E0B);
      case UserStatus.dnd: return const Color(0xFFEF4444);
      case UserStatus.offline: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = ref.watch(friendPresenceProvider(user.id));
    final presence = presenceAsync.valueOrNull;
    final status = presence?.status ?? UserStatus.offline;
    final inRoom = presence?.inRoom;

    final initials = user.username.trim().isEmpty ? '?' : user.username.trim()[0].toUpperCase();
    final safeName = user.username.trim().isEmpty ? 'MixVy user' : user.username;

    String subtitleText;
    if (inRoom != null && inRoom.isNotEmpty) {
      subtitleText = 'In a room';
    } else if (presence?.isOnline == true) {
      subtitleText = status == UserStatus.away ? 'Away' : status == UserStatus.dnd ? 'Do not disturb' : 'Online';
    } else {
      subtitleText = user.bio?.isNotEmpty == true ? user.bio! : 'Offline';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => UserProfilePopup.show(context, ref, userId: user.id, preloadedUser: user),
        leading: Stack(
          children: [
            CircleAvatar(child: Text(initials)),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(status),
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(safeName)),
            if (onToggleFavorite != null)
              GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorite ? Colors.amber : null,
                  size: 20,
                ),
              ),
          ],
        ),
        subtitle: Text(subtitleText, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final displayName = user?.username.isNotEmpty == true ? user!.username : 'MixVy user';
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
