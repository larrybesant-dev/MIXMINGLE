import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_layout.dart';
import '../../models/user_model.dart';
import '../../models/presence_model.dart';
import '../providers/friend_provider.dart';
import '../providers/user_provider.dart';
import '../../features/feed/widgets/feed_empty_state.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../widgets/user_profile_popup.dart';
import '../../services/notification_service.dart';
import '../../services/presence_service.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../core/theme.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  late final TextEditingController _searchController;
  final Set<String> _pendingFriendActions = <String>{};
  final Set<String> _pendingMessageActions = <String>{};
  final Set<String> _pendingInviteActions = <String>{};

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
    final currentUser = ref.watch(userProvider);
    final friendsAsync = ref.watch(friendsListProvider);
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsProvider);
    final pendingOutgoingIdsAsync = ref.watch(pendingOutgoingFriendRequestIdsProvider);
    final candidateAsync = ref.watch(friendCandidateSearchProvider);
    final friendService = ref.read(friendServiceProvider);
    final favoritesAsync = ref.watch(favoriteFriendIdsProvider);
    final myPresenceAsync = ref.watch(currentUserPresenceProvider);
    final myRoomId = myPresenceAsync.valueOrNull?.inRoom;

    if (currentUserId == null) {
      return AppPageScaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: const AppEmptyView(
          title: 'Please log in to manage friends',
          icon: Icons.login_rounded,
        ),
      );
    }

    final theme = Theme.of(context);

    return AppPageScaffold(
      backgroundColor: VelvetNoir.surface,
      appBar: AppBar(
        backgroundColor: VelvetNoir.surfaceHigh,
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: VelvetNoir.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.pageHorizontalPadding,
          12,
          context.pageHorizontalPadding,
          32,
        ),
        children: [
          // ── Status toggle ──────────────────────────────────────────────
          _StatusToggleBar(userId: currentUserId),
          const SizedBox(height: 16),

          // ── Search ─────────────────────────────────────────────────────
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by username',
            ),
            onChanged: (value) {
              ref.read(friendSearchQueryProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 24),

          // ── Incoming requests ──────────────────────────────────────────
          _SectionHeader(
            label: 'Requests',
            icon: Icons.mail_outline_rounded,
            badge: incomingRequestsAsync.valueOrNull?.length,
          ),
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
                    .map((entry) => _IncomingFriendRequestTile(
                          requestId: entry.request.id,
                          user: entry.fromUser,
                          isBusy: _pendingFriendActions.contains(entry.request.id),
                          onAccept: () async {
                            setState(() => _pendingFriendActions.add(entry.request.id));
                            try {
                              await friendService.acceptFriendRequest(entry.request.id);
                              ref.invalidate(currentFriendIdsProvider);
                              ref.invalidate(friendCandidateSearchProvider);
                            } finally {
                              if (mounted) setState(() => _pendingFriendActions.remove(entry.request.id));
                            }
                          },
                          onDecline: () async {
                            setState(() => _pendingFriendActions.add(entry.request.id));
                            try {
                              await friendService.declineFriendRequest(entry.request.id);
                              ref.invalidate(friendCandidateSearchProvider);
                            } finally {
                              if (mounted) setState(() => _pendingFriendActions.remove(entry.request.id));
                            }
                          },
                        ))
                    .toList(growable: false),
              );
            },
            loading: () => const _SectionLoading(),
            error: (e, _) => _SectionError(message: e.toString()),
          ),

          const SizedBox(height: 24),

          // ── Friends list ───────────────────────────────────────────────
          _SectionHeader(
            label: 'Friends',
            icon: Icons.people_alt_rounded,
            badge: friendsAsync.valueOrNull?.length,
          ),
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
                children: friends.map((friend) {
                  final isFavorite = favoritesAsync.valueOrNull?.contains(friend.id) ?? false;
                  return _FriendUserTile(
                    user: friend,
                    isFavorite: isFavorite,
                    isConfirmedFriend: true,
                    actionIcon: Icons.person_remove_outlined,
                    actionTooltip: 'Remove friend',
                    isBusy: _pendingFriendActions.contains(friend.id),
                    isMessageBusy: _pendingMessageActions.contains(friend.id),
                    isInviteBusy: _pendingInviteActions.contains(friend.id),
                    myRoomId: myRoomId,
                    onToggleFavorite: () async {
                      await friendService.setFavorite(currentUserId, friend.id, isFavorite: !isFavorite);
                      ref.invalidate(favoriteFriendIdsProvider);
                    },
                    onAction: () async {
                      setState(() => _pendingFriendActions.add(friend.id));
                      try {
                        await friendService.removeFriend(currentUserId, friend.id);
                        ref.invalidate(currentFriendIdsProvider);
                        ref.invalidate(friendCandidateSearchProvider);
                      } finally {
                        if (mounted) setState(() => _pendingFriendActions.remove(friend.id));
                      }
                    },
                    onMessage: () async {
                      setState(() => _pendingMessageActions.add(friend.id));
                      try {
                        final convId = await ref.read(messagingControllerProvider).createDirectConversation(
                              userId1: currentUserId,
                              user1Name: currentUser?.username ?? 'Me',
                              user1AvatarUrl: currentUser?.avatarUrl,
                              userId2: friend.id,
                              user2Name: friend.username,
                              user2AvatarUrl: friend.avatarUrl,
                            );
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        context.go('/messages/$convId');
                      } catch (e) {
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
                      } finally {
                        if (mounted) setState(() => _pendingMessageActions.remove(friend.id));
                      }
                    },
                    onInvite: myRoomId == null
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _pendingInviteActions.add(friend.id));
                            try {
                              await NotificationService().sendRoomInviteToFriends(
                                friendIds: [friend.id],
                                inviterId: currentUserId,
                                inviterName: currentUser?.username.trim().isEmpty == true
                                    ? 'Someone'
                                    : (currentUser?.username ?? 'Someone'),
                                roomId: myRoomId,
                                roomName: "${currentUser?.username ?? 'Someone'}'s room",
                              );
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('${friend.username} was invited to your room!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) messenger.showSnackBar(SnackBar(content: Text('Could not send invite: $e')));
                            } finally {
                              if (mounted) setState(() => _pendingInviteActions.remove(friend.id));
                            }
                          },
                  );
                }).toList(growable: false),
              );
            },
            loading: () => const _SectionLoading(),
            error: (e, _) => _SectionError(message: e.toString()),
          ),

          const SizedBox(height: 24),

          // ── People you may know ────────────────────────────────────────
          _SectionHeader(label: 'People you may know', icon: Icons.search_rounded),
          const SizedBox(height: 8),
          candidateAsync.when(
            data: (users) {
              final pendingOutgoingIds = pendingOutgoingIdsAsync.valueOrNull ?? const <String>{};
              if (users.isEmpty) {
                final suggestionsAsync = ref.watch(friendSuggestionsProvider);
                return suggestionsAsync.when(
                  data: (suggestions) {
                    if (suggestions.isEmpty) {
                      return const FeedEmptyState(
                        emoji: '🔍',
                        heading: 'No matches right now',
                        message: 'Try a different name.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Suggested — friends of your friends',
                            style: theme.textTheme.bodySmall?.copyWith(color: VelvetNoir.onSurfaceVariant),
                          ),
                        ),
                        ...suggestions.map((user) => _FriendUserTile(
                              user: user,
                              actionIcon: pendingOutgoingIds.contains(user.id) ? Icons.schedule : Icons.person_add_alt_1,
                              actionTooltip: pendingOutgoingIds.contains(user.id) ? 'Requested' : 'Add friend',
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
                                        messenger.showSnackBar(SnackBar(content: Text('Friend request sent to ${user.username}.')));
                                      } finally {
                                        if (mounted) setState(() => _pendingFriendActions.remove(user.id));
                                      }
                                    },
                            )),
                      ],
                    );
                  },
                  loading: () => const _SectionLoading(),
                  error: (Object e, StackTrace s) => const SizedBox.shrink(),
                );
              }
              return Column(
                children: users
                    .map((user) => _FriendUserTile(
                          user: user,
                          actionIcon: pendingOutgoingIds.contains(user.id) ? Icons.schedule : Icons.person_add_alt_1,
                          actionTooltip: pendingOutgoingIds.contains(user.id) ? 'Requested' : 'Add friend',
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
                                    messenger.showSnackBar(SnackBar(content: Text('Friend request sent to ${user.username}.')));
                                  } finally {
                                    if (mounted) setState(() => _pendingFriendActions.remove(user.id));
                                  }
                                },
                        ))
                    .toList(growable: false),
              );
            },
            loading: () => const _SectionLoading(),
            error: (e, _) => _SectionError(message: e.toString()),
          ),
        ],
      ),
    );
  }
}

// ── Status toggle bar ────────────────────────────────────────────────────────

class _StatusToggleBar extends ConsumerWidget {
  const _StatusToggleBar({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = ref.watch(currentUserPresenceProvider);
    final status = presenceAsync.valueOrNull?.status ?? UserStatus.offline;
    final inRoom = presenceAsync.valueOrNull?.inRoom;
    final theme = Theme.of(context);

    Color statusColor(UserStatus s) {
      switch (s) {
        case UserStatus.online: return const Color(0xFF22C55E);
        case UserStatus.away: return const Color(0xFFF59E0B);
        case UserStatus.dnd: return const Color(0xFFEF4444);
        case UserStatus.offline: return VelvetNoir.onSurfaceVariant;
      }
    }

    String statusLabel(UserStatus s) {
      switch (s) {
        case UserStatus.online: return 'Online';
        case UserStatus.away: return 'Away';
        case UserStatus.dnd: return 'Do not disturb';
        case UserStatus.offline: return 'Offline';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VelvetNoir.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor(status),
              boxShadow: [BoxShadow(color: statusColor(status).withValues(alpha: 0.5), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            inRoom != null ? 'In a room · ${statusLabel(status)}' : statusLabel(status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          PopupMenuButton<UserStatus>(
            tooltip: 'Change status',
            icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (s) async {
              await PresenceService().setStatus(userId, s);
            },
            itemBuilder: (_) => [
              _statusItem(UserStatus.online, 'Online', const Color(0xFF22C55E)),
              _statusItem(UserStatus.away, 'Away', const Color(0xFFF59E0B)),
              _statusItem(UserStatus.dnd, 'Do not disturb', const Color(0xFFEF4444)),
              _statusItem(UserStatus.offline, 'Appear offline', VelvetNoir.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<UserStatus> _statusItem(UserStatus s, String label, Color color) =>
      PopupMenuItem<UserStatus>(
        value: s,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      );
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon, this.badge});
  final String label;
  final IconData icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: VelvetNoir.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: VelvetNoir.primary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: VelvetNoir.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: VelvetNoir.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$badge',
              style: theme.textTheme.labelSmall?.copyWith(
                color: VelvetNoir.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('Something went wrong'),
          subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      );
}

// ── Friend tile ──────────────────────────────────────────────────────────────

class _FriendUserTile extends ConsumerWidget {
  const _FriendUserTile({
    required this.user,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
    required this.isBusy,
    this.isConfirmedFriend = false,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.myRoomId,
    this.onMessage,
    this.isMessageBusy = false,
    this.onInvite,
    this.isInviteBusy = false,
  });

  final UserModel user;
  final IconData actionIcon;
  final String actionTooltip;
  final Future<void> Function()? onAction;
  final bool isBusy;
  final bool isConfirmedFriend;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final String? myRoomId;
  final Future<void> Function()? onMessage;
  final bool isMessageBusy;
  final Future<void> Function()? onInvite;
  final bool isInviteBusy;

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

    // Show "Invite" only when the current user is in a room and this friend
    // is NOT already in that same room.
    final canInvite = isConfirmedFriend &&
        myRoomId != null &&
        inRoom != myRoomId &&
        onInvite != null;

    final initials = user.username.trim().isEmpty ? '?' : user.username.trim()[0].toUpperCase();
    final safeName = user.username.trim().isEmpty ? 'MixVy user' : user.username;

    final String subtitleText;
    if (inRoom != null && inRoom.isNotEmpty) {
      subtitleText = 'In a room';
    } else if (presence?.isOnline == true) {
      switch (status) {
        case UserStatus.away: subtitleText = 'Away'; break;
        case UserStatus.dnd: subtitleText = 'Do not disturb'; break;
        default: subtitleText = 'Online'; break;
      }
    } else {
      subtitleText = user.bio?.isNotEmpty == true ? (user.bio!) : 'Offline';
    }

    final theme = Theme.of(context);
    final statusDotColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => UserProfilePopup.show(context, ref, userId: user.id, preloadedUser: user),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              // Avatar + status dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: VelvetNoir.primary.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: VelvetNoir.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusDotColor,
                        border: Border.all(color: VelvetNoir.surfaceHigh, width: 2),
                        boxShadow: [BoxShadow(color: statusDotColor.withValues(alpha: 0.5), blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            safeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: VelvetNoir.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (inRoom != null && inRoom.isNotEmpty)
                          _StatusChip(label: 'In Room', color: VelvetNoir.secondary)
                        else
                          Text(
                            subtitleText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: status != UserStatus.offline
                                  ? _statusColor(status)
                                  : VelvetNoir.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favourite toggle
                  if (onToggleFavorite != null)
                    _TileIconButton(
                      icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFavorite ? Colors.amber : VelvetNoir.onSurfaceVariant,
                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                      onTap: onToggleFavorite,
                    ),
                  // Message
                  if (isConfirmedFriend && onMessage != null)
                    _TileIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      tooltip: 'Message',
                      busy: isMessageBusy,
                      onTap: isMessageBusy ? null : onMessage,
                    ),
                  // Invite to room
                  if (canInvite)
                    _TileIconButton(
                      icon: Icons.meeting_room_outlined,
                      tooltip: 'Invite to your room',
                      color: VelvetNoir.primary,
                      busy: isInviteBusy,
                      onTap: isInviteBusy ? null : onInvite,
                    ),
                  // Main action (remove / add)
                  const SizedBox(width: 2),
                  _TileIconButton(
                    icon: actionIcon,
                    tooltip: actionTooltip,
                    busy: isBusy,
                    onTap: isBusy ? null : onAction,
                    color: actionIcon == Icons.person_remove_outlined
                        ? theme.colorScheme.error.withValues(alpha: 0.8)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TileIconButton extends StatelessWidget {
  const _TileIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
    this.busy = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          icon: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color ?? VelvetNoir.onSurfaceVariant,
                  ),
                )
              : Icon(icon, size: 18, color: color ?? VelvetNoir.onSurfaceVariant),
          onPressed: onTap,
          padding: EdgeInsets.zero,
          splashRadius: 18,
        ),
      ),
    );
  }
}

// ── Incoming friend request tile ─────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: VelvetNoir.primary.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: TextStyle(color: VelvetNoir.primary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: VelvetNoir.onSurface),
                  ),
                  Text(
                    'Sent you a friend request',
                    style: TextStyle(fontSize: 12, color: VelvetNoir.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: isBusy ? null : onDecline,
                  style: TextButton.styleFrom(
                    foregroundColor: VelvetNoir.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: isBusy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: VelvetNoir.primary,
                    foregroundColor: VelvetNoir.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isBusy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: VelvetNoir.surface))
                      : const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
