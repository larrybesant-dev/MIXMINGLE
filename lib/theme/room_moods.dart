import 'package:flutter/material.dart';

class RoomMoods {
  static const Map<String, RoomMood> moods = {
    'Chill': RoomMood(
      background: LinearGradient(
        colors: [Color(0xFF16213e), Color(0xFF6C63FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accent: Color(0xFF6C63FF),
      animationAsset: 'assets/lottie/chill.json',
    ),
    'After Hours': RoomMood(
      background: LinearGradient(
        colors: [Color(0xFF1a1a2e), Color(0xFFFFD700)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      accent: Color(0xFFFFD700),
      animationAsset: 'assets/lottie/after_hours.json',
    ),
    'Game Night': RoomMood(
      background: LinearGradient(
        colors: [Color(0xFF22223b), Color(0xFF6C63FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      accent: Color(0xFF6C63FF),
      animationAsset: 'assets/lottie/game_night.json',
    ),
  };
}

class RoomMood {
  final LinearGradient background;
  final Color accent;
  final String animationAsset;

  const RoomMood({required this.background, required this.accent, required this.animationAsset});
}
