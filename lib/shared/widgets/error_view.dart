import 'package:flutter/material.dart';

import 'glow_text.dart';
import 'neon_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? details;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF4C4C),
              size: 48,
            ),
            const SizedBox(height: 12),
            GlowText(
              text: message,
              fontSize: 18,
              color: Colors.white,
              glowColor: const Color(0xFFFF4C4C),
              textAlign: TextAlign.center,
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              NeonButton(label: 'Retry', onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}
