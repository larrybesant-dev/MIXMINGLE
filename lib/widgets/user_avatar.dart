import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final double radius;

  const UserAvatar({required this.avatarUrl, this.radius = 24, super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: NetworkImage(avatarUrl),
      radius: radius,
    );
  }
}
