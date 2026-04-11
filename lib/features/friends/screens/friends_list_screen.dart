import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout.dart';
import '../../../models/user_model.dart';
import '../../../presentation/providers/friend_provider.dart';
import '../../../presentation/providers/user_provider.dart';
import '../../../services/notification_service.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../messaging/providers/messaging_provider.dart';
import '../models/friend_roster_entry.dart';
import '../providers/friends_providers.dart';
import '../widgets/friend_tile.dart';

class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPageScaffold(
      backgroundColor: VelvetNoir.surface,
      appBar: _FriendsAppBar(),
      body: FriendsPaneView(showHeader: false),
    );
  }
}

class FriendsPaneView extends ConsumerWidget {
  const FriendsPaneView({
    super.key,
    this.showHeader = true,
  });

  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(friendRosterProvider);
    final currentUser = ref.watch(userProvider);
    final myPresence = ref.watch(currentUserPresenceProvider).valueOrNull;
    final myRoomId = myPresence?.inRoom;

    return rosterAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: VelvetNoir.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load friends: $error',
              style: const TextStyle(color: VelvetNoir.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (entries) {
          final inRoomEntries = entries
              .where((entry) => (entry.roomId ?? '').isNotEmpty)
              .toList(growable: false);
          final onlineEntries = entries
              .where((entry) => entry.isOnline && (entry.roomId ?? '').isEmpty)
              .toList(growable: false);
          final offlineEntries = entries
              .where((entry) => !entry.isOnline)
              .toList(growable: false);

          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No friends yet.',
                  style: TextStyle(color: VelvetNoir.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.pageHorizontalPadding,
              showHeader ? 24 : 16,
              context.pageHorizontalPadding,
              16,
            ),
            children: [
              if (showHeader) ...[
                Text(
                  'Friends',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: VelvetNoir.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Desktop uses a persistent roster plus embedded friend panes.',
                  style: TextStyle(
                    color: VelvetNoir.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _SectionHeader(label: 'ONLINE'),
              const SizedBox(height: 12),
              _buildSection(
                context,
                entries: onlineEntries,
                emptyLabel: 'No friends online right now.',
                itemBuilder: (entry) => FriendTile(
                  key: ValueKey('online-${entry.friendId}'),
                  user: entry.user,
                  statusLabel: 'Online',
                  statusColor: const Color(0xFF22C55E),
                  actions: [
                    FriendTileAction(
                      label: 'Message',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => _openConversation(context, ref, currentUser, entry.user),
                    ),
                    if ((myRoomId ?? '').isNotEmpty)
                      FriendTileAction(
                        label: 'Invite',
                        icon: Icons.mail_outline_rounded,
                        onPressed: () => _inviteFriend(
                          context,
                          currentUser: currentUser,
                          friend: entry.user,
                          roomId: myRoomId!,
                        ),
                      ),
                  ],
                  onTap: () => context.go('/profile/${entry.friendId}'),
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(label: 'IN ROOMS'),
              const SizedBox(height: 12),
              _buildSection(
                context,
                entries: inRoomEntries,
                emptyLabel: 'No friends are in rooms right now.',
                itemBuilder: (entry) => FriendTile(
                  key: ValueKey('room-${entry.friendId}'),
                  user: entry.user,
                  statusLabel: 'In room ${entry.roomId}',
                  statusColor: VelvetNoir.primary,
                  statusIcon: Icons.mic_rounded,
                  actions: [
                    FriendTileAction(
                      label: 'Join Room',
                      icon: Icons.meeting_room_rounded,
                      onPressed: () => context.go('/room/${entry.roomId}'),
                    ),
                    FriendTileAction(
                      label: 'Message',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => _openConversation(context, ref, currentUser, entry.user),
                    ),
                  ],
                  onTap: () => context.go('/profile/${entry.friendId}'),
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(label: 'OFFLINE'),
              const SizedBox(height: 12),
              _buildSection(
                context,
                entries: offlineEntries,
                emptyLabel: 'No friends are offline.',
                itemBuilder: (entry) => FriendTile(
                  key: ValueKey('offline-${entry.friendId}'),
                  user: entry.user,
                  statusLabel: _lastSeenLabel(entry),
                  statusColor: VelvetNoir.onSurfaceVariant,
                  actions: const [],
                  onTap: () => context.go('/profile/${entry.friendId}'),
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildSection(
    BuildContext context, {
    required List<FriendRosterEntry> entries,
    required String emptyLabel,
    required Widget Function(FriendRosterEntry entry) itemBuilder,
  }) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: VelvetNoir.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VelvetNoir.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Text(
          emptyLabel,
          style: const TextStyle(
            color: VelvetNoir.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < entries.length; index += 1) ...[
          itemBuilder(entries[index]),
          if (index != entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _openConversation(
    BuildContext context,
    WidgetRef ref,
    UserModel? currentUser,
    UserModel friend,
  ) async {
    if (currentUser == null) return;

    try {
      final conversationId = await ref.read(messagingControllerProvider).createDirectConversation(
            userId1: currentUser.id,
            user1Name: currentUser.username,
            user1AvatarUrl: currentUser.avatarUrl,
            userId2: friend.id,
            user2Name: friend.username,
            user2AvatarUrl: friend.avatarUrl,
          );
      if (!context.mounted) return;
      context.go('/messages/$conversationId');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $error')),
      );
    }
  }

  Future<void> _inviteFriend(
    BuildContext context, {
    required UserModel? currentUser,
    required UserModel friend,
    required String roomId,
  }) async {
    if (currentUser == null) return;

    try {
      await NotificationService().sendRoomInviteToFriends(
        friendIds: [friend.id],
        inviterId: currentUser.id,
        inviterName: currentUser.username,
        roomId: roomId,
        roomName: "${currentUser.username}'s room",
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite sent to ${friend.username}.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send invite: $error')),
      );
    }
  }

  String _lastSeenLabel(FriendRosterEntry entry) {
    final lastSeen = entry.lastSeen;
    if (lastSeen == null) return 'Offline';
    final delta = DateTime.now().difference(lastSeen);
    if (delta.inMinutes < 1) return 'Last seen just now';
    if (delta.inMinutes < 60) return 'Last seen ${delta.inMinutes}m ago';
    if (delta.inHours < 24) return 'Last seen ${delta.inHours}h ago';
    return 'Last seen ${delta.inDays}d ago';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: VelvetNoir.primary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FriendsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FriendsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: VelvetNoir.surface,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Friends',
        style: TextStyle(
          color: VelvetNoir.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}