// lib/widgets/room_overlay_diagnostics.dart
// Diagnostics overlay for room (compile-safe placeholder).

import 'package:flutter/material.dart';

/// Minimal diagnostics overlay that shows basic runtime info.
class RoomOverlayDiagnostics extends StatelessWidget {
  const RoomOverlayDiagnostics({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagnostics',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Room active',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
