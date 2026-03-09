import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/social_providers.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;
  const UserProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followers = ref.watch(followersProvider(userId));
    final following = ref.watch(followingProvider(userId));
    final friends = ref.watch(friendsProvider(userId));
    // TODO: Fetch user profile data from Firestore
    // TODO: Fetch interests, bio, join date, etc.

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          ProfileHeaderWidget(userId: userId),
          ProfileStatsWidget(
            followersCount: followers.maybeWhen(data: (d) => d.length, orElse: () => 0),
            followingCount: following.maybeWhen(data: (d) => d.length, orElse: () => 0),
            friendsCount: friends.maybeWhen(data: (d) => d.length, orElse: () => 0),
          ),
          FollowButtonWidget(userId: userId),
          ProfileRoomsWidget(userId: userId),
          ProfileActivityWidget(userId: userId),
        ],
      ),
    );
  }
}
