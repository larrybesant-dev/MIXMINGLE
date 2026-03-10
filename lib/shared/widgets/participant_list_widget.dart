import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/participant.dart';

class ParticipantListWidget extends StatelessWidget {
  final List<Participant> participants;
  final Function(Participant)? onParticipantTap;
  final Function(Participant)? onParticipantLongPress;
  final bool showHostIndicator;
  final String? hostId;

  const ParticipantListWidget({
    super.key,
    required this.participants,
    this.onParticipantTap,
    this.onParticipantLongPress,
    this.showHostIndicator = true,
    this.hostId,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(DesignSpacing.md),
      decoration: BoxDecoration(
        color: DesignColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.people,
                color: DesignColors.accent,
                size: 20,
              ),
              const SizedBox(width: DesignSpacing.sm),
              Text(
                'Participants (${participants.length})',
                style: DesignTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DesignColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignSpacing.md),

          // Participant list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return _buildParticipantItem(participant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignSpacing.xl),
      decoration: BoxDecoration(
        color: DesignColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            color: DesignColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: DesignSpacing.md),
          Text(
            'No participants yet',
            style: DesignTypography.body.copyWith(
              color: DesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: DesignSpacing.sm),
          Text(
            'Share the room link to invite others',
            style: DesignTypography.caption.copyWith(
              color: DesignColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(Participant participant) {
    final isHost = showHostIndicator && participant.id == hostId;
    final isMuted = participant.isMuted;
    final isVideoEnabled = participant.isVideoEnabled;
    final isSpeaking = participant.isSpeaking;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignSpacing.sm),
      padding: const EdgeInsets.all(DesignSpacing.md),
      decoration: BoxDecoration(
        color: isSpeaking
            ? DesignColors.accent.withValues(alpha: 0.1)
            : DesignColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSpeaking
              ? DesignColors.accent.withValues(alpha: 0.3)
              : DesignColors.surface,
        ),
      ),
      child: InkWell(
        onTap: () => onParticipantTap?.call(participant),
        onLongPress: () => onParticipantLongPress?.call(participant),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignColors.accent,
                    DesignColors.gold,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  participant.name.isNotEmpty
                      ? participant.name[0].toUpperCase()
                      : '?',
                  style: DesignTypography.body.copyWith(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: DesignSpacing.md),

            // Participant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Name
                      Text(
                        participant.name,
                        style: DesignTypography.body.copyWith(
                          color: DesignColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Host indicator
                      if (isHost) ...[
                        const SizedBox(width: DesignSpacing.xs),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: DesignColors.gold,
                        ),
                      ],

                      // Speaking indicator
                      if (isSpeaking) ...[
                        const SizedBox(width: DesignSpacing.xs),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: DesignColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DesignColors.success.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Status indicators
                  Row(
                    children: [
                      // Audio status
                      Icon(
                        isMuted ? Icons.mic_off : Icons.mic,
                        size: 14,
                        color: isMuted
                            ? DesignColors.error
                            : DesignColors.textSecondary,
                      ),

                      const SizedBox(width: DesignSpacing.sm),

                      // Video status
                      Icon(
                        isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        size: 14,
                        color: isVideoEnabled
                            ? DesignColors.textSecondary
                            : DesignColors.error,
                      ),

                      // Connection quality (placeholder)
                      const SizedBox(width: DesignSpacing.sm),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DesignColors.success, // Could be dynamic based on connection
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action menu
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: DesignColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _showParticipantMenu(participant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantMenu(Participant participant) {
    // The menu actions need BuildContext, so this should be called from itemBuilder
    // For now, trigger the callback if available
    onParticipantTap?.call(participant);
  }
}
