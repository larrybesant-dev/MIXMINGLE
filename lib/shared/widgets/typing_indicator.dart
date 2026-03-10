import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

/// Animated three-dot typing indicator shown when the other user is typing.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final bounce = sin(
                  (_controller.value * 2 * pi) - (i * pi / 3),
                );
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8 + bounce * 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignColors.accent
                        .withValues(alpha: 0.5 + bounce * 0.4),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
