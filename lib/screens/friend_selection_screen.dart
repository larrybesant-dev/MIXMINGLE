import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/friend_provider.dart';
import '../models/friend_model.dart';

class FriendSelectionScreen extends ConsumerWidget {
  final void Function(FriendModel friend) onFriendSelected;
  const FriendSelectionScreen({super.key, required this.onFriendSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Friend')),
      body: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(child: Text('No friends found.'));
          }
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: friend.avatarUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl!))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(friend.name ?? friend.friendId ?? 'Unknown'),
                onTap: () => onFriendSelected(friend),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
