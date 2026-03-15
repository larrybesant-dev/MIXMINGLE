import 'package:flutter/material.dart';

class BrandTouchpoints {
  static Widget invitation(String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_cafe, size: 48, color: Color(0xFF6C63FF)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.white70)),
      ],
    );
  }
}
