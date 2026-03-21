import 'package:flutter/material.dart';
import '../../../models/user.dart';

class TrendingUserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const TrendingUserCard({required this.user, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(user.avatarUrl),
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            user.username,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${user.coinBalance} coins',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
