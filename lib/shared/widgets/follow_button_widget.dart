import 'package:flutter/material.dart';

class FollowButtonWidget extends StatelessWidget {
  final String userId;
  const FollowButtonWidget({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Use Riverpod to determine follow/friend state
    // TODO: Switch between Follow, Following, Friend
    return ElevatedButton(
      onPressed: () {},
      child: const Text('Follow'), // TODO: Change label based on state
    );
  }
}
