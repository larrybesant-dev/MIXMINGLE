/// Room Card Widget
///
/// Displays a room in room discovery with:
/// - Room name
/// - Participant count
/// - Energy level indicator (calm/active/buzzing)
/// - Hover animation
///
/// Usage:
/// ```dart
/// RoomCardWidget(
///   roomName: 'Gaming Room',
///   participantCount: 5,
///   energy: 7.5,
///   onTap: () => joinRoom(),
/// )
/// ```
///
/// Enforces: DESIGN_BIBLE.md Section D (Room Energy) + DESIGN_CONSTANTS
/// Reference: RoomEnergyThresholds in design_constants.dart
library;

import 'package:flutter/material.dart';
import '../../../../core/design_system/design_constants.dart';

class RoomCardWidget extends StatefulWidget {
  /// Room display name
  final String roomName;

  /// Participant count
  final int participantCount;

  /// Room energy level (0.0-10.0)
  final double energy;


  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Whether the room is currently live (shows pulsing LIVE badge)
  final bool isLive;

  const RoomCardWidget({
    required this.roomName,
    required this.participantCount,
    required this.energy,
    required this.onTap,
    this.isLive = true,
    super.key,
  });

  @override
  State<RoomCardWidget> createState() => _RoomCardWidgetState();
}

class _RoomCardWidgetState extends State<RoomCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _energyPulseController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Hover scale animation
    _hoverController = AnimationController(
      vsync: this,
      duration: DesignAnimations.cardHoverDuration, // 150ms
    );

    // Energy pulse animation
    _energyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _energyPulseController.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _hovering = true);
    _hoverController.forward();
  }

  void _onExit() {
    setState(() => _hovering = false);
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final energyColor = RoomEnergyThresholds.getEnergyColor(widget.energy);
    final energyLabel = RoomEnergyThresholds.getEnergyLabel(widget.energy);

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
          ),
          child: Container(
            // âœ… Use DesignSpacing
            padding: const EdgeInsets.all(DesignSpacing.lg),

            // âœ… Use DesignBorders, DesignShadows, DesignColors
            decoration: BoxDecoration(
              border: _hovering
                  ? DesignBorders.cardHovered
                  : DesignBorders.cardDefault,
              borderRadius:
                  BorderRadius.circular(DesignSpacing.cardBorderRadius),
              color: DesignColors.surfaceAlt,
              boxShadow: [
                _hovering ? DesignShadows.medium : DesignShadows.subtle,
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // LIVE badge (pulsing, shown when isLive == true)
                if (widget.isLive)
                  AnimatedBuilder(
                    animation: _energyPulseController,
                    builder: (context, child) {
                      final glowAlpha = 0.3 +
                          (_energyPulseController.value * 0.5);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC2200)
                              .withValues(alpha: 0.18),
                          border: Border.all(
                            color: const Color(0xFFFF3B1A)
                                .withValues(alpha: glowAlpha),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B1A)
                                  .withValues(alpha: glowAlpha * 0.5),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5533),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFFFF5533),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Room name (âœ… DesignTypography.heading)
                Text(
                  widget.roomName,
                  style: DesignTypography.heading,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: DesignSpacing.lg),

                // Footer: participant count + energy indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Participant count (âœ… DesignTypography.caption)
                    Text(
                      '${widget.participantCount} people',
                      style: DesignTypography.caption,
                    ),

                    // Energy indicator with pulse
                    AnimatedBuilder(
                      animation: _energyPulseController,
                      builder: (context, child) {
                        final scale = 1.0 +
                            (0.1 *
                                _energyPulseController.value); // 1.0 to 1.1

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignSpacing.md,
                              vertical: DesignSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              // âœ… Use energy color from RoomEnergyThresholds
                              color: energyColor.withValues(alpha: 0.1),
                              border: Border.all(
                                color: energyColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              energyLabel,
                              style: DesignTypography.label.copyWith(
                                color: energyColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
