import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/neon_button.dart';

class BetaLandingPage extends ConsumerWidget {
  const BetaLandingPage({super.key});

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFFFFD700),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Beta Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2,
                    ),
                  ),
                  child: const GlowText(
                    text: 'BETA',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    glowColor: Color(0xFFFF4C4C),
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome Text
                const GlowText(
                  text: 'Welcome to Mix & Mingle',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  glowColor: Color(0xFFFF4C4C),
                ),
                const SizedBox(height: 16),

                const Text(
                  'The ultimate social video chat platform for live performances and global connections.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 48),

                // Beta Features
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlowText(
                        text: 'Beta Features',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        glowColor: Color(0xFFFF4C4C),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                          '🎥 Real-time video chat in live rooms'),
                      _buildFeatureItem(
                          '💬 Instant messaging with participants'),
                      _buildFeatureItem('🎭 Create and join themed rooms'),
                      _buildFeatureItem('🎁 Send tips to performers'),
                      _buildFeatureItem('📱 Works on web, mobile, and desktop'),
                      _buildFeatureItem('🌟 Club-style UI with neon effects'),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Call to Action
                NeonButton(
                  onPressed: () {
                    // Navigate to signup
                    Navigator.of(context).pushNamed('/signup');
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  child: const Text(
                    'Join Beta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Beta Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '🚧 Beta Testing Notice',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This is a beta version. Features may change and you might encounter bugs. Your feedback helps us improve!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
