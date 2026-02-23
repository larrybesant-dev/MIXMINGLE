import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';

/// First Recommendation/Activation - Final onboarding step
/// Shows 3 options: Join a Room, Try Speed Dating, or Browse Rooms
class FirstRecommendationPage extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const FirstRecommendationPage({super.key, required this.onComplete});

  @override
  ConsumerState<FirstRecommendationPage> createState() =>
      _FirstRecommendationPageState();
}

class _FirstRecommendationPageState
    extends ConsumerState<FirstRecommendationPage> {
  bool _isLoading = false;

  Future<void> _markOnboardingComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'onboardingComplete': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking onboarding complete: $e');
    }
  }

  Future<void> _handleChoice(String choice) async {
    setState(() => _isLoading = true);

    try {
      // Mark onboarding as complete
      await _markOnboardingComplete();

      // Complete onboarding and navigate based on choice
      widget.onComplete();

      // Navigate to appropriate screen
      if (mounted) {
        switch (choice) {
          case 'speed-dating':
            // Navigate to speed dating lobby
            Navigator.of(context).pushReplacementNamed('/speed-dating/lobby');
            break;
          case 'browse':
            // Navigate to rooms list
            Navigator.of(context).pushReplacementNamed('/rooms');
            break;
          case 'join-room':
          default:
            // Navigate to home (will show recommended room)
            Navigator.of(context).pushReplacementNamed('/home');
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Welcome! ðŸŽ‰'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Title
                NeonText(
                  'YOU\'RE ALL SET!',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  textColor: DesignColors.white,
                  glowColor: DesignColors.gold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Choose how you want to start:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignColors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Option 1: Join a Room
                _buildOptionCard(
                  icon: Icons.video_call,
                  title: 'JOIN A ROOM',
                  description: 'Jump into a live video room with people online right now',
                  color: DesignColors.accent,
                  onTap: () => _handleChoice('join-room'),
                ),
                const SizedBox(height: 16),

                // Option 2: Speed Dating
                _buildOptionCard(
                  icon: Icons.speed,
                  title: 'TRY SPEED DATING',
                  description: '5-minute video dates with matched singles. Real connections.',
                  color: DesignColors.gold,
                  onTap: () => _handleChoice('speed-dating'),
                ),
                const SizedBox(height: 16),

                // Option 3: Browse Rooms
                _buildOptionCard(
                  icon: Icons.explore,
                  title: 'BROWSE ROOMS',
                  description: 'Explore all available rooms and join one that interests you',
                  color: Color(0xFF00D9FF),
                  onTap: () => _handleChoice('browse'),
                ),

                const SizedBox(height: 40),

                // Skip button
                TextButton(
                  onPressed: _isLoading ? null : () => _handleChoice('join-room'),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: DesignColors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: NeonGlowCard(
        glowColor: color,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: DesignColors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
