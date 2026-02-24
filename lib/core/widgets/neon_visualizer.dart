// lib/core/widgets/neon_visualizer.dart
//
// NeonVisualizer — animated neon bar equalizer.
//
// Modes:
//   NeonVisualizerMode.profile  – slow, aesthetic (for profile page)
//   NeonVisualizerMode.room     – faster, reactive (for room page)
//
// Usage:
//   NeonVisualizer(isPlaying: true, mode: NeonVisualizerMode.profile)
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum NeonVisualizerMode { profile, room }

class NeonVisualizer extends StatefulWidget {
  const NeonVisualizer({
    super.key,
    required this.isPlaying,
    this.mode = NeonVisualizerMode.profile,
    this.barCount = 7,
    this.height = 32.0,
    this.width = 48.0,
    this.primaryColor,
  });

  final bool isPlaying;
  final NeonVisualizerMode mode;
  final int barCount;
  final double height;
  final double width;
  final Color? primaryColor;

  @override
  State<NeonVisualizer> createState() => _NeonVisualizerState();
}

class _NeonVisualizerState extends State<NeonVisualizer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      final speed = widget.mode == NeonVisualizerMode.room
          ? 200 + _rng.nextInt(300)  // 200–500ms reactive
          : 600 + _rng.nextInt(600); // 600–1200ms aesthetic
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: speed),
      );
    });

    _animations = List.generate(widget.barCount, (i) {
      return Tween<double>(
        begin: 0.15 + _rng.nextDouble() * 0.2,
        end:   0.55 + _rng.nextDouble() * 0.45,
      ).animate(CurvedAnimation(
        parent: _controllers[i],
        curve: Curves.easeInOut,
      ));
    });

    if (widget.isPlaying) _startAll();
  }

  void _startAll() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAll() {
    for (final c in _controllers) {
      c.animateTo(0.15, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void didUpdateWidget(NeonVisualizer old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _startAll() : _stopAll();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = (widget.width - (widget.barCount - 1) * 3) / widget.barCount;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) {
              final fraction = _animations[i].value;
              final barHeight = widget.height * fraction;
              final t = i / (widget.barCount - 1); // 0.0 → 1.0

              // Gradient: blue → pink → purple
              final color = Color.lerp(
                const Color(0xFF00B4FF), // neon blue
                Color.lerp(
                  const Color(0xFFFF2D9B), // neon pink
                  const Color(0xFFB44DFF), // neon purple
                  t,
                )!,
                t,
              )!;

              return Container(
                width: barWidth,
                height: barHeight.clamp(3.0, widget.height),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: widget.isPlaying
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Ring variant: wraps behind avatar ─────────────────────────────

class NeonVisualizerRing extends StatefulWidget {
  const NeonVisualizerRing({
    super.key,
    required this.isPlaying,
    required this.radius,
    this.barCount = 24,
    this.mode = NeonVisualizerMode.profile,
  });

  final bool isPlaying;
  final double radius;
  final int barCount;
  final NeonVisualizerMode mode;

  @override
  State<NeonVisualizerRing> createState() => _NeonVisualizerRingState();
}

class _NeonVisualizerRingState extends State<NeonVisualizerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rng = math.Random();
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(widget.barCount, (_) => 0.3 + _rng.nextDouble() * 0.7);
    _controller = AnimationController(
      vsync: this,
      duration: widget.mode == NeonVisualizerMode.room
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.isPlaying) {
          setState(() {
            _heights = List.generate(
                widget.barCount, (_) => 0.2 + _rng.nextDouble() * 0.8);
          });
          _controller.forward(from: 0);
        }
      });

    if (widget.isPlaying) _controller.forward();
  }

  @override
  void didUpdateWidget(NeonVisualizerRing old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) _controller.forward();
    if (!widget.isPlaying && old.isPlaying) _controller.stop();
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
      builder: (_, __) => CustomPaint(
        size: Size(widget.radius * 2 + 24, widget.radius * 2 + 24),
        painter: _RingPainter(
          barCount: widget.barCount,
          heights: _heights,
          progress: _controller.value,
          isPlaying: widget.isPlaying,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.barCount,
    required this.heights,
    required this.progress,
    required this.isPlaying,
  });

  final int barCount;
  final List<double> heights;
  final double progress;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const barMaxLength = 10.0;

    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi - math.pi / 2;
      final t = i / (barCount - 1);
      final h = heights[i] * barMaxLength;

      final color = Color.lerp(
        const Color(0xFF00B4FF),
        Color.lerp(
          const Color(0xFFFF2D9B),
          const Color(0xFFB44DFF),
          t,
        )!,
        t,
      )!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.7 + 0.3 * heights[i])
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final start = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius + h) * math.cos(angle),
        center.dy + (radius + h) * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}
