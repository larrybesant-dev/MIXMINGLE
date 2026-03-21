import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/room_model.dart';
import '../../room/providers/participant_providers.dart';
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
    final hostAsync = ref.watch(hostProvider(room.id));
    final coHostsAsync = ref.watch(coHostsProvider(room.id));
    final participantCountAsync = ref.watch(participantCountProvider(room.id));
    bool expanded = true;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StatefulBuilder(
        builder: (context, setState) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    tooltip: expanded ? 'Collapse' : 'Expand',
                    onPressed: () => setState(() => expanded = !expanded),
                  ),
                ],
              ),
              AnimatedCrossFade(
                crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 250),
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (room.description != null && room.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(room.description!, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Host', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.2)),
                    ),
                    hostAsync.when(
                      data: (host) => host == null
                          ? const Text('No host')
                          : GestureDetector(
                              onTap: () {
                                // TODO: Show profile modal for host
                              },
                              child: Row(
                                children: [
                                  UserAvatarName(userId: host.userId),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading host: $e'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Co-Hosts', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.2)),
                    ),
                    coHostsAsync.when(
                      data: (cohosts) => cohosts.isEmpty
                          ? const Text('No co-hosts')
                          : Wrap(
                              spacing: 8,
                              children: cohosts.map((c) => GestureDetector(
                                onTap: () {
                                  // TODO: Show profile modal for cohost
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    UserAvatarName(userId: c.userId),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Co-host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading co-hosts: $e'),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Participants', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.2)),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Open participant list modal
                      },
                      child: participantCountAsync.when(
                        data: (count) => Text('$count in the room', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error loading count: $e'),
                      ),
                    ),
                    if (room.rules != null && room.rules!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Room Rules', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.2)),
                      ),
                      Text(room.rules!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (room.isLocked)
                          Row(
                            children: [
                              const Icon(Icons.lock, size: 18, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('Locked', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        if (room.slowModeSeconds != null && room.slowModeSeconds! > 0) ...[
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 18, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('Slow mode: ${room.slowModeSeconds}s', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
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
                    // Optional enhancements row
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (isMember && hostAsync.asData?.value != null && ref.read(isHostProvider(hostAsync.asData!.value)))
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Invite co-host
                            },
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Invite Co-host'),
                          ),
                        if (!isMember)
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Report room
                            },
                            icon: const Icon(Icons.flag),
                            label: const Text('Report Room'),
                          ),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Share room link
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
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
          CircleAvatar(backgroundImage: NetworkImage(user?.avatarUrl ?? ''), radius: 20),
          Text(user?.username ?? 'Unknown', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      loading: () => const CircleAvatar(radius: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => const CircleAvatar(radius: 20, child: Icon(Icons.error)),
    );
  }
}
