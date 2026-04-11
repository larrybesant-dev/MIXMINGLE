import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme.dart';
import '../../core/utils/network_image_url.dart';
import '../../features/friends/models/friend_roster_entry.dart';
import '../../features/friends/providers/friends_providers.dart';
import '../../features/messaging/models/conversation_model.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../models/presence_model.dart';
import '../../models/user_model.dart';
import '../../presentation/providers/user_provider.dart';
import '../../services/moderation_service.dart';
import '../../services/notification_service.dart';

class DesktopMessengerShell extends ConsumerStatefulWidget {
  const DesktopMessengerShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  ConsumerState<DesktopMessengerShell> createState() =>
      _DesktopMessengerShellState();
}

class _DesktopMessengerShellState extends ConsumerState<DesktopMessengerShell> {
  late final TextEditingController _searchController;
  String _query = '';
  bool _showOffline = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    if (currentUser == null) {
      return widget.child;
    }
    final sideRailWidth = context.screenWidth >= AppBreakpoints.expanded ? 288.0 : 256.0;

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: _MessengerSidebar(
            currentUser: currentUser,
            searchController: _searchController,
            query: _query,
            showOffline: _showOffline,
            onToggleOffline: () => setState(() => _showOffline = !_showOffline),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: VelvetNoir.surface),
            child: SafeArea(child: widget.child),
          ),
        ),
        SizedBox(
          width: sideRailWidth,
          child: _DesktopSocialRail(currentUser: currentUser),
        ),
      ],
    );
  }
}

class _MessengerSidebar extends ConsumerWidget {
  const _MessengerSidebar({
    required this.currentUser,
    required this.searchController,
    required this.query,
    required this.showOffline,
    required this.onToggleOffline,
  });

  final UserModel currentUser;
  final TextEditingController searchController;
  final String query;
  final bool showOffline;
  final VoidCallback onToggleOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(friendRosterProvider).valueOrNull ?? const <FriendRosterEntry>[];
    final conversations =
        ref.watch(conversationsStreamProvider(currentUser.id)).valueOrNull ?? const <Conversation>[];
    final favoriteIds =
        ref.watch(favoriteFriendIdsProvider).valueOrNull ?? const <String>{};

    final filteredRoster = roster.where((entry) {
      if (query.isEmpty) return true;
      final conversation = _directConversationForFriend(conversations, currentUser.id, entry.friendId);
      final preview = (conversation?.lastMessagePreview ?? '').toLowerCase();
      return entry.user.username.toLowerCase().contains(query) ||
          preview.contains(query);
    }).toList(growable: false)
      ..sort(_compareRosterEntries);

    final favorites = filteredRoster
        .where((entry) => favoriteIds.contains(entry.friendId))
        .toList(growable: false);
    final online = filteredRoster
        .where((entry) =>
            !favoriteIds.contains(entry.friendId) &&
            entry.isOnline)
        .toList(growable: false);
    final offline = filteredRoster
        .where((entry) =>
            !favoriteIds.contains(entry.friendId) &&
            !entry.isOnline)
        .toList(growable: false);

    final recentChats = conversations
        .where((conversation) => conversation.type == 'direct')
        .toList(growable: false)
      ..sort((a, b) => (b.lastMessageAt ?? b.createdAt)
          .compareTo(a.lastMessageAt ?? a.createdAt));

    return Container(
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceLow,
        border: Border(
          right: BorderSide(
            color: VelvetNoir.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messenger',
                    style: GoogleFonts.playfairDisplay(
                      color: VelvetNoir.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'See people. Click. Talk.',
                    style: GoogleFonts.raleway(
                      color: VelvetNoir.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SearchField(controller: searchController),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                children: [
                  _SidebarSection(
                    title: 'Favorites',
                    count: favorites.length,
                    child: favorites.isEmpty
                        ? const _SidebarEmptyState(label: 'No favorite friends yet.')
                        : Column(
                            children: favorites
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _FriendRosterRow(
                                      currentUser: currentUser,
                                      entry: entry,
                                      conversation: _directConversationForFriend(
                                        conversations,
                                        currentUser.id,
                                        entry.friendId,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  ),
                  _SidebarSection(
                    title: 'Online',
                    count: online.length,
                    child: online.isEmpty
                        ? const _SidebarEmptyState(label: 'Nobody online right now.')
                        : Column(
                            children: online
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _FriendRosterRow(
                                      currentUser: currentUser,
                                      entry: entry,
                                      conversation: _directConversationForFriend(
                                        conversations,
                                        currentUser.id,
                                        entry.friendId,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  ),
                  _SidebarSection(
                    title: 'Recent Chats',
                    count: recentChats.length,
                    child: recentChats.isEmpty
                        ? const _SidebarEmptyState(label: 'Your recent chats show up here.')
                        : Column(
                            children: recentChats.take(8).map((conversation) {
                              final friendId = conversation.participantIds.firstWhere(
                                (id) => id != currentUser.id,
                                orElse: () => '',
                              );
                              final entry = filteredRoster.cast<FriendRosterEntry?>().firstWhere(
                                    (candidate) => candidate?.friendId == friendId,
                                    orElse: () => null,
                                  );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _RecentConversationRow(
                                  currentUser: currentUser,
                                  conversation: conversation,
                                  entry: entry,
                                ),
                              );
                            }).toList(growable: false),
                          ),
                  ),
                  _SidebarSection(
                    title: 'Offline',
                    count: offline.length,
                    trailing: TextButton(
                      onPressed: onToggleOffline,
                      child: Text(showOffline ? 'Hide' : 'Show'),
                    ),
                    child: !showOffline
                        ? const _SidebarEmptyState(label: 'Offline friends collapsed.')
                        : offline.isEmpty
                            ? const _SidebarEmptyState(label: 'No offline friends.')
                            : Column(
                                children: offline
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _FriendRosterRow(
                                          currentUser: currentUser,
                                          entry: entry,
                                          conversation: _directConversationForFriend(
                                            conversations,
                                            currentUser.id,
                                            entry.friendId,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMessengerHome extends ConsumerWidget {
  const _DesktopMessengerHome({required this.currentUser});

  final UserModel currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsStreamProvider(currentUser.id));
    final requestsCount =
        ref.watch(requestsStreamProvider(currentUser.id)).valueOrNull?.length ?? 0;

    return Container(
      color: VelvetNoir.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inbox',
                          style: GoogleFonts.playfairDisplay(
                            color: VelvetNoir.onSurface,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          requestsCount > 0
                              ? '$requestsCount pending request${requestsCount == 1 ? '' : 's'} waiting for review.'
                              : 'Your live conversations and active threads stay here.',
                          style: GoogleFonts.raleway(
                            color: VelvetNoir.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/messages/new'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('New message'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      VelvetNoir.surfaceHigh,
                      VelvetNoir.surfaceContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: VelvetNoir.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your social gravity lives here.',
                            style: GoogleFonts.playfairDisplay(
                              color: VelvetNoir.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Keep the roster open, jump straight into conversations, and use rooms as an extension of chat instead of a separate mode.',
                            style: GoogleFonts.raleway(
                              color: VelvetNoir.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HeroActionChip(
                          icon: Icons.people_alt_outlined,
                          label: 'Friends',
                          onTap: () => context.go('/friends'),
                        ),
                        _HeroActionChip(
                          icon: Icons.meeting_room_outlined,
                          label: 'Rooms',
                          onTap: () => context.go('/rooms'),
                        ),
                        _HeroActionChip(
                          icon: Icons.notifications_none_rounded,
                          label: 'Alerts',
                          onTap: () => context.go('/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: conversationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: VelvetNoir.primary),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Could not load conversations: $error',
                      style: const TextStyle(color: VelvetNoir.onSurfaceVariant),
                    ),
                  ),
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 44,
                              color: VelvetNoir.primary,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No conversations yet',
                              style: GoogleFonts.playfairDisplay(
                                color: VelvetNoir.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pick someone from the left roster to start talking.',
                              style: GoogleFonts.raleway(
                                color: VelvetNoir.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final unread = conversation.hasUnreadMessages(currentUser.id);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.go('/messages/${conversation.id}'),
                            borderRadius: BorderRadius.circular(18),
                            child: Ink(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: VelvetNoir.surfaceHigh,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: unread
                                      ? VelvetNoir.primary.withValues(alpha: 0.45)
                                      : VelvetNoir.outlineVariant.withValues(alpha: 0.32),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: VelvetNoir.surfaceHighest,
                                    child: Text(
                                      conversation
                                              .getDisplayName(currentUser.id)
                                              .characters
                                              .first
                                              .toUpperCase(),
                                      style: const TextStyle(
                                        color: VelvetNoir.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                conversation.getDisplayName(currentUser.id),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: VelvetNoir.onSurface,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatConversationTime(
                                                conversation.lastMessageAt ??
                                                    conversation.createdAt,
                                              ),
                                              style: const TextStyle(
                                                color: VelvetNoir.onSurfaceVariant,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          conversation.lastMessagePreview ??
                                              'No messages yet',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: unread
                                                ? VelvetNoir.onSurface
                                                : VelvetNoir.onSurfaceVariant,
                                            fontSize: 13,
                                            fontWeight: unread
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: VelvetNoir.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSocialRail extends ConsumerWidget {
  const _DesktopSocialRail({required this.currentUser});

  final UserModel currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(friendRosterProvider).valueOrNull ?? const <FriendRosterEntry>[];
    final conversations =
        ref.watch(conversationsStreamProvider(currentUser.id)).valueOrNull ?? const <Conversation>[];
    final myPresence = ref.watch(currentUserPresenceProvider).valueOrNull;
    final requestCount =
        ref.watch(requestsStreamProvider(currentUser.id)).valueOrNull?.length ?? 0;

    final onlineCount = roster.where((entry) => entry.isOnline).length;
    final inRoomCount = roster.where((entry) => (entry.roomId ?? '').isNotEmpty).length;
    final unreadCount = conversations.where((c) => c.hasUnreadMessages(currentUser.id)).length;

    return Container(
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceLow,
        border: Border(
          left: BorderSide(
            color: VelvetNoir.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _RailCard(
              title: 'Presence',
              child: Column(
                children: [
                  _StatRow(label: 'Online friends', value: '$onlineCount'),
                  _StatRow(label: 'Friends in rooms', value: '$inRoomCount'),
                  _StatRow(label: 'Unread chats', value: '$unreadCount'),
                  _StatRow(label: 'Requests', value: '$requestCount'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _RailCard(
              title: 'Your status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(
                    color: _presenceColor(myPresence?.status, myPresence?.inRoom),
                    label: _presenceLabel(myPresence),
                  ),
                  if ((myPresence?.inRoom ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/room/${myPresence!.inRoom}'),
                      icon: const Icon(Icons.meeting_room_outlined),
                      label: const Text('Rejoin current room'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _RailCard(
              title: 'Shortcuts',
              child: Column(
                children: [
                  _RailShortcut(
                    icon: Icons.people_outline,
                    label: 'Friends',
                    onTap: () => context.go('/friends'),
                  ),
                  _RailShortcut(
                    icon: Icons.meeting_room_outlined,
                    label: 'Browse rooms',
                    onTap: () => context.go('/rooms'),
                  ),
                  _RailShortcut(
                    icon: Icons.person_outline,
                    label: 'Your profile',
                    onTap: () => context.go('/profile'),
                  ),
                  _RailShortcut(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => context.go('/notifications'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRosterRow extends ConsumerWidget {
  const _FriendRosterRow({
    required this.currentUser,
    required this.entry,
    required this.conversation,
  });

  final UserModel currentUser;
  final FriendRosterEntry entry;
  final Conversation? conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = conversation?.lastMessagePreview ?? _presenceLabel(entry.presence);
    final timestamp = conversation?.lastMessageAt ?? entry.lastSeen;
    final unread = conversation?.hasUnreadMessages(currentUser.id) ?? false;
    final avatarUrl = sanitizeNetworkImageUrl(entry.user.avatarUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openConversation(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? VelvetNoir.primary.withValues(alpha: 0.42)
                  : VelvetNoir.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: VelvetNoir.surfaceHighest,
                    backgroundImage:
                        avatarUrl == null ? null : CachedNetworkImageProvider(avatarUrl),
                    child: avatarUrl == null
                        ? Text(
                            entry.user.username.isNotEmpty
                                ? entry.user.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: VelvetNoir.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: VelvetNoir.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: VelvetNoir.surface, width: 2),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _presenceColor(entry.presence.status, entry.roomId),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: VelvetNoir.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            _formatConversationTime(timestamp),
                            style: const TextStyle(
                              color: VelvetNoir.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread ? VelvetNoir.onSurface : VelvetNoir.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: VelvetNoir.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              PopupMenuButton<_FriendMenuAction>(
                tooltip: 'Friend actions',
                color: VelvetNoir.surfaceHigh,
                onSelected: (value) => _handleAction(context, ref, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _FriendMenuAction.message,
                    child: Text('Message'),
                  ),
                  const PopupMenuItem(
                    value: _FriendMenuAction.viewProfile,
                    child: Text('View profile'),
                  ),
                  if ((entry.roomId ?? '').isNotEmpty)
                    const PopupMenuItem(
                      value: _FriendMenuAction.joinRoom,
                      child: Text('Join room'),
                    ),
                  if ((_currentRoomId(ref) ?? '').isNotEmpty &&
                      _currentRoomId(ref) != entry.roomId)
                    const PopupMenuItem(
                      value: _FriendMenuAction.inviteToRoom,
                      child: Text('Invite to room'),
                    ),
                  const PopupMenuItem(
                    value: _FriendMenuAction.blockUser,
                    child: Text('Block user'),
                  ),
                ],
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: VelvetNoir.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _currentRoomId(WidgetRef ref) {
    return ref.read(currentUserPresenceProvider).valueOrNull?.inRoom;
  }

  Future<void> _openConversation(BuildContext context, WidgetRef ref) async {
    final existingId = conversation?.id;
    if (existingId != null) {
      if (context.mounted) context.go('/messages/$existingId');
      return;
    }

    try {
      final conversationId = await ref.read(messagingControllerProvider).createDirectConversation(
            userId1: currentUser.id,
            user1Name: currentUser.username,
            user1AvatarUrl: currentUser.avatarUrl,
            userId2: entry.user.id,
            user2Name: entry.user.username,
            user2AvatarUrl: entry.user.avatarUrl,
          );
      if (context.mounted) context.go('/messages/$conversationId');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $error')),
      );
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _FriendMenuAction action,
  ) async {
    switch (action) {
      case _FriendMenuAction.message:
        await _openConversation(context, ref);
        return;
      case _FriendMenuAction.viewProfile:
        if (context.mounted) context.go('/profile/${entry.friendId}');
        return;
      case _FriendMenuAction.joinRoom:
        final roomId = entry.roomId;
        if (roomId != null && context.mounted) context.go('/room/$roomId');
        return;
      case _FriendMenuAction.inviteToRoom:
        final roomId = _currentRoomId(ref);
        if (roomId == null || roomId.isEmpty) return;
        try {
          await NotificationService().sendRoomInviteToFriends(
            friendIds: [entry.friendId],
            inviterId: currentUser.id,
            inviterName: currentUser.username,
            roomId: roomId,
            roomName: "${currentUser.username}'s room",
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invite sent to ${entry.user.username}.')),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not send invite: $error')),
          );
        }
        return;
      case _FriendMenuAction.blockUser:
        try {
          await ModerationService().blockUser(entry.friendId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${entry.user.username} blocked.')),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not block user: $error')),
          );
        }
        return;
    }
  }
}

class _RecentConversationRow extends StatelessWidget {
  const _RecentConversationRow({
    required this.currentUser,
    required this.conversation,
    required this.entry,
  });

  final UserModel currentUser;
  final Conversation conversation;
  final FriendRosterEntry? entry;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.hasUnreadMessages(currentUser.id);
    final avatarUrl = sanitizeNetworkImageUrl(entry?.user.avatarUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/messages/${conversation.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: VelvetNoir.surfaceHighest,
                backgroundImage:
                    avatarUrl == null ? null : CachedNetworkImageProvider(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        conversation
                            .getDisplayName(currentUser.id)
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: VelvetNoir.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.getDisplayName(currentUser.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VelvetNoir.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessagePreview ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VelvetNoir.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: VelvetNoir.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.count,
    required this.child,
    this.trailing,
  });

  final String title;
  final int count;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title ($count)',
                  style: GoogleFonts.raleway(
                    color: VelvetNoir.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SidebarEmptyState extends StatelessWidget {
  const _SidebarEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VelvetNoir.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VelvetNoir.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: VelvetNoir.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.raleway(
          color: VelvetNoir.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search friends and chats',
          hintStyle: GoogleFonts.raleway(
            color: VelvetNoir.onSurfaceVariant,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: VelvetNoir.onSurfaceVariant,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: VelvetNoir.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: VelvetNoir.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: VelvetNoir.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: VelvetNoir.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: VelvetNoir.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.raleway(
              color: VelvetNoir.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RailShortcut extends StatelessWidget {
  const _RailShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: VelvetNoir.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: VelvetNoir.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: VelvetNoir.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: VelvetNoir.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: VelvetNoir.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: VelvetNoir.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _FriendMenuAction {
  message,
  viewProfile,
  joinRoom,
  inviteToRoom,
  blockUser,
}

Conversation? _directConversationForFriend(
  List<Conversation> conversations,
  String currentUserId,
  String friendId,
) {
  for (final conversation in conversations) {
    if (conversation.type != 'direct') continue;
    final otherId = conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId == friendId) return conversation;
  }
  return null;
}

int _compareRosterEntries(FriendRosterEntry left, FriendRosterEntry right) {
  final leftOnlineWeight = left.roomId != null && left.roomId!.isNotEmpty
      ? 2
      : left.isOnline
          ? 1
          : 0;
  final rightOnlineWeight = right.roomId != null && right.roomId!.isNotEmpty
      ? 2
      : right.isOnline
          ? 1
          : 0;

  if (leftOnlineWeight != rightOnlineWeight) {
    return rightOnlineWeight.compareTo(leftOnlineWeight);
  }

  final leftSeen = left.lastSeen;
  final rightSeen = right.lastSeen;
  if (leftSeen != null && rightSeen != null) {
    final compare = rightSeen.compareTo(leftSeen);
    if (compare != 0) return compare;
  }

  return left.user.username.toLowerCase().compareTo(
        right.user.username.toLowerCase(),
      );
}

Color _presenceColor(UserStatus? status, String? roomId) {
  if ((roomId ?? '').isNotEmpty) return VelvetNoir.primary;
  switch (status) {
    case UserStatus.online:
      return const Color(0xFF22C55E);
    case UserStatus.away:
      return const Color(0xFFF59E0B);
    case UserStatus.dnd:
      return const Color(0xFFEF4444);
    case UserStatus.offline:
    case null:
      return const Color(0xFF6B7280);
  }
}

String _presenceLabel(PresenceModel? presence) {
  if (presence == null) return 'Offline';
  if ((presence.inRoom ?? '').isNotEmpty) return 'In room ${presence.inRoom}';
  switch (presence.status) {
    case UserStatus.online:
      return 'Online';
    case UserStatus.away:
      return 'Away';
    case UserStatus.dnd:
      return 'Busy';
    case UserStatus.offline:
      if (presence.lastSeen == null) return 'Offline';
      final delta = DateTime.now().difference(presence.lastSeen!);
      if (delta.inMinutes < 1) return 'Last seen just now';
      if (delta.inMinutes < 60) return 'Last seen ${delta.inMinutes}m ago';
      if (delta.inHours < 24) return 'Last seen ${delta.inHours}h ago';
      return 'Last seen ${delta.inDays}d ago';
  }
}

String _formatConversationTime(DateTime value) {
  final now = DateTime.now();
  final difference = now.difference(value);
  if (difference.inMinutes < 1) return 'now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${value.month}/${value.day}';
}

class _DesktopFriendsCenter extends ConsumerWidget {
  const _DesktopFriendsCenter({required this.currentUser});

  final UserModel currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(friendRosterProvider);
    final myPresence = ref.watch(currentUserPresenceProvider).valueOrNull;
    final myRoomId = myPresence?.inRoom;

    return Container(
      color: VelvetNoir.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: rosterAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: VelvetNoir.primary),
            ),
            error: (error, _) => Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: VelvetNoir.surfaceHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: VelvetNoir.secondary.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 40,
                      color: VelvetNoir.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Friends are unavailable right now',
                      style: GoogleFonts.playfairDisplay(
                        color: VelvetNoir.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        color: VelvetNoir.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (entries) {
              final favoritesAsync = ref.watch(favoriteFriendIdsProvider);
              final favoriteIds = favoritesAsync.valueOrNull ?? const <String>{};
              final favorites = entries
                  .where((entry) => favoriteIds.contains(entry.friendId))
                  .toList(growable: false);
              final inRooms = entries
                  .where((entry) => (entry.roomId ?? '').isNotEmpty)
                  .toList(growable: false);
              final online = entries
                  .where((entry) =>
                      entry.isOnline &&
                      (entry.roomId ?? '').isEmpty &&
                      !favoriteIds.contains(entry.friendId))
                  .toList(growable: false);
              final offline = entries
                  .where((entry) => !entry.isOnline)
                  .toList(growable: false);

              return ListView(
                children: [
                  Text(
                    'Friends',
                    style: GoogleFonts.playfairDisplay(
                      color: VelvetNoir.onSurface,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your roster stays visible on the left. Use this center pane for fast actions and room jumps.',
                    style: GoogleFonts.raleway(
                      color: VelvetNoir.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DesktopFriendSection(
                    title: 'Favorites',
                    entries: favorites,
                    currentUser: currentUser,
                    myRoomId: myRoomId,
                    emptyLabel: 'No favorite friends yet.',
                  ),
                  const SizedBox(height: 20),
                  _DesktopFriendSection(
                    title: 'In Rooms',
                    entries: inRooms,
                    currentUser: currentUser,
                    myRoomId: myRoomId,
                    emptyLabel: 'No friends are in rooms right now.',
                  ),
                  const SizedBox(height: 20),
                  _DesktopFriendSection(
                    title: 'Online',
                    entries: online,
                    currentUser: currentUser,
                    myRoomId: myRoomId,
                    emptyLabel: 'No friends online right now.',
                  ),
                  const SizedBox(height: 20),
                  _DesktopFriendSection(
                    title: 'Offline',
                    entries: offline,
                    currentUser: currentUser,
                    myRoomId: myRoomId,
                    emptyLabel: 'No offline friends.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DesktopFriendSection extends StatelessWidget {
  const _DesktopFriendSection({
    required this.title,
    required this.entries,
    required this.currentUser,
    required this.myRoomId,
    required this.emptyLabel,
  });

  final String title;
  final List<FriendRosterEntry> entries;
  final UserModel currentUser;
  final String? myRoomId;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: VelvetNoir.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${entries.length})',
            style: GoogleFonts.raleway(
              color: VelvetNoir.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(
                color: VelvetNoir.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DesktopFriendCard(
                  currentUser: currentUser,
                  myRoomId: myRoomId,
                  entry: entry,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DesktopFriendCard extends ConsumerWidget {
  const _DesktopFriendCard({
    required this.currentUser,
    required this.myRoomId,
    required this.entry,
  });

  final UserModel currentUser;
  final String? myRoomId;
  final FriendRosterEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = sanitizeNetworkImageUrl(entry.user.avatarUrl);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: VelvetNoir.surfaceHighest,
            backgroundImage:
                avatarUrl == null ? null : CachedNetworkImageProvider(avatarUrl),
            child: avatarUrl == null
                ? Text(
                    entry.user.username.isNotEmpty
                        ? entry.user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: VelvetNoir.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.user.username,
                  style: const TextStyle(
                    color: VelvetNoir.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _presenceLabel(entry.presence),
                  style: TextStyle(
                    color: _presenceColor(entry.presence.status, entry.roomId),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/profile/${entry.friendId}'),
                icon: const Icon(Icons.person_outline, size: 16),
                label: const Text('Profile'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final conversationId = await ref
                        .read(messagingControllerProvider)
                        .createDirectConversation(
                          userId1: currentUser.id,
                          user1Name: currentUser.username,
                          user1AvatarUrl: currentUser.avatarUrl,
                          userId2: entry.user.id,
                          user2Name: entry.user.username,
                          user2AvatarUrl: entry.user.avatarUrl,
                        );
                    if (context.mounted) {
                      context.go('/messages/$conversationId');
                    }
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open chat: $error')),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Message'),
              ),
              if ((entry.roomId ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => context.go('/room/${entry.roomId}'),
                  icon: const Icon(Icons.meeting_room_outlined, size: 16),
                  label: const Text('Join room'),
                ),
              if ((myRoomId ?? '').isNotEmpty && myRoomId != entry.roomId)
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await NotificationService().sendRoomInviteToFriends(
                        friendIds: [entry.friendId],
                        inviterId: currentUser.id,
                        inviterName: currentUser.username,
                        roomId: myRoomId!,
                        roomName: "${currentUser.username}'s room",
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invite sent to ${entry.user.username}.')),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not send invite: $error')),
                      );
                    }
                  },
                  icon: const Icon(Icons.mail_outline_rounded, size: 16),
                  label: const Text('Invite'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}