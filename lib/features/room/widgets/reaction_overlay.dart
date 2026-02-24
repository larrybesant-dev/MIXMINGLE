// lib/features/room/widgets/reaction_overlay.dart
//
// ReactionOverlay – neon-glowing floating emoji bursts layered above
// the room content. Reactions drift upward from a random X position
// near the bottom, fade out, and clean themselves up automatically.
//
// Usage:
//   Stack(
//     children: [
//       RoomContent(),
//       const ReactionOverlay(),   // place on top
//     ],
//   )
//
// Trigger a reaction anywhere:
//   ReactionBus.emit('🔥');
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/vibe_theme.dart';

// ─────────────────────────────────────────────────────────────────
// Simple in-memory bus so any widget can fire a reaction
// without needing the overlay in the widget tree path.
// ─────────────────────────────────────────────────────────────────
class ReactionBus {
  ReactionBus._();

  static final List<void Function(String)> _listeners = [];

  static void addListener(void Function(String) cb) => _listeners.add(cb);
  static void removeListener(void Function(String) cb) => _listeners.remove(cb);

  static void emit(String emoji) {
    for (final cb in List.of(_listeners)) {
      cb(emoji);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Overlay widget
// ─────────────────────────────────────────────────────────────────
class ReactionOverlay extends StatefulWidget {
  final String? vibeTag;

  const ReactionOverlay({super.key, this.vibeTag});

  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<ReactionOverlay> {
  final List<_NeonFloat> _floats = [];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    ReactionBus.addListener(_onReaction);
  }

  @override
  void dispose() {
    ReactionBus.removeListener(_onReaction);
    super.dispose();
  }

  void _onReaction(String emoji) {
    if (!mounted) return;
    setState(() {
      _floats.add(_NeonFloat(
        emoji: emoji,
        key: UniqueKey(),
        startX: 0.1 + _rng.nextDouble() * 0.8, // 10% – 90% width
        driftX: (_rng.nextDouble() - 0.5) * 60,
      ));
    });
  }

  void _removeFloat(_NeonFloat f) {
    if (!mounted) return;
    setState(() => _floats.remove(f));
  }

  @override
  Widget build(BuildContext context) {
    if (_floats.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        children: _floats
            .map((f) => _NeonFloatWidget(
                  data: f,
                  vibeTag: widget.vibeTag,
                  onDone: () => _removeFloat(f),
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Data class for one floating emoji.
// ─────────────────────────────────────────────────────────────────
class _NeonFloat {
  final String emoji;
  final Key key;
  final double startX; // 0.0–1.0 fraction of parent width
  final double driftX; // horizontal drift in px

  const _NeonFloat({
    required this.emoji,
    required this.key,
    required this.startX,
    required this.driftX,
  });
}

// ─────────────────────────────────────────────────────────────────
// Single floating emoji widget.
// ─────────────────────────────────────────────────────────────────
class _NeonFloatWidget extends StatefulWidget {
  final _NeonFloat data;
  final String? vibeTag;
  final VoidCallback onDone;

  const _NeonFloatWidget({
    required this.data,
    required this.vibeTag,
    required this.onDone,
  });

  @override
  State<_NeonFloatWidget> createState() => __NeonFloatWidgetState();
}

class __NeonFloatWidgetState extends State<_NeonFloatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _y;

  static const _floatDuration = Duration(milliseconds: 1400);
  static const _floatDistance = 180.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _floatDuration);

    // Opacity: quick in, slow fade out
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_ctrl);

    // Scale: pop in from 0.6 to 1.2 then settle to 1.0
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
    ]).animate(_ctrl);

    // Y: float upward
    _y = Tween<double>(begin: 0, end: -_floatDistance)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vt = VibeTheme.of(vibeTag: widget.vibeTag, energy: 70);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalW = constraints.maxW > 0 ? constraints.maxW : 300.0;
        final startPx = totalW * widget.data.startX;

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            return Positioned(
              bottom: 80,
              left: startPx + widget.data.driftX * _ctrl.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: vt.glowColor
                              .withValues(alpha: _opacity.value * 0.8),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Transform.translate(
                      offset: Offset(0, _y.value),
                      child: Text(
                        widget.data.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Convenience extension on BoxConstraints for maxW safety.
// ─────────────────────────────────────────────────────────────────
extension on BoxConstraints {
  double get maxW => maxWidth.isFinite ? maxWidth : 300.0;
}
