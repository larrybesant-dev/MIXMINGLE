import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profilePictureUrl;
  const ProfileAvatar({super.key, this.profilePictureUrl});

  bool get _hasImage => profilePictureUrl != null && profilePictureUrl!.trim().isNotEmpty;

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
                  profilePictureUrl!.trim(),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ),
                    );
                  },
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
