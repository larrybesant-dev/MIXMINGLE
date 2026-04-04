import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String profilePictureUrl;
  final double radius;

  const UserAvatar({required this.profilePictureUrl, this.radius = 24, super.key});

  bool get _hasImage => profilePictureUrl.trim().isNotEmpty;

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
                child: CachedNetworkImage(
                  imageUrl: profilePictureUrl.trim(),
                  width: radius * 2 - 4,
                  height: radius * 2 - 4,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: SizedBox(
                      width: radius,
                      height: radius,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person, color: theme.colorScheme.primary, size: radius),
                ),
              )
            : Icon(Icons.person, color: theme.colorScheme.primary, size: radius),
      ),
    );
  }
}
