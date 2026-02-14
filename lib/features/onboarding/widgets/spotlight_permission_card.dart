/// Spotlight Permission Card
///
/// A card with spotlight animation showing permission status.
/// Used in the Permissions screen for Camera, Mic, Notifications.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';

class SpotlightPermissionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final bool isDenied;
  final VoidCallback? onRequest;
  final bool isLoading;

  const SpotlightPermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isGranted = false,
    this.isDenied = false,
    this.onRequest,
    this.isLoading = false,
  });

  @override
  State<SpotlightPermissionCard> createState() => _SpotlightPermissionCardState();
}

class _SpotlightPermissionCardState extends State<SpotlightPermissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _spotlightController;
  late Animation<double> _spotlightAnimation;

  @override
  void initState() {
    super.initState();
    _spotlightController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _spotlightAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.linear,
    ));

    if (!widget.isGranted && !widget.isDenied) {
      _spotlightController.repeat();
    }
  }

  @override
  void didUpdateWidget(SpotlightPermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGranted || widget.isDenied) {
      _spotlightController.stop();
    } else if (!_spotlightController.isAnimating) {
      _spotlightController.repeat();
    }
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    if (widget.isGranted) return NeonColors.successGreen;
    if (widget.isDenied) return NeonColors.errorRed;
    return NeonColors.neonOrange;
  }

  String get _statusText {
    if (widget.isGranted) return 'Granted';
    if (widget.isDenied) return 'Denied';
    return 'Not Set';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spotlightAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: DesignColors.surfaceAlt,
            border: Border.all(
              color: _statusColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              // Base shadow
              BoxShadow(
                color: DesignColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              // Spotlight glow (only when not granted/denied)
              if (!widget.isGranted && !widget.isDenied)
                BoxShadow(
                  color: NeonColors.neonOrange.withValues(
                    alpha: 0.3 +
                        0.2 * math.sin(_spotlightAnimation.value).abs(),
                  ),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Spotlight sweep effect
              if (!widget.isGranted && !widget.isDenied)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _SpotlightPainter(
                        angle: _spotlightAnimation.value,
                        color: NeonColors.neonOrange,
                      ),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon with glow
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: _statusColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isGranted ? Icons.check : widget.icon,
                        color: _statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: DesignColors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Gold accent line
                              Expanded(
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        DesignColors.gold.withValues(alpha: 0.6),
                                        DesignColors.gold.withValues(alpha: 0.0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: DesignColors.textGray,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Status indicator
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _statusColor.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: _statusColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  _statusText,
                                  style: TextStyle(
                                    color: _statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Request button
                              if (!widget.isGranted && !widget.isLoading)
                                GestureDetector(
                                  onTap: widget.onRequest,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          NeonColors.neonOrange,
                                          NeonColors.neonOrange.withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      widget.isDenied ? 'Settings' : 'Enable',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.isLoading)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      NeonColors.neonOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for spotlight sweep effect
class _SpotlightPainter extends CustomPainter {
  final double angle;
  final Color color;

  _SpotlightPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.8;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          0.5 * math.cos(angle),
          0.5 * math.sin(angle),
        ),
        radius: 0.8,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
