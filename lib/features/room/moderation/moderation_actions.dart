import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'moderation_provider.dart';

class ModerationActions extends ConsumerWidget {
  final String roomId;
  final String userId;

  const ModerationActions({required this.roomId, required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moderationService = ref.read(moderationServiceProvider);
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.block),
          onPressed: () => moderationService.reportUser(userId, 'Violation'),
          tooltip: 'Report User',
        ),
        IconButton(
          icon: Icon(Icons.block),
          onPressed: () => moderationService.blockUser(userId),
          tooltip: 'Block User',
        ),
      ],
    );
  }
}
