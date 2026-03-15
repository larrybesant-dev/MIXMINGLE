/// DESIGN SYSTEM - ANIMATION UTILITIES
///
/// Reusable animation builders that enforce DESIGN_BIBLE.md timings
/// Reference: DESIGN_BIBLE.md Section C
library;

import 'package:flutter/material.dart';
import 'design_constants.dart';

// ==============================================================================
// A. JOIN PHASE ANIMATION BUILDER
// ==============================================================================

/// Manages join flow state transitions with precise timing requirements
class JoinPhaseAnimationController {
  final JoinPhase Function() getCurrentPhase;
  final VoidCallback onComplete;

  late AnimationController _stageController;

  JoinPhaseAnimationController({
    required this.getCurrentPhase,
    required this.onComplete,
    required TickerProvider vsync,
  }) {
    _stageController = AnimationController(
      vsync: vsync,
      duration: Duration.zero,
    );
  }

  /// Transition to next phase with proper timing
  Future<void> animateToPhase(JoinPhase nextPhase) async {
    final duration = nextPhase.expectedDuration;

    _stageController.reset();
    _stageController.duration = duration;

    await _stageController.forward();
  }

  Animation<int> get milliselapsed {
    return StepTween(begin: 0, end: 1000).animate(_stageController);
  }

  void dispose() => _stageController.dispose();
}

// ==============================================================================
// B. PRESENCE CARD ANIMATION BUILDER
// ==============================================================================

/// Slides in participant card from bottom with fade + transform
class PresenceCardAnimation {
  static Animation<Offset> slideUpAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 1), // Start below
      end: Offset.zero, // End at final position
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: DesignAnimations.easeOutCubic,
      ),
    );
  }

  static Animation<double> fadeInAnimation(AnimationController controller) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: DesignAnimations.easeOutCubic,
      ),
    );
  }

  /// Combined animation for new participant arrival
  static Future<void> animateArrival(TickerProvider vsync) async {
    final controller = AnimationController(
      vsync: vsync,
      duration: DesignAnimations.presenceSlideInDuration,
    );

    await controller.forward();
    controller.dispose();
  }
}

// ==============================================================================
// C. SPEAKING PULSE ANIMATION
// ==============================================================================

/// Continuously pulses when participant is speaking
class SpeakingPulseAnimation extends StatefulWidget {
  final Widget child;
  final bool isSpeaking;

  const SpeakingPulseAnimation({
    super.key,
    required this.child,
    required this.isSpeaking,
  });

  @override
  State<SpeakingPulseAnimation> createState() => _SpeakingPulseAnimationState();
}

class _SpeakingPulseAnimationState extends State<SpeakingPulseAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: DesignAnimations.speakingPulseDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isSpeaking) {
      _startPulsing();
    }
  }

  void _startPulsing() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulsing() {
    _pulseController.stop();
  }

  @override
  void didUpdateWidget(SpeakingPulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _startPulsing();
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _stopPulsing();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: widget.isSpeaking
                  ? [
                      DesignShadows.subtle,
                      BoxShadow(
                        color: DesignColors.accent
                            .withValues(alpha: _shadowAnimation.value * 0.4),
                        blurRadius: 8 * _shadowAnimation.value,
                        spreadRadius: 2 * _shadowAnimation.value,
                      ),
                    ]
                  : [DesignShadows.subtle],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ==============================================================================
// D. NOTIFICATION ANIMATION
// ==============================================================================

/// Slides in notification from top, auto-dismisses
class NotificationAnimation extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onComplete;

  const NotificationAnimation({
    super.key,
    required this.message,
    required this.type,
    required this.onComplete,
  });

  @override
  State<NotificationAnimation> createState() => _NotificationAnimationState();
}

class _NotificationAnimationState extends State<NotificationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeOutController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    // Slide in from top
    _slideController = AnimationController(
      vsync: this,
      duration: DesignAnimations.notificationFadeInDuration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _slideController, curve: DesignAnimations.easeOutCubic),
    );

    // Fade out after visible duration
    _fadeOutController = AnimationController(
      vsync: this,
      duration: DesignAnimations.notificationFadeOutDuration,
    );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
          parent: _fadeOutController, curve: DesignAnimations.easeInCubic),
    );

    _slideController.forward().then((_) {
      Future.delayed(widget.type.visibleDuration, () {
        if (mounted) {
          _fadeOutController.forward().then((_) {
            widget.onComplete();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _fadeOutController]),
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 100,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(DesignSpacing.lg),
        decoration: BoxDecoration(
          color: widget.type.backgroundColor,
          borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
        ),
        child: Text(
          widget.message,
          style: DesignTypography.body.copyWith(
            color: DesignColors.accent,
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// E. BUTTON FEEDBACK ANIMATION
// ==============================================================================

/// Press feedback: scale down + release
class ButtonFeedbackAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const ButtonFeedbackAnimation({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  State<ButtonFeedbackAnimation> createState() =>
      _ButtonFeedbackAnimationState();
}

class _ButtonFeedbackAnimationState extends State<ButtonFeedbackAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: DesignAnimations.buttonPressDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    await _pressController.forward();
    await _pressController.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ==============================================================================
// F. ROOM ENERGY CARD ANIMATION
// ==============================================================================

/// Room card with energy indicator that changes based on room state
class RoomEnergyCardAnimation extends StatefulWidget {
  final String roomName;
  final double energy;
  final int participantCount;
  final VoidCallback onTap;

  const RoomEnergyCardAnimation({
    super.key,
    required this.roomName,
    required this.energy,
    required this.participantCount,
    required this.onTap,
  });

  @override
  State<RoomEnergyCardAnimation> createState() =>
      _RoomEnergyCardAnimationState();
}

class _RoomEnergyCardAnimationState extends State<RoomEnergyCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _energyController;
  late Animation<double> _energyPulse;

  @override
  void initState() {
    super.initState();
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _energyPulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _energyController, curve: Curves.easeInOut),
    );

    // Pulse energy indicator continuously
    _energyController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(RoomEnergyCardAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.energy - widget.energy).abs() > 0.1) {
      // Energy changed significantly, emphasize it
      _energyController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energyColor = RoomEnergyThresholds.getEnergyColor(widget.energy);
    final energyLabel = RoomEnergyThresholds.getEnergyLabel(widget.energy);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _energyPulse,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(DesignSpacing.cardPadding),
            decoration: BoxDecoration(
              border: DesignBorders.cardDefault,
              borderRadius:
                  BorderRadius.circular(DesignSpacing.cardBorderRadius),
              color: DesignColors.accent,
              boxShadow: const [DesignShadows.subtle],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: DesignTypography.heading,
                ),
                const SizedBox(height: DesignSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.participantCount} people',
                      style: DesignTypography.caption,
                    ),
                    Transform.scale(
                      scale: _energyPulse.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSpacing.md,
                          vertical: DesignSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: energyColor.withValues(alpha: 0.1),
                          border: Border.all(color: energyColor, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          energyLabel,
                          style: DesignTypography.label.copyWith(
                            color: energyColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
