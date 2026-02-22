import 'package:flutter/material.dart';

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const NeonButton({required this.label, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFFFF4C4C),
            Color(0xFFFFD700)
          ]), // glowingRed to goldenYellow
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF4C4C)
                    .withValues(alpha: 0.35), // glowingRed glow
                blurRadius: 14,
                spreadRadius: 0)
          ]),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
