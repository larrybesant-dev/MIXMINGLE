import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/room_model.dart';
import '../../feed/providers/presence_providers.dart';
import '../../feed/providers/user_providers.dart';

class RoomInfoPanel extends ConsumerWidget {
  final RoomModel room;
  final String currentUserId;
  final bool isMember;

  const RoomInfoPanel({
    required this.room,
    required this.currentUserId,
    required this.isMember,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostId = room.hostId;
    final coHostIds = room.coHosts;
    final presenceAsync = ref.watch(presenceStreamProvider(room.id));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.name, style: Theme.of(context).textTheme.headlineSmall),
            if ((room.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(room.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
              ),
            Text('Host', style: Theme.of(context).textTheme.titleSmall),
            UserAvatarName(userId: hostId),
            if (coHostIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Co-Hosts', style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: coHostIds.map((id) => UserAvatarName(userId: id ?? '')).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('Participants', style: Theme.of(context).textTheme.titleSmall),
            presenceAsync.when(
              data: (users) => Wrap(
                spacing: 8,
                children: users.map((u) => UserAvatarName(userId: u.userId ?? '')).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading participants: $e'),
            ),
            if ((room.rules ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Room Rules', style: Theme.of(context).textTheme.titleSmall),
              Text(room.rules ?? '', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (room.isLocked && !isMember) ...[
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Implement request to join logic
                  },
                  child: const Text('Request to Join'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UserAvatarName extends ConsumerWidget {
  final String userId;
  const UserAvatarName({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    return userAsync.when(
      data: (user) => Column(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl), radius: 20),
          Text(user.username, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      loading: () => const CircleAvatar(radius: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => const CircleAvatar(radius: 20, child: Icon(Icons.error)),
    );
  }
}
