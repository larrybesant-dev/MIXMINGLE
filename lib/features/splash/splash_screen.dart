import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
    );

    _scale = Tween<double>(begin: 0.78, end: 1.24).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.92, curve: Curves.easeOutQuart),
      ),
    );

    _controller.forward().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) context.go('/');
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A0C),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A853).withValues(alpha: 0.22),
                      blurRadius: 72,
                      spreadRadius: 24,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/branding/mixvy_logo.png',
                  width: 112,
                  height: 112,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'MixVy',
                style: TextStyle(
                  color: Color(0xFFF2EBE0),
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
