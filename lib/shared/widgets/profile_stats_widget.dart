import 'package:flutter/material.dart';

class ProfileStatsWidget extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  const ProfileStatsWidget({required this.followersCount, required this.followingCount, required this.friendsCount, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(children: [const Text('Followers'), Text('$followersCount')]),
        const SizedBox(width: 16),
        Column(children: [const Text('Following'), Text('$followingCount')]),
        const SizedBox(width: 16),
        Column(children: [const Text('Friends'), Text('$friendsCount')]),
      ],
    );
  }
}
