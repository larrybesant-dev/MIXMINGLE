import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

class RoomHeader extends StatelessWidget {
  final String roomName;
  final String roomId;
  final int participantCount;
  final bool isHost;
  final String? hostName;
  final VoidCallback onLeave;
  final VoidCallback? onSettings;
  final VoidCallback? onInvite;

  const RoomHeader({
    super.key,
    required this.roomName,
    required this.roomId,
    required this.participantCount,
    this.isHost = false,
    this.hostName,
    required this.onLeave,
    this.onSettings,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + DesignSpacing.md,
        left: DesignSpacing.lg,
        right: DesignSpacing.lg,
        bottom: DesignSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignColors.surface.withValues(alpha: 0.95),
            DesignColors.surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: DesignColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with room info and actions
          Row(
            children: [
              // Room info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room name
                    Text(
                      roomName,
                      style: DesignTypography.heading.copyWith(
                        color: DesignColors.textPrimary,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: DesignSpacing.xs),

                    // Room details
                    Row(
                      children: [
                        // Room ID
                        Text(
                          'ID: ${roomId.substring(0, 8)}...',
                          style: DesignTypography.caption.copyWith(
                            color: DesignColors.textSecondary,
                          ),
                        ),

                        // Separator
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: DesignSpacing.sm),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: DesignColors.textSecondary.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),

                        // Host indicator
                        if (isHost) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: DesignColors.gold,
                          ),
                          SizedBox(width: DesignSpacing.xs),
                          Text(
                            'Host',
                            style: DesignTypography.caption.copyWith(
                              color: DesignColors.gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (hostName != null) ...[
                          Text(
                            'Host: $hostName',
                            style: DesignTypography.caption.copyWith(
                              color: DesignColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Invite button
                  if (onInvite != null)
                    IconButton(
                      icon: Icon(
                        Icons.person_add,
                        color: DesignColors.accent,
                        size: 20,
                      ),
                      onPressed: onInvite,
                      tooltip: 'Invite others',
                    ),

                  // Settings button
                  if (onSettings != null)
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: DesignColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: onSettings,
                      tooltip: 'Room settings',
                    ),

                  // Leave button
                  Container(
                    margin: EdgeInsets.only(left: DesignSpacing.sm),
                    child: ElevatedButton.icon(
                      onPressed: onLeave,
                      icon: Icon(
                        Icons.exit_to_app,
                        size: 16,
                      ),
                      label: Text('Leave'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignColors.error,
                        foregroundColor: DesignColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignSpacing.md,
                          vertical: DesignSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: DesignSpacing.md),

          // Bottom row with participant count and status
          Row(
            children: [
              // Participant count
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSpacing.md,
                  vertical: DesignSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: DesignColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DesignColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: DesignColors.accent,
                    ),
                    SizedBox(width: DesignSpacing.xs),
                    Text(
                      '$participantCount ${participantCount == 1 ? 'person' : 'people'}',
                      style: DesignTypography.caption.copyWith(
                        color: DesignColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer
              Expanded(child: Container()),

              // Room status
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSpacing.md,
                  vertical: DesignSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: DesignColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DesignColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DesignColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: DesignSpacing.xs),
                    Text(
                      'Live',
                      style: DesignTypography.caption.copyWith(
                        color: DesignColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
