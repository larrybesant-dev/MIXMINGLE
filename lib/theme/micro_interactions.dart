import 'package:flutter/material.dart';

class MicroInteractions {
  static Widget fadeScaleTransition({required Widget child, required Animation<double> animation}) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }

  static Widget animatedReaction({required IconData icon, required Color color}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Icon(icon, color: color, size: 32),
    );
  }
}
