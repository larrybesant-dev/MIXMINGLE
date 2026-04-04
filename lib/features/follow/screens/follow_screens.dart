import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/follow_provider.dart';

class FollowersScreen extends ConsumerWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: followersAsync.when(
        data: (followers) {
          if (followers.isEmpty) {
            return const Center(child: Text('No followers yet'));
          }
          return ListView.separated(
            itemCount: followers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final follower = followers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: follower.avatarUrl != null
                      ? CachedNetworkImageProvider(follower.avatarUrl!)
                      : null,
                  child: follower.avatarUrl == null
                      ? Text(follower.username[0].toUpperCase())
                      : null,
                ),
                title: Row(
                  children: [
                    Text(follower.username),
                    if (follower.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified, size: 16, color: Colors.blue),
                      ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => context.push('/profile/${follower.userId}'),
                  child: const Text('View'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class FollowingScreen extends ConsumerWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Following')),
      body: followingAsync.when(
        data: (following) {
          if (following.isEmpty) {
            return const Center(child: Text('Not following anyone yet'));
          }
          return ListView.separated(
            itemCount: following.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = following[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.username[0].toUpperCase())
                      : null,
                ),
                title: Row(
                  children: [
                    Text(user.username),
                    if (user.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified, size: 16, color: Colors.blue),
                      ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => context.push('/profile/${user.userId}'),
                  child: const Text('View'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
