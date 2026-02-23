import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class ClubBackground extends StatelessWidget {
  final Widget child;
  final bool showGradient;
  final bool showParticles;

  const ClubBackground({
    super.key,
    required this.child,
    this.showGradient = true,
    this.showParticles = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: showGradient
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ClubColors.deepNavy,
                  ClubColors.deepNavy.withValues(alpha: 0.95),
                  ClubColors.deepNavy.withValues(alpha: 0.9),
                  ClubColors.deepNavy.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              )
            : null,
        color: showGradient ? null : ClubColors.deepNavy,
      ),
      child: Stack(
        children: [
          // Animated background elements
          if (showParticles) ...[
            Positioned.fill(
              child: _AnimatedParticles(),
            ),
          ],

          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      ClubColors.glowingRed.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          child,
        ],
      ),
    );
  }
}

class _AnimatedParticles extends StatefulWidget {
  @override
  State<_AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<_AnimatedParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(seconds: 3 + index),
        vsync: this,
      )..repeat(reverse: true);
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final opacity = 0.1 + (_animations[index].value * 0.1);
            final size = 50.0 + (_animations[index].value * 50.0);

            return Positioned(
              left: (MediaQuery.of(context).size.width * (0.1 + index * 0.15)) %
                  MediaQuery.of(context).size.width,
              top: (MediaQuery.of(context).size.height * (0.2 + index * 0.15)) %
                  MediaQuery.of(context).size.height,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClubColors.goldenYellow.withValues(alpha: opacity),
                  boxShadow: [
                    BoxShadow(
                      color: ClubColors.goldenYellow
                          .withValues(alpha: opacity * 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
