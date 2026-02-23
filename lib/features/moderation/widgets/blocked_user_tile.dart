import 'package:flutter/material.dart';

class BlockedUserTile extends StatelessWidget {
  final String blockedUserId;
  final String? displayName;
  final String? avatarUrl;
  final VoidCallback onUnblock;
  final bool isLoading;

  const BlockedUserTile({
    super.key,
    required this.blockedUserId,
    this.displayName,
    this.avatarUrl,
    required this.onUnblock,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: null,
      ),
      title: Text(
        displayName ?? blockedUserId,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: displayName != null
          ? Text(
              blockedUserId,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: onUnblock,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Unblock'),
            ),
    );
  }
}
