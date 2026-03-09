import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userId;
  const ProfileHeaderWidget({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch profile picture, username, display name, bio, interests, join date
    return Column(
      children: [
        CircleAvatar(radius: 40), // TODO: Load image
        Text('Username'), // TODO: Load username
        Text('Display Name'), // TODO: Load display name
        Text('Bio'), // TODO: Load bio
        Text('Interests'), // TODO: Load interests
        Text('Joined: 2026'), // TODO: Load join date
      ],
    );
  }
}
