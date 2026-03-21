import 'package:flutter/material.dart';

class FeedEmptyState extends StatelessWidget {
  final String message;

  const FeedEmptyState({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7 * 255).round()),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
