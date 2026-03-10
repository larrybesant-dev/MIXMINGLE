import 'package:flutter/material.dart';

class FriendTileWidget extends StatelessWidget {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final bool isFriend;
  final VoidCallback? onTap;

  const FriendTileWidget({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.isFriend,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
      ),
      title: Text(displayName),
      subtitle: Text(isFriend ? 'Friend' : 'Not Friend'),
      onTap: onTap,
    );
  }
}
