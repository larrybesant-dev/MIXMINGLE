/// CANONICAL EXAMPLE: Presence Card Widget
///
/// This file demonstrates the CORRECT way to implement a card that shows
/// a participant in a Video Room. It enforces:
/// - DESIGN_BIBLE.md Section A (colors)
/// - DESIGN_BIBLE.md Section B (typography, spacing)
/// - DESIGN_BIBLE.md Section C (animations)
/// - DESIGN_SECRETS_INTEGRATION.md (hard-coded values)
///
/// THIS IS A BINDING EXAMPLE. Copy this pattern exactly for new widgets.
///
/// DO NOT USE Material Card, ListTile, or Colors.*
/// DO USE DesignColors.*, DesignTypography.*, DesignSpacing.*
library;

import 'package:flutter/material.dart';
import '../../../../core/design_system/design_constants.dart';
import '../../../core/design_system/design_animations.dart';

/// Participant presence card shown in room participant list.
///
/// Features:
/// - âœ… Custom card (no Material Card)
/// - âœ… Speaking pulse animation
/// - âœ… Arrival/departure slide animation
/// - âœ… All colors from DesignColors
/// - âœ… All spacing from DesignSpacing
/// - âœ… All animations from DesignAnimations
class PresenceCard extends StatefulWidget {
  /// Participant name (e.g., "Emma")
  final String participantName;

  /// Avatar image URL
  final String? avatarUrl;

  /// Whether this participant is currently speaking
  final bool isSpeaking;

  /// When this participant joined (for sorting)
  final DateTime joinedAt;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Whether to show arrival animation (slide in from bottom)
  final bool showArrivalAnimation;

  const PresenceCard({super.key,
    required this.participantName,
    this.avatarUrl,
    required this.isSpeaking,
    required this.joinedAt,
    required this.onTap,
    this.showArrivalAnimation = true,
  });

  @override
  State<PresenceCard> createState() => _PresenceCardState();
}

class _PresenceCardState extends State<PresenceCard>
    with TickerProviderStateMixin {
  /// Controls the arrival slide animation
  late AnimationController _arrivalController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeArrivalAnimation();
  }

  void _initializeArrivalAnimation() {
    if (!widget.showArrivalAnimation) {
      return;
    }

    // Slide in from bottom + fade in (250ms per DESIGN_BIBLE)
    _arrivalController = AnimationController(
      vsync: this,
      duration: DesignAnimations.presenceSlideInDuration, // 250ms
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start slightly below
      end: Offset.zero, // End at final position
    ).animate(
      CurvedAnimation(
        parent: _arrivalController,
        curve: DesignAnimations.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _arrivalController,
        curve: DesignAnimations.easeOutCubic,
      ),
    );

    _arrivalController.forward();
  }

  @override
  void dispose() {
    _arrivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with arrival animation if enabled
    Widget card = _buildCard();

    if (widget.showArrivalAnimation) {
      card = AnimatedBuilder(
        animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value * 50,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: card,
      );
    }

    // Wrap with speaking pulse if speaking
    if (widget.isSpeaking) {
      card = SpeakingPulseAnimation(
        isSpeaking: true,
        child: card,
      );
    }

    return card;
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // âœ… Spacing: use DesignSpacing
        padding: EdgeInsets.all(DesignSpacing.lg), // 16px
        margin: EdgeInsets.only(bottom: DesignSpacing.md), // 12px gap between cards

        // âœ… Design: custom borders, shadows, no Material Card
        decoration: BoxDecoration(
          border: DesignBorders.cardDefault,
          borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
          color: DesignColors.accent,
          boxShadow: [DesignShadows.subtle],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar + Name + Mute indicator
            Row(
              children: [
                // âœ… Avatar
                Container(
                  width: DesignSpacing.avatarMedium,
                  height: DesignSpacing.avatarMedium,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      DesignSpacing.avatarMedium / 2,
                    ),
                    color: DesignColors.accent,
                  ),
                  child: widget.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DesignSpacing.avatarMedium / 2,
                          ),
                          child: Image.network(
                            widget.avatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: DesignColors.accent,
                        ),
                ),

                // Spacer
                SizedBox(width: DesignSpacing.lg), // 16px gap

                // âœ… Name (typography: subheading)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.participantName,
                        style: DesignTypography.subheading,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Speaking indicator
                      if (widget.isSpeaking) ...[
                        SizedBox(height: DesignSpacing.xs), // 4px
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignSpacing.sm,
                            vertical: DesignSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: DesignColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Speaking now',
                            style: DesignTypography.caption.copyWith(
                              color: DesignColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Mute button (if not speaking)
                if (!widget.isSpeaking)
                  Icon(
                    Icons.mic_off,
                    color: DesignColors.accent,
                    size: 20,
                  ),
              ],
            ),

            // Bottom row: Joined time
            Padding(
              padding: EdgeInsets.only(top: DesignSpacing.md),
              child: Text(
                _formatJoinTime(),
                style: DesignTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinTime() {
    final now = DateTime.now();
    final difference = now.difference(widget.joinedAt);

    if (difference.inSeconds < 60) {
      return 'Just joined';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// ==============================================================================
// EXAMPLE USAGE
// ==============================================================================

/// Example widget showing how to use PresenceCard
class RoomParticipantsList extends StatelessWidget {
  final List<Map<String, dynamic>> participants;

  const RoomParticipantsList({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(DesignSpacing.lg),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];

        return PresenceCard(
          participantName: participant['name'] as String,
          avatarUrl: participant['avatarUrl'] as String?,
          isSpeaking: participant['isSpeaking'] as bool? ?? false,
          joinedAt: participant['joinedAt'] as DateTime,
          showArrivalAnimation: index == 0, // Animate first arrival
          onTap: () {
            // Navigate or show details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tapped ${participant['name']}'),
                duration: Duration(milliseconds: 500),
              ),
            );
          },
        );
      },
    );
  }
}

// ==============================================================================
// TESTING EXAMPLE
// ==============================================================================

class PresenceCardTestScreen extends StatefulWidget {
  const PresenceCardTestScreen({super.key});

  @override
  State<PresenceCardTestScreen> createState() =>
      _PresenceCardTestScreenState();
}

class _PresenceCardTestScreenState extends State<PresenceCardTestScreen> {
  late List<Map<String, dynamic>> _testParticipants;

  @override
  void initState() {
    super.initState();
    _testParticipants = [
      {
        'name': 'Emma',
        'avatarUrl': null,
        'isSpeaking': true,
        'joinedAt': DateTime.now().subtract(Duration(minutes: 5)),
      },
      {
        'name': 'James',
        'avatarUrl': null,
        'isSpeaking': false,
        'joinedAt': DateTime.now().subtract(Duration(minutes: 2)),
      },
      {
        'name': 'Sarah',
        'avatarUrl': null,
        'isSpeaking': false,
        'joinedAt': DateTime.now().subtract(Duration(seconds: 30)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Presence Cards Test')),
      body: Column(
        children: [
          // Show current participants
          Expanded(
            child: RoomParticipantsList(participants: _testParticipants),
          ),

          // Button to toggle speaking state
          Padding(
            padding: EdgeInsets.all(DesignSpacing.lg),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _testParticipants[0]['isSpeaking'] =
                      !_testParticipants[0]['isSpeaking'];
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSpacing.lg,
                  vertical: DesignSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: DesignColors.accent,
                  borderRadius: BorderRadius.circular(
                    DesignSpacing.buttonBorderRadius,
                  ),
                ),
                child: Text(
                  'Toggle Speaking',
                  style: DesignTypography.button,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// KEY PATTERNS FOR REPLICATION
// ==============================================================================

/*
PATTERN 1: Import Design System
âœ… import './core/design_system/design_constants.dart';
âœ… import './core/design_system/design_animations.dart';

PATTERN 2: Colors
âœ… color: DesignColors.accent
âœ… color: DesignColors.accent
âœ… color: DesignColors.accent
âŒ color: DesignColors.accent
âŒ color: DesignColors.accent

PATTERN 3: Typography
âœ… style: DesignTypography.subheading
âœ… style: DesignTypography.caption
âŒ style: DesignTypography.body

PATTERN 4: Spacing
âœ… padding: EdgeInsets.all(DesignSpacing.lg)
âœ… height: DesignSpacing.avatarMedium
âœ… gap: SizedBox(height: DesignSpacing.md)
âŒ padding: EdgeInsets.all(DesignSpacing.lg)
âŒ height: 40

PATTERN 5: Borders & Shadows
âœ… decoration: BoxDecoration(
    border: DesignBorders.cardDefault,
    boxShadow: [DesignShadows.subtle],
  )
âŒ No Material Card
âŒ No Material shadows

PATTERN 6: Animations
âœ… duration: DesignAnimations.presenceSlideInDuration
âœ… curve: DesignAnimations.easeOutCubic
âœ… AnimatedBuilder with DesignAnimations durations
âŒ Duration(milliseconds: 250)
âŒ Curves.easeOut

PATTERN 7: Custom Widgets
âœ… Everything extended from StatelessWidget/StatefulWidget
âœ… All building with Container + BoxDecoration
âœ… All interactions via GestureDetector
âŒ No Material Card
âŒ No Material Button
âŒ No Material ListTile

PATTERN 8: Testing
âœ… Test that widget respects DesignAnimations durations
âœ… Test that colors use DesignColors
âœ… Test animation triggers at right times
âœ… flutter test test/design_constants_test.dart
*/
