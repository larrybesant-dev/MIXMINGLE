import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final double radius;

  const UserAvatar({required this.avatarUrl, this.radius = 24, super.key});

  bool get _hasImage => avatarUrl.trim().isNotEmpty;

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
        child: _hasImage
            ? ClipOval(
                child: Image.network(
                  avatarUrl.trim(),
                  width: radius * 2 - 4,
                  height: radius * 2 - 4,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person, color: theme.colorScheme.primary, size: radius);
                  },
                ),
              )
            : Icon(Icons.person, color: theme.colorScheme.primary, size: radius),
      ),
    );
  }
}
