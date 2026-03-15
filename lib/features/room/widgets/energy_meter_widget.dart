// lib/features/room/widgets/energy_meter_widget.dart
//
// EnergyMeterWidget – visual room energy bar or ring displayed in
// the room header. Color + glow intensity driven by VibeTheme.
//
// Usage:
//   EnergyMeterWidget(energy: 72, vibeTag: room.vibeTag)
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/vibe_theme.dart';

class EnergyMeterWidget extends StatefulWidget {
  /// Energy level 0–100.
  final int energy;

  /// Room vibe tag (chill, hype, etc.).
  final String? vibeTag;

  /// Whether to show the text label (e.g. "🔥 Heating up").
  final bool showLabel;

  /// Bar height in logical pixels.
  final double height;

  const EnergyMeterWidget({
    super.key,
    required this.energy,
    this.vibeTag,
    this.showLabel = true,
    this.height = 6,
  });

  @override
  State<EnergyMeterWidget> createState() => _EnergyMeterWidgetState();
}

class _EnergyMeterWidgetState extends State<EnergyMeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this)..repeat(reverse: true);
    _updatePulseDuration();
  }

  @override
  void didUpdateWidget(EnergyMeterWidget old) {
    super.didUpdateWidget(old);
    if (old.energy != widget.energy || old.vibeTag != widget.vibeTag) {
      _updatePulseDuration();
    }
  }

  void _updatePulseDuration() {
    final vt = VibeTheme.of(vibeTag: widget.vibeTag, energy: widget.energy);
    _pulseCtrl.duration = vt.pulseDuration;
    if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vt = VibeTheme.of(vibeTag: widget.vibeTag, energy: widget.energy);
    final fillFraction = widget.energy / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Bar ──────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final t = AppMotion.pulse.transform(_pulseCtrl.value);
            final glowAlpha = vt.glowIntensity * (0.55 + t * 0.45);
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: FractionallySizedBox(
                widthFactor: fillFraction,
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: AppMotion.slow,
                  curve: AppMotion.transition,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [vt.secondary, vt.primary],
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: vt.glowColor.withValues(alpha: glowAlpha),
                        blurRadius: vt.glowBlur,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // ── Label ─────────────────────────────────────────────────
        if (widget.showLabel) ...[
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: AppMotion.normal,
            child: Text(
              vt.energyLabel,
              key: ValueKey(vt.energyLabel),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: vt.primary.withValues(alpha: 0.9),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
