import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

class LeaveRoomScreen extends StatefulWidget {
  final String roomName;
  final int participantCount;
  final Duration timeInRoom;
  final VoidCallback onLeave;
  final VoidCallback onCancel;

  const LeaveRoomScreen({
    super.key,
    required this.roomName,
    required this.participantCount,
    required this.timeInRoom,
    required this.onLeave,
    required this.onCancel,
  });

  @override
  State<LeaveRoomScreen> createState() => _LeaveRoomScreenState();
}

class _LeaveRoomScreenState extends State<LeaveRoomScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        body: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(DesignSpacing.xl),
              padding: const EdgeInsets.all(DesignSpacing.xl),
              decoration: BoxDecoration(
                color: DesignColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(DesignSpacing.md),
                        decoration: BoxDecoration(
                          color: DesignColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.exit_to_app,
                          color: DesignColors.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: DesignSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Leave Room',
                              style: DesignTypography.heading,
                            ),
                            Text(
                              widget.roomName,
                              style: DesignTypography.caption.copyWith(
                                color: DesignColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: DesignColors.textSecondary),
                        onPressed: widget.onCancel,
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignSpacing.xl),

                  // Room stats
                  Container(
                    padding: const EdgeInsets.all(DesignSpacing.lg),
                    decoration: BoxDecoration(
                      color: DesignColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          icon: Icons.people,
                          value: '${widget.participantCount}',
                          label: 'Participants',
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: DesignColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        _buildStat(
                          icon: Icons.access_time,
                          value: _formatDuration(widget.timeInRoom),
                          label: 'Time Here',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DesignSpacing.xl),

                  // Warning message
                  Container(
                    padding: const EdgeInsets.all(DesignSpacing.lg),
                    decoration: BoxDecoration(
                      color: DesignColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: DesignColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: DesignSpacing.md),
                        Expanded(
                          child: Text(
                            'You will disconnect from the video call and lose access to the room.',
                            style: DesignTypography.body.copyWith(
                              color: DesignColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DesignSpacing.xl),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: DesignColors.textSecondary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Stay',
                            style: DesignTypography.button.copyWith(
                              color: DesignColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignSpacing.lg),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onLeave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignColors.error,
                            foregroundColor: DesignColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Leave Room',
                            style: DesignTypography.button,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: DesignColors.textSecondary, size: 20),
        const SizedBox(height: DesignSpacing.sm),
        Text(
          value,
          style: DesignTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: DesignColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: DesignTypography.caption.copyWith(
            color: DesignColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
