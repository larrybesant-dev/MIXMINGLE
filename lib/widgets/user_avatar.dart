import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final double radius;

  const UserAvatar({required this.avatarUrl, this.radius = 24, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      backgroundColor: theme.colorScheme.surface,
      radius: radius,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary, width: 2),
        ),
        child: ClipOval(
          child: Image.network(avatarUrl, width: radius * 2 - 4, height: radius * 2 - 4, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
