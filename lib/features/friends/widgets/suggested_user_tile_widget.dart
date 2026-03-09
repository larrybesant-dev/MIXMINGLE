import 'package:flutter/material.dart';

class SuggestedUserTileWidget extends StatelessWidget {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final VoidCallback? onFollow;

  const SuggestedUserTileWidget({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    this.onFollow,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
      ),
      title: Text(displayName),
      trailing: ElevatedButton(
        onPressed: onFollow,
        child: const Text('Follow'),
      ),
    );
  }
}
