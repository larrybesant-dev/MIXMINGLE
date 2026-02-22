// lib/widgets/reaction_stream_overlay.dart

import 'package:flutter/material.dart';
import '../models/reaction_model.dart';
import 'reaction_burst.dart';

class ReactionStreamOverlay extends StatelessWidget {
  final List<ReactionModel> reactions;
  const ReactionStreamOverlay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: reactions.map((r) => AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          left: 16.0 * reactions.indexOf(r),
          top: 8.0 * reactions.indexOf(r),
          child: ReactionBurst(type: r.type),
        )).toList(),
      ),
    );
  }
}
