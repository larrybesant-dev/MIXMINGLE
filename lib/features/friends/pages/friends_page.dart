import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/social_providers.dart';

class FriendsPage extends ConsumerWidget {
  final String userId;
  const FriendsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider(userId));
    final followers = ref.watch(followersProvider(userId));
    final following = ref.watch(followingProvider(userId));
    // TODO: Suggested users logic

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView(
        children: [
          SectionWidget(title: 'Friends', users: friends.maybeWhen(data: (d) => d, orElse: () => [])),
          SectionWidget(title: 'Followers', users: followers.maybeWhen(data: (d) => d, orElse: () => [])),
          SectionWidget(title: 'Following', users: following.maybeWhen(data: (d) => d, orElse: () => [])),
          const SectionWidget(title: 'Suggested Users', users: []), // TODO: Implement suggested users
        ],
      ),
    );
  }
}

class SectionWidget extends StatelessWidget {
  final String title;
  final List<String> users;
  const SectionWidget({required this.title, required this.users, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...users.map((u) => ListTile(title: Text(u))), // TODO: Load user profile info
      ],
    );
  }
}
