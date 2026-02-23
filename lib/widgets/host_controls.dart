// lib/widgets/host_controls.dart
// Host controls UI for room (minimal compile-safe version).

import 'package:flutter/material.dart';
import 'package:mixmingle/core/stubs/app_stubs.dart';

/// Minimal host controls widget to satisfy compilation and tests.
class HostControls extends StatelessWidget {
  const HostControls({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MixMingleTheme stub for safe default styling.
    final theme = MixMingleTheme.light;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () async {
              // Minimal safe call to roomService stub.
              await roomService.joinRoom('test-room');
            },
            child: const Text('Join'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await roomService.leaveRoom();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
