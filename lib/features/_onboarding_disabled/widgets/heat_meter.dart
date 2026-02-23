library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Heat Meter Widget
///
/// An animated bar showing room "heat" level.
/// Used in the First Room Recommendation screen.

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';

class HeatMeter extends StatefulWidget {
  final double heatLevel; // 0.0 to 1.0
  final String? label;
  final double height;
  final bool animate;

  const HeatMeter({
    super.key,
    required this.heatLevel,
    this.label,
    this.height = 8,
    this.animate = true,
  });

  @override
  State<HeatMeter> createState() => _HeatMeterState();
}

class _HeatMeterState extends State<HeatMeter> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.heatLevel,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HeatMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heatLevel != widget.heatLevel) {
      _fillAnimation = Tween<double>(
        begin: oldWidget.heatLevel,
        end: widget.heatLevel,
      ).animate(CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutCubic,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getHeatColor(double level) {
    if (level < 0.3) return NeonColors.neonBlue;
    if (level < 0.6) return NeonColors.neonOrange;
    return NeonColors.errorRed;
  }

  String _getHeatLabel(double level) {
    if (level < 0.3) return 'Chill';
    if (level < 0.6) return 'Active';
    if (level < 0.8) return 'Hot';
    return 'Buzzing';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final currentLevel = widget.animate
            ? _fillAnimation.value
            : widget.heatLevel;
        final heatColor = _getHeatColor(currentLevel);
        final glowIntensity = _pulseAnimation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: DesignColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: heatColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getHeatLabel(currentLevel),
                        style: TextStyle(
                          color: heatColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                color: DesignColors.surfaceAlt,
                border: Border.all(
                  color: heatColor.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  // Fill bar
                  FractionallySizedBox(
                    widthFactor: currentLevel.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            NeonColors.neonBlue,
                            NeonColors.neonOrange,
                            if (currentLevel > 0.6) NeonColors.errorRed,
                          ],
                          stops: currentLevel > 0.6
                              ? const [0.0, 0.5, 1.0]
                              : const [0.0, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: heatColor.withValues(alpha: glowIntensity * 0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Animated pulse dots
                  if (widget.animate && currentLevel > 0.1)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HeatDotsPainter(
                          progress: _pulseAnimation.value,
                          fillWidth: currentLevel,
                          color: heatColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter for animated pulse dots
class _HeatDotsPainter extends CustomPainter {
  final double progress;
  final double fillWidth;
  final Color color;

  _HeatDotsPainter({
    required this.progress,
    required this.fillWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: progress * 0.5)
      ..style = PaintingStyle.fill;

    final maxX = size.width * fillWidth - 4;
    if (maxX < 4) return;

    // Draw small dots along the fill
    for (int i = 0; i < 3; i++) {
      final x = maxX - (i * 8) - progress * 4;
      if (x > 4) {
        canvas.drawCircle(
          Offset(x, size.height / 2),
          1.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatDotsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.fillWidth != fillWidth;
  }
}

/// Compact heat indicator for room cards
class HeatIndicator extends StatelessWidget {
  final double heatLevel;
  final bool showLabel;
  final double size;

  const HeatIndicator({
    super.key,
    required this.heatLevel,
    this.showLabel = true,
    this.size = 16,
  });

  Color get _color {
    if (heatLevel < 0.3) return NeonColors.neonBlue;
    if (heatLevel < 0.6) return NeonColors.neonOrange;
    return NeonColors.errorRed;
  }

  String get _label {
    if (heatLevel < 0.3) return 'Chill';
    if (heatLevel < 0.6) return 'Active';
    return 'Hot';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: 0.2),
            border: Border.all(color: _color, width: 2),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.local_fire_department,
            color: _color,
            size: size * 0.7,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
