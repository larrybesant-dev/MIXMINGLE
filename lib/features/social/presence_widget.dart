import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presence_provider.dart';

class PresenceWidget extends ConsumerWidget {
  final String userId;

  const PresenceWidget({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceService = ref.read(presenceServiceProvider);
    return StreamBuilder<bool>(
      stream: presenceService.listenToPresence(userId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        return Row(
          children: [
            Icon(
              isOnline ? Icons.circle : Icons.circle_outlined,
              color: isOnline ? Colors.green : Colors.grey,
              size: 12,
            ),
            SizedBox(width: 4),
            Semantics(
              label: isOnline ? 'User is online' : 'User is offline',
              child: Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green[800] : Colors.grey[800], // Improved contrast
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
