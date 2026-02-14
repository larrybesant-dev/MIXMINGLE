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

  /// Number of participants currently in room
  final int participantCount;

  /// Room energy level (0.0-10.0)
  final double energy;

  /// Callback when card is tapped
  final VoidCallback onTap;

  const RoomCardWidget({
    required this.roomName,
    required this.participantCount,
    required this.energy,
    required this.onTap,
    super.key,
  });

  @override
  State<RoomCardWidget> createState() => _RoomCardWidgetState();
}

class _RoomCardWidgetState extends State<RoomCardWidget>
    with SingleTickerProviderStateMixin {
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
      duration: Duration(milliseconds: 800),
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
            // ✅ Use DesignSpacing
            padding: EdgeInsets.all(DesignSpacing.lg),

            // ✅ Use DesignBorders, DesignShadows, DesignColors
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
                // Room name (✅ DesignTypography.heading)
                Text(
                  widget.roomName,
                  style: DesignTypography.heading,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: DesignSpacing.lg),

                // Footer: participant count + energy indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Participant count (✅ DesignTypography.caption)
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
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignSpacing.md,
                              vertical: DesignSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              // ✅ Use energy color from RoomEnergyThresholds
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



