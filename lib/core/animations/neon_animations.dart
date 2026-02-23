import 'package:flutter/material.dart';

/// ============================================================================
/// NEON ANIMATION UTILITIES - Electric Lounge Effects
/// Reusable animation curves and effects for consistent motion
/// ============================================================================

class NeonAnimations {
  // Custom curves for neon aesthetic
  static const Curve neonPulse = Curves.easeInOut;
  static const Curve neonFlow = Curves.elasticOut;
  static const Curve neonSnap = Curves.decelerate;

  // Standard durations
  static const Duration quickDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration verySlowDuration = Duration(milliseconds: 800);
  static const Duration glowDuration = Duration(milliseconds: 2000);

  /// Breathing glow animation (for ambient effects)
  static Animation<double> createGlowAnimation(
    AnimationController controller, {
    double minOpacity = 0.4,
    double maxOpacity = 1.0,
  }) {
    return Tween<double>(begin: minOpacity, end: maxOpacity).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  /// Pulse animation (for emphasis)
  static Animation<double> createPulseAnimation(
    AnimationController controller, {
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return Tween<double>(begin: minScale, end: maxScale).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticInOut),
    );
  }

  /// Scale animation (for entrance/exit)
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double startScale = 0.8,
    double endScale = 1.0,
  }) {
    return Tween<double>(begin: startScale, end: endScale).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut),
    );
  }

  /// Opacity fade animation
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    bool fadeIn = true,
  }) {
    return Tween<double>(
      begin: fadeIn ? 0.0 : 1.0,
      end: fadeIn ? 1.0 : 0.0,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  /// Slide animation (for navigation)
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutQuart),
    );
  }

  /// Combined scale + fade for elegant entrance
  static Future<void> playScaleAndFadeAnimation(
    AnimationController scaleController,
    AnimationController fadeController, {
    Duration? duration,
  }) async {
    await scaleController.forward();
    fadeController.forward();
  }
}

/// Neon glow shadow generator
class NeonGlowShadow {
  /// Double-glow shadow (orange + blue) for brand effect
  static List<BoxShadow> dualGlow({
    double orangeOpacity = 0.6,
    double blueOpacity = 0.3,
    double blurRadius = 24,
    double spreadRadius = 4,
  }) {
    return [
      BoxShadow(
        color: const Color(0xFFFF7A3C).withValues(alpha: orangeOpacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
      BoxShadow(
        color: const Color(0xFF00D9FF).withValues(alpha: blueOpacity),
        blurRadius: blurRadius * 0.75,
        spreadRadius: spreadRadius * 0.5,
      ),
    ];
  }

  /// Single color glow shadow
  static List<BoxShadow> singleGlow({
    required Color color,
    double opacity = 0.6,
    double blurRadius = 20,
    double spreadRadius = 4,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  /// Subtle glow (for text and small elements)
  static List<BoxShadow> subtleGlow({
    required Color color,
    double opacity = 0.3,
    double blurRadius = 8,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Intense glow (for emphasis)
  static List<BoxShadow> intenseGlow({
    required Color color,
    double opacity = 0.8,
    double blurRadius = 32,
    double spreadRadius = 8,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }
}

/// Neon gradient definitions
class NeonGradients {
  /// Primary brand gradient (orange to purple)
  static const LinearGradient mixToMingle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF7A3C), // Neon Orange
      Color(0xFFBD00FF), // Neon Purple
    ],
  );

  /// Blue accent gradient (blue to cyan)
  static const LinearGradient blueAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00D9FF), // Neon Blue
      Color(0xFF0099FF), // Cyan Blue
    ],
  );

  /// Dark background gradient
  static const LinearGradient darkBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1F3A), // Dark Navy 2
      Color(0xFF0A0E27), // Dark Navy
    ],
  );

  /// Premium gradient (purple to pink)
  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFBD00FF), // Neon Purple
      Color(0xFFFF2BD7), // Neon Pink
    ],
  );
}

/// Interactive animation widget builder
class NeonAnimatedBuilder extends StatefulWidget {
  final Widget Function(BuildContext, Animation<double>) builder;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onComplete;
  final bool autoStart;

  const NeonAnimatedBuilder({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOut,
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<NeonAnimatedBuilder> createState() => _NeonAnimatedBuilderState();
}

class _NeonAnimatedBuilderState extends State<NeonAnimatedBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    if (widget.autoStart) {
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return widget.builder(context, _controller);
      },
    );
  }
}
