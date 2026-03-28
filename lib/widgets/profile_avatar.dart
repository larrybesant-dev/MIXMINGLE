import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  const ProfileAvatar({super.key, this.imageUrl});

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

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
        child: _hasImage
            ? ClipOval(
                child: Image.network(
                  imageUrl!.trim(),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person, color: theme.colorScheme.primary, size: 32);
                  },
                ),
              )
            : Icon(Icons.person, color: theme.colorScheme.primary, size: 32),
      ),
    );
  }
}
