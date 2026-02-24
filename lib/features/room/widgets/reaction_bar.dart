// lib/features/room/widgets/reaction_bar.dart
//
// Reaction bar with floating emoji burst animations for live rooms.
//
// Usage:
//   ReactionBarWidget(onReact: (emoji) => controller.sendReaction(emoji))
//
// Tap any emoji → it floats upward with a random horizontal drift and fades out.
// `onReact` fires each time so the controller can broadcast to Firestore.
// ───────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design_system/design_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class ReactionBarWidget extends StatefulWidget {
  /// Called each time the user taps a reaction emoji.
  final void Function(String emoji) onReact;

  const ReactionBarWidget({super.key, required this.onReact});

  @override
  State<ReactionBarWidget> createState() => _ReactionBarWidgetState();
}

class _ReactionBarWidgetState extends State<ReactionBarWidget> {
  static const _emojis = ['🔥', '❤️', '😂', '👏', '💯', '🎵'];

  // Each active float is tracked here; they remove themselves on completion.
  final List<_FloatData> _floats = [];

  void _handleTap(String emoji) {
    widget.onReact(emoji);

    // Random horizontal offset: –24 to +24 logical pixels
    final dx = (math.Random().nextDouble() - 0.5) * 48;

    final data = _FloatData(
      emoji: emoji,
      dx: dx,
      key: UniqueKey(),
    );

    setState(() => _floats.add(data));
  }

  void _removeFloat(_FloatData data) {
    if (!mounted) return;
    setState(() => _floats.remove(data));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Semi-transparent pill that sits at the bottom of the room
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: DesignColors.background.withValues(alpha: 0.75),
        border: Border.all(
          color: DesignColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: DesignColors.accent.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Emoji button row ────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _emojis
                .map((e) => _EmojiButton(
                      emoji: e,
                      onTap: () => _handleTap(e),
                    ))
                .toList(),
          ),

          // ── Active floats ────────────────────────────────────────────
          for (final floatData in _floats)
            _EmojiFloatWidget(
              key: floatData.key,
              emoji: floatData.emoji,
              dx: floatData.dx,
              onDone: () => _removeFloat(floatData),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual emoji button
// ─────────────────────────────────────────────────────────────────────────────

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _pulse.forward();
    _pulse.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DesignColors.surfaceLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating emoji that rises and fades out
// ─────────────────────────────────────────────────────────────────────────────

class _FloatData {
  final String emoji;
  final double dx;
  final Key key;

  const _FloatData({required this.emoji, required this.dx, required this.key});
}

class _EmojiFloatWidget extends StatefulWidget {
  final String emoji;
  final double dx;
  final VoidCallback onDone;

  const _EmojiFloatWidget({
    super.key,
    required this.emoji,
    required this.dx,
    required this.onDone,
  });

  @override
  State<_EmojiFloatWidget> createState() => _EmojiFloatWidgetState();
}

class _EmojiFloatWidgetState extends State<_EmojiFloatWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rise; // 0-120 px upward
  late final Animation<double> _fade; // 1 → 0

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rise = Tween<double>(begin: 0, end: -120).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)),
    );

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        bottom: -_rise.value, // starts at 0, goes negative (upward)
        child: Transform.translate(
          offset: Offset(widget.dx, 0),
          child: Opacity(
            opacity: _fade.value,
            child: IgnorePointer(
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
