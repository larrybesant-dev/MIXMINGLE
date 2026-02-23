library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Welcome Screen
///
/// The first screen of the onboarding flow.
/// Features the Mix & Mingle neon logo and animated background.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
import '../widgets/neon_button.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const WelcomeScreen({
    super.key,
    this.onContinue,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late Animation<double> _sweepAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoGlowAnimation;

  @override
  void initState() {
    super.initState();

    // Sweep animation for neon background
    _sweepController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _sweepAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_sweepController);

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _logoScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoGlowAnimation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _fadeController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: DesignColors.background,
      body: Stack(
        children: [
          // Animated neon sweep background
          AnimatedBuilder(
            animation: _sweepAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _NeonSweepPainter(
                  angle: _sweepAnimation.value,
                ),
              );
            },
          ),

          // Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: NeonColors.neonOrange.withValues(
                                    alpha: _logoGlowAnimation.value,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: NeonColors.neonBlue.withValues(
                                    alpha: _logoGlowAnimation.value * 0.5,
                                  ),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // Logo icon
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NeonColors.neonOrange,
                                NeonColors.neonBlue,
                              ],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.nightlife,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Logo text
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NeonColors.neonOrange,
                                DesignColors.gold,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Mix & Mingle',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subtitle with glow
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: DesignColors.surfaceAlt.withValues(alpha: 0.5),
                        border: Border.all(
                          color: NeonColors.neonBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Your night starts here.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: DesignColors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Features preview
                    _buildFeaturesList(),

                    const Spacer(flex: 1),

                    // CTA Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OnboardingNeonButton(
                        text: 'Enter the Lounge',
                        onPressed: widget.onContinue,
                        useGoldTrim: true,
                        width: double.infinity,
                        height: 60,
                        icon: Icons.arrow_forward,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      ('ðŸŽ¥', 'Live Video Rooms'),
      ('ðŸ’¬', 'Real Connections'),
      ('âœ¨', 'VIP Experience'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.map((feature) {
        return Column(
          children: [
            Text(
              feature.$1,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              feature.$2,
              style: TextStyle(
                color: DesignColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Custom painter for animated neon sweep background
class _NeonSweepPainter extends CustomPainter {
  final double angle;

  _NeonSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 1.2;

    // First sweep - orange
    final orangeX = center.dx + radius * 0.5 * math.cos(angle);
    final orangeY = center.dy + radius * 0.5 * math.sin(angle);

    final orangePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (orangeX / size.width - 0.5) * 2,
          (orangeY / size.height - 0.5) * 2,
        ),
        radius: 0.6,
        colors: [
          NeonColors.neonOrange.withValues(alpha: 0.15),
          NeonColors.neonOrange.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      orangePaint,
    );

    // Second sweep - blue (offset by pi)
    final blueX = center.dx + radius * 0.5 * math.cos(angle + math.pi);
    final blueY = center.dy + radius * 0.5 * math.sin(angle + math.pi);

    final bluePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (blueX / size.width - 0.5) * 2,
          (blueY / size.height - 0.5) * 2,
        ),
        radius: 0.6,
        colors: [
          NeonColors.neonBlue.withValues(alpha: 0.12),
          NeonColors.neonBlue.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bluePaint,
    );

    // Gold accent sweep
    final goldX = center.dx + radius * 0.3 * math.cos(angle * 0.7 + math.pi / 2);
    final goldY = center.dy + radius * 0.3 * math.sin(angle * 0.7 + math.pi / 2);

    final goldPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (goldX / size.width - 0.5) * 2,
          (goldY / size.height - 0.5) * 2,
        ),
        radius: 0.4,
        colors: [
          DesignColors.gold.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(_NeonSweepPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
