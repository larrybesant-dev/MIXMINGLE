import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/app_page_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _loaderController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _loaderOpacity = CurvedAnimation(
      parent: _loaderController,
      curve: Curves.easeInOut,
    );

    _glowPulse = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    _logoController.forward().whenComplete(() {
      _textController.forward().whenComplete(() {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) context.go('/');
        });
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      safeArea: false,
      body: Stack(
        children: [
          // Wine-red atmospheric glow background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (context, _) => CustomPaint(
                painter: _GlowBackgroundPainter(opacity: _glowPulse.value),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // M monogram with gold glow ring
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _glowPulse,
                    builder: (context, _) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37)
                                .withValues(alpha: _glowPulse.value),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: const Color(0xFF781E2B)
                                .withValues(alpha: _glowPulse.value * 0.6),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                        gradient: const RadialGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF0B0B0B)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 64,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD4AF37),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // MIXVY wordmark
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) => Opacity(
                    opacity: _textOpacity.value,
                    child: child,
                  ),
                  child: Text(
                    'MIXVY',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 8,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: child,
                  ),
                  child: Text(
                    'Where chemistry meets connection.',
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFF7EDE2).withValues(alpha: 0.55),
                      letterSpacing: 0.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loader text
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _loaderController,
              builder: (context, _) => Opacity(
                opacity: _loaderOpacity.value,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return AnimatedBuilder(
                          animation: _loaderController,
                          builder: (context, _) {
                            final delay = i * 0.2;
                            final progress = ((_loaderController.value - delay)
                                    .clamp(0.0, 0.6)) /
                                0.6;
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                  const Color(0xFFD4AF37),
                                  progress,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting energy...',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: const Color(0xFFF7EDE2).withValues(alpha: 0.35),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBackgroundPainter extends CustomPainter {
  final double opacity;
  const _GlowBackgroundPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Wine-red glow in lower-left
    final wineGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, 0.7),
        radius: 0.7,
        colors: [
          const Color(0xFF781E2B).withValues(alpha: opacity * 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wineGlow);

    // Gold glow top-right
    final goldGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.5),
        radius: 0.5,
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: opacity * 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), goldGlow);
  }

  @override
  bool shouldRepaint(_GlowBackgroundPainter old) => old.opacity != opacity;
}
