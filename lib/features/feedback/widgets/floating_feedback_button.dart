import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feedback_modal.dart';
import '../../../core/theme/neon_colors.dart';

class FloatingFeedbackButton extends ConsumerWidget {
  const FloatingFeedbackButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: FloatingActionButton(
        backgroundColor: NeonColors.neonBlue,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const FeedbackModal(),
          );
        },
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.feedback, color: Colors.white),
      ),
    );
  }
}
