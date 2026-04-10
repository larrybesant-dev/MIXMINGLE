import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../providers/follow_provider.dart';

class FollowersScreen extends ConsumerWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider(userId));

    return AppPageScaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: AppAsyncValueView<List<dynamic>>(
        value: followersAsync,
        fallbackContext: 'followers',
        isEmpty: (followers) => followers.isEmpty,
        empty: const AppEmptyView(
          title: 'No followers yet',
          icon: Icons.people_outline_rounded,
        ),
        data: (followers) => ListView.separated(
          itemCount: followers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final follower = followers[index];
            return _FollowUserTile(
              avatarUrl: follower.avatarUrl,
              username: follower.username,
              isVerified: follower.isVerified,
              onTap: () => context.push('/profile/${follower.userId}'),
            );
          },
        ),
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

    return AppPageScaffold(
      appBar: AppBar(title: const Text('Following')),
      body: AppAsyncValueView<List<dynamic>>(
        value: followingAsync,
        fallbackContext: 'following',
        isEmpty: (following) => following.isEmpty,
        empty: const AppEmptyView(
          title: 'Not following anyone yet',
          icon: Icons.person_add_alt_rounded,
        ),
        data: (following) => ListView.separated(
          itemCount: following.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = following[index];
            return _FollowUserTile(
              avatarUrl: user.avatarUrl,
              username: user.username,
              isVerified: user.isVerified,
              onTap: () => context.push('/profile/${user.userId}'),
            );
          },
        ),
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({
    required this.avatarUrl,
    required this.username,
    required this.isVerified,
    required this.onTap,
  });

  final String? avatarUrl;
  final String username;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
        child: avatarUrl == null ? Text(username[0].toUpperCase()) : null,
      ),
      title: Row(
        children: [
          Text(username),
          if (isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, size: 16, color: Colors.blue),
            ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: onTap,
        child: const Text('View'),
      ),
    );
  }
}
