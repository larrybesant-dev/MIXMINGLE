/// Energy Pulse Widget
///
/// Reusable widget to visualize room energy level with animated pulse.
///
/// Features:
/// - Animated pulse rings based on energy intensity
/// - Color transitions: Calm (blue) → Active (amber) → Buzzing (red)
/// - Energy value display (0.0-10.0)
/// - Scales pulse intensity with energy level
///
/// Usage:
/// ```dart
/// EnergyPulseWidget(
///   energy: 6.5,
///   size: 64,
/// )
/// ```
///
/// Enforces: DESIGN_BIBLE.md Section D + DesignAnimations
/// Reference: RoomEnergyThresholds in design_constants.dart
library;

import 'package:flutter/material.dart';
import '../../../../core/design_system/design_constants.dart';

class EnergyPulseWidget extends StatefulWidget {
  /// Room energy level (0.0-10.0)
  final double energy;

  /// Size of the pulse circle
  final double size;

  /// Optional: custom color (defaults to energy-based color)
  final Color? color;

  const EnergyPulseWidget({
    required this.energy,
    this.size = 64,
    this.color,
    super.key,
  });

  @override
  State<EnergyPulseWidget> createState() => _EnergyPulseWidgetState();
}

class _EnergyPulseWidgetState extends State<EnergyPulseWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pulse animation (expand and contract)
    _pulseController = AnimationController(
      vsync: this,
      duration: DesignAnimations.speakingPulseDuration, // 200ms
    )..repeat(reverse: true);

    // Scale animation for intensity (slower, continuous)
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EnergyPulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart pulse if energy changes significantly
    if ((oldWidget.energy - widget.energy).abs() > 1.0) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energyColor = RoomEnergyThresholds.getEnergyColor(widget.energy);
    final displayColor = widget.color ?? energyColor;

    // Normalize energy to 0.0-1.0 for animation intensity
    final energyNormalized = (widget.energy / 10.0).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _scaleController]),
      builder: (context, child) {
        // Pulse expands from center outward
        final pulseScale = 1.0 + (0.2 * _pulseController.value);

        // Opacity fades as pulse expands
        final pulseOpacity = 1.0 - _pulseController.value;

        // Inner scale responds to energy intensity
        final innerScale = 1.0 + (0.1 * _scaleController.value);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring (only visible if energy > threshold)
              if (energyNormalized > 0.2)
                Container(
                  width: widget.size * pulseScale,
                  height: widget.size * pulseScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: displayColor.withValues(
                        alpha: pulseOpacity * 0.6 * energyNormalized,
                      ),
                      width: 2,
                    ),
                  ),
                ),

              // Middle pulse ring (only visible if energy > threshold)
              if (energyNormalized > 0.4)
                Container(
                  width: widget.size * (1.1 + 0.15 * _scaleController.value),
                  height: widget.size * (1.1 + 0.15 * _scaleController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: displayColor.withValues(
                        alpha: 0.3 * energyNormalized,
                      ),
                      width: 1,
                    ),
                  ),
                ),

              // Inner circle (always visible)
              Transform.scale(
                scale: innerScale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ✅ Use colors from DesignColors
                    color: displayColor.withValues(alpha: 0.2),
                    border: Border.all(
                      color: displayColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    // Display energy value (✅ DesignTypography.subheading)
                    child: Text(
                      widget.energy.toStringAsFixed(1),
                      style: DesignTypography.subheading.copyWith(
                        color: displayColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Extension to get energy color and label
/// Moved to design_constants.dart (RoomEnergyThresholds)
/// But kept here as reference comment:
///
/// Calm: energy < 2.0 → Blue
/// Active: 2.0 ≤ energy < 5.0 → Amber
/// Buzzing: energy ≥ 5.0 → Red
///
/// See: RoomEnergyThresholds.getEnergyColor(energy)
/// See: RoomEnergyThresholds.getEnergyLabel(energy)



