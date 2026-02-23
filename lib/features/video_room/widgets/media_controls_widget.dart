import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

class MediaControlsWidget extends StatefulWidget {
  final bool isMicEnabled;
  final bool isCameraEnabled;
  final bool isScreenSharing;
  final Function(bool)? onMicToggle;
  final Function(bool)? onCameraToggle;
  final Function(bool)? onScreenShareToggle;
  final VoidCallback? onMoreOptions;

  const MediaControlsWidget({
    super.key,
    required this.isMicEnabled,
    required this.isCameraEnabled,
    this.isScreenSharing = false,
    this.onMicToggle,
    this.onCameraToggle,
    this.onScreenShareToggle,
    this.onMoreOptions,
  });

  @override
  State<MediaControlsWidget> createState() => _MediaControlsWidgetState();
}

class _MediaControlsWidgetState extends State<MediaControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSpacing.lg),
      margin: EdgeInsets.all(DesignSpacing.lg),
      decoration: BoxDecoration(
        color: DesignColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: DesignColors.shadowColor,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: DesignColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Microphone control
          _buildControlButton(
            icon: widget.isMicEnabled ? Icons.mic : Icons.mic_off,
            isActive: widget.isMicEnabled,
            activeColor: DesignColors.accent,
            inactiveColor: DesignColors.error,
            onPressed: () => widget.onMicToggle?.call(!widget.isMicEnabled),
            tooltip: widget.isMicEnabled ? 'Mute microphone' : 'Unmute microphone',
          ),

          SizedBox(width: DesignSpacing.md),

          // Camera control
          _buildControlButton(
            icon: widget.isCameraEnabled ? Icons.videocam : Icons.videocam_off,
            isActive: widget.isCameraEnabled,
            activeColor: DesignColors.accent,
            inactiveColor: DesignColors.error,
            onPressed: () => widget.onCameraToggle?.call(!widget.isCameraEnabled),
            tooltip: widget.isCameraEnabled ? 'Turn off camera' : 'Turn on camera',
          ),

          SizedBox(width: DesignSpacing.md),

          // Screen share control
          _buildControlButton(
            icon: widget.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            isActive: widget.isScreenSharing,
            activeColor: DesignColors.gold,
            inactiveColor: DesignColors.textSecondary,
            onPressed: () => widget.onScreenShareToggle?.call(!widget.isScreenSharing),
            tooltip: widget.isScreenSharing ? 'Stop sharing' : 'Share screen',
          ),

          SizedBox(width: DesignSpacing.md),

          // More options
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignColors.surface,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.more_vert,
                color: DesignColors.textPrimary,
                size: 20,
              ),
              onPressed: widget.onMoreOptions,
              tooltip: 'More options',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? activeColor : DesignColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeColor : inactiveColor,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: isActive ? DesignColors.white : inactiveColor,
                size: 24,
              ),
              onPressed: () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                onPressed();
              },
              tooltip: tooltip,
            ),
          ),
        );
      },
    );
  }
}

// Extension for positioning the controls
class MediaControlsOverlay extends StatelessWidget {
  final Widget child;
  final MediaControlsWidget controls;

  const MediaControlsOverlay({
    super.key,
    required this.child,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: DesignSpacing.xl,
          left: 0,
          right: 0,
          child: Center(child: controls),
        ),
      ],
    );
  }
}
