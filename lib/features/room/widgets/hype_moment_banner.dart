// lib/features/room/widgets/hype_moment_banner.dart
//
// HypeMomentBanner – auto-generated transient banner surfaced when
// room energy spikes. Shown as an overlay, auto-dismisses after 3 s.
//
// Static API:
//   HypeMomentBanner.show(context, message: '🔥 This room is heating up!');
//
// Widget API (inline, self-dismissing):
//   HypeMomentBanner(message: '...', onDismissed: () {})
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/vibe_theme.dart';

// ─────────────────────────────────────────────────────────────────
// Controller that watches energy and fires banners at thresholds.
// ─────────────────────────────────────────────────────────────────
class HypeEventDetector {
  static const _thresholds = [30, 60, 90];

  int _lastEnergy = 0;
  final Set<int> _firedThresholds = {};

  /// Returns a banner message if a threshold was crossed, else null.
  String? update({
    required int energy,
    int recentJoins = 0,
    int activeSpeakers = 0,
  }) {
    final old = _lastEnergy;
    _lastEnergy = energy;

    // Threshold crossing check
    for (final t in _thresholds) {
      if (old < t && energy >= t && !_firedThresholds.contains(t)) {
        _firedThresholds.add(t);
        return _messageForThreshold(t, energy);
      }
    }

    // Rapid join surge
    if (recentJoins >= 5) {
      return '👥 $recentJoins people just joined!';
    }

    // New conversation sparked
    if (old < 10 && activeSpeakers >= 2) {
      return '💬 New conversation starting!';
    }

    return null;
  }

  /// Reset when leaving a room.
  void reset() {
    _lastEnergy = 0;
    _firedThresholds.clear();
  }

  String _messageForThreshold(int threshold, int energy) {
    if (threshold >= 90) return '🚀 This room is ON FIRE!';
    if (threshold >= 60) return '⚡ The vibe is peaking!';
    return '🔥 This room is heating up!';
  }
}

// ─────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────
class HypeMomentBanner extends StatefulWidget {
  final String message;
  final String? vibeTag;
  final VoidCallback? onDismissed;
  final Duration displayDuration;

  const HypeMomentBanner({
    super.key,
    required this.message,
    this.vibeTag,
    this.onDismissed,
    this.displayDuration = const Duration(seconds: 3),
  });

  /// Show a self-dismissing overlay banner at the top of [context].
  static OverlayEntry show(
    BuildContext context, {
    required String message,
    String? vibeTag,
    Duration displayDuration = const Duration(seconds: 3),
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: HypeMomentBanner(
          message: message,
          vibeTag: vibeTag,
          displayDuration: displayDuration,
          onDismissed: () => entry.remove(),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<HypeMomentBanner> createState() => _HypeMomentBannerState();
}

class _HypeMomentBannerState extends State<HypeMomentBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.normal);
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.entrance));
    _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.entrance));

    _ctrl.forward();

    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vt = VibeTheme.of(vibeTag: widget.vibeTag, energy: 75);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: vt.background.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: vt.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: vt.glowColor.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  style: TextStyle(
                    color: vt.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(Icons.close,
                      size: 14, color: vt.primary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
