import 'package:flutter/material.dart';

class ProfileStatsWidget extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  const ProfileStatsWidget({required this.followersCount, required this.followingCount, required this.friendsCount, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(children: [Text('Followers'), Text('$followersCount')]),
        SizedBox(width: 16),
        Column(children: [Text('Following'), Text('$followingCount')]),
        SizedBox(width: 16),
        Column(children: [Text('Friends'), Text('$friendsCount')]),
      ],
    );
  }
}
