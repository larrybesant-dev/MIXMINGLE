// lib/features/room/widgets/speaking_glow.dart
//
// SpeakingGlow – wraps any widget (typically a camera tile or avatar)
// with an animated neon border glow that pulses in sync with speech.
//
// Usage:
//   SpeakingGlow(
//     isSpeaking: participant.isSpeaking,
//     vibeTag: room.vibeTag,
//     child: CameraTile(...),
//   )
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/vibe_theme.dart';

class SpeakingGlow extends StatefulWidget {
  /// Whether this participant is currently speaking.
  final bool isSpeaking;

  /// Room vibe tag used to tint the glow color.
  final String? vibeTag;

  /// Custom override color (takes precedence over VibeTheme).
  final Color? glowColor;

  /// Border radius applied to both glow and child.
  final BorderRadius borderRadius;

  /// Border width of the speaking ring.
  final double borderWidth;

  final Widget child;

  const SpeakingGlow({
    super.key,
    required this.isSpeaking,
    required this.child,
    this.vibeTag,
    this.glowColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.borderWidth = 2.0,
  });

  @override
  State<SpeakingGlow> createState() => _SpeakingGlowState();
}

class _SpeakingGlowState extends State<SpeakingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)..duration = _pulseDuration();
    _updateAnim();
  }

  @override
  void didUpdateWidget(SpeakingGlow old) {
    super.didUpdateWidget(old);
    final durChanged = old.vibeTag != widget.vibeTag;
    if (old.isSpeaking != widget.isSpeaking || durChanged) {
      if (durChanged) _ctrl.duration = _pulseDuration();
      _updateAnim();
    }
  }

  Duration _pulseDuration() {
    final vt = VibeTheme.of(vibeTag: widget.vibeTag, energy: 60);
    return Duration(
      milliseconds:
          (vt.pulseDuration.inMilliseconds * 0.5).round().clamp(200, 800),
    );
  }

  void _updateAnim() {
    if (widget.isSpeaking) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vt = VibeTheme.of(vibeTag: widget.vibeTag, energy: 65);
    final color = widget.glowColor ?? vt.glowColor;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = AppMotion.pulse.transform(_ctrl.value);
        // Pulse border opacity 0.5 → 1.0
        final borderAlpha = widget.isSpeaking ? 0.5 + t * 0.5 : 0.0;
        // Pulse shadow blur 8 → 24
        final blurRadius = widget.isSpeaking ? 8.0 + t * 16.0 : 0.0;
        final spreadRadius = widget.isSpeaking ? 0.3 + t * 1.7 : 0.0;

        return AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: color.withValues(alpha: borderAlpha.clamp(0, 1)),
              width: widget.borderWidth,
            ),
            boxShadow: widget.isSpeaking
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: (t * 0.7).clamp(0, 1)),
                      blurRadius: blurRadius,
                      spreadRadius: spreadRadius,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: (t * 0.3).clamp(0, 1)),
                      blurRadius: blurRadius * 2.5,
                      spreadRadius: 0,
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
