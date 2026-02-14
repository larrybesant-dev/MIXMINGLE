import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

class NightclubHomePage extends StatefulWidget {
  const NightclubHomePage({super.key});

  @override
  State<NightclubHomePage> createState() => _NightclubHomePageState();
}

class _NightclubHomePageState extends State<NightclubHomePage>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _beamController;
  late AnimationController _bokehController;
  late Animation<double> _glowAnimation;
  late Animation<double> _beamAnimation;
  late Animation<double> _bokehAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _beamController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _bokehController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _beamAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _beamController, curve: Curves.linear),
    );

    _bokehAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _bokehController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _beamController.dispose();
    _bokehController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Dark background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF1A0A1E),
                  Color(0xFF0F0A1A),
                ],
              ),
            ),
          ),

          // Animated light beams
          AnimatedBuilder(
            animation: _beamAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: LightBeamsPainter(_beamAnimation.value),
                size: Size.infinite,
              );
            },
          ),

          // Bokeh effects
          AnimatedBuilder(
            animation: _bokehAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: BokehPainter(_bokehAnimation.value),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // App name in turquoise neon
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'MIX & MINGLE',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00FFFF)
                              .withValues(alpha: _glowAnimation.value),
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00FFFF).withValues(
                                  alpha: _glowAnimation.value * 0.8),
                              blurRadius: 20 * _glowAnimation.value,
                            ),
                            Shadow(
                              color: const Color(0xFF00FFFF).withValues(
                                  alpha: _glowAnimation.value * 0.4),
                              blurRadius: 40 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Welcome message
                const Text(
                  'Welcome to Mix & Mingle 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtext
                Text(
                  'The social video chat app with a club vibe.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // Bottom navigation links
                Container(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNeonLink('Privacy Policy'),
                      const SizedBox(width: 40),
                      _buildNeonLink('Terms of Service'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Subtle overlay for depth
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: _glowAnimation.value * 0.5,
                  sigmaY: _glowAnimation.value * 0.5,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNeonLink(String text) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Handle navigation
            if (text == 'Privacy Policy') {
              // Open privacy policy in web browser
              // For web, we can use url_launcher or just navigate to the HTML file
              // Since this is a web app, we'll use a simple approach
              _launchURL('privacy.html');
            } else if (text == 'Terms of Service') {
              // Open terms of service in web browser
              _launchURL('terms.html');
            }
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF00FFFF)
                  .withValues(alpha: _glowAnimation.value),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF00FFFF)
                  .withValues(alpha: _glowAnimation.value),
              shadows: [
                Shadow(
                  color: const Color(0xFF00FFFF)
                      .withValues(alpha: _glowAnimation.value * 0.6),
                  blurRadius: 8 * _glowAnimation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchURL(String fileName) async {
    final url = Uri.file(fileName); // For local HTML files
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback: try as web URL
        final webUrl = Uri.parse(fileName);
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl);
        } else {
          debugPrint('Could not launch $fileName');
        }
      }
    } catch (e) {
      debugPrint('Error launching $fileName: $e');
    }
  }
}

class LightBeamsPainter extends CustomPainter {
  final double animationValue;

  LightBeamsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw multiple light beams
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + animationValue;
      final startRadius = 50.0;
      final endRadius = math.min(size.width, size.height) / 2;

      final startX = center.dx + math.cos(angle) * startRadius;
      final startY = center.dy + math.sin(angle) * startRadius;
      final endX = center.dx + math.cos(angle) * endRadius;
      final endY = center.dy + math.sin(angle) * endRadius;

      // Color cycling through purple, blue, pink
      final colors = [
        const Color(0xFF9C27B0), // Purple
        const Color(0xFF2196F3), // Blue
        const Color(0xFFE91E63), // Pink
      ];
      paint.color = colors[i % colors.length].withValues(alpha: 0.3);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LightBeamsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class BokehPainter extends CustomPainter {
  final double animationValue;

  BokehPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    // Draw bokeh circles
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = (random.nextDouble() * 30 + 10) * animationValue;

      // Color cycling
      final colors = [
        const Color(0xFF9C27B0), // Purple
        const Color(0xFF2196F3), // Blue
        const Color(0xFFE91E63), // Pink
        const Color(0xFF00FFFF), // Turquoise
      ];
      paint.color = colors[i % colors.length].withValues(alpha: 0.1);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(BokehPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
