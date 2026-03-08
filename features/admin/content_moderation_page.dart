import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentModerationPage extends ConsumerWidget {
  const ContentModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Moderation')),
      body: const Column(
        children: [
          // TODO: Add approve/reject stories, short videos, posts widgets
          Text('Content moderation coming soon'),
        ],
      ),
    );
  }
}
