// lib/widgets/reaction_burst.dart

import 'package:flutter/material.dart';

class ReactionBurst extends StatelessWidget {
  final String type;
  const ReactionBurst({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.deepPurple,
        boxShadow: [],
      ),
      child: Icon(
        type == 'like' ? Icons.thumb_up : Icons.emoji_emotions,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}
