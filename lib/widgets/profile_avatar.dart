import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  const ProfileAvatar({super.key, this.imageUrl});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      backgroundColor: theme.colorScheme.surface,
      radius: 28,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary, width: 2),
        ),
        child: imageUrl != null
            ? ClipOval(child: Image.network(imageUrl!, width: 48, height: 48, fit: BoxFit.cover))
            : Icon(Icons.person, color: theme.colorScheme.primary, size: 32),
      ),
    );
  }
}
