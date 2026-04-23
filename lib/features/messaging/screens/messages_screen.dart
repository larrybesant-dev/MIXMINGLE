import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../panes/MessageModel_pane_view.dart';
import '../providers/messaging_provider.dart';

class MessageModelScreen extends ConsumerWidget {
  const MessageModelScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  final String userId;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New MessageModel',
            onPressed: () => GoRouter.of(context).push('/MessageModel/new'),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'MessageModel requests',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: VelvetNoir.surface,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => MessageModelRequestsSheet(
                  requestsAsync: requestsAsync,
                  userId: userId,
                ),
              );
            },
          ),
        ],
      ),
      body: MessageModelPaneView(
        userId: userId,
        username: username,
        showHeader: false,
      ),
    );
  }
}
