import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

class JoinRoomScreen extends StatefulWidget {
  final String roomName;
  final String roomId;
  final VoidCallback onJoin;
  final VoidCallback onCancel;

  const JoinRoomScreen({
    super.key,
    required this.roomName,
    required this.roomId,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: DesignColors.white),
          onPressed: widget.onCancel,
        ),
        title: Text(
          'Join Room',
          style: DesignTypography.heading.copyWith(
            color: DesignColors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignSpacing.xl),
          child: Column(
            children: [
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Room icon with pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    DesignColors.accent.withValues(alpha: 0.8),
                                    DesignColors.gold.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignColors.accent.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.video_call,
                                size: 60,
                                color: DesignColors.white,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: DesignSpacing.xl),

                      // Room name
                      Text(
                        widget.roomName,
                        style: DesignTypography.display.copyWith(
                          color: DesignColors.white,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: DesignSpacing.md),

                      // Room ID
                      Text(
                        'Room ID: ${widget.roomId}',
                        style: DesignTypography.caption.copyWith(
                          color: DesignColors.white.withValues(alpha: 0.7),
                        ),
                      ),

                      const SizedBox(height: DesignSpacing.xl),

                      // Join instructions
                      Container(
                        padding: const EdgeInsets.all(DesignSpacing.lg),
                        decoration: BoxDecoration(
                          color: DesignColors.surface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: DesignColors.accent,
                              size: 24,
                            ),
                            const SizedBox(height: DesignSpacing.md),
                            Text(
                              'Getting ready to join...',
                              style: DesignTypography.body.copyWith(
                                color: DesignColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DesignSpacing.sm),
                            Text(
                              'Please ensure your camera and microphone are ready',
                              style: DesignTypography.caption.copyWith(
                                color: DesignColors.white.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Join button
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: DesignSpacing.lg),
                child: ElevatedButton(
                  onPressed: widget.onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignColors.accent,
                    foregroundColor: DesignColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                    shadowColor: DesignColors.accent.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    'Join Room',
                    style: DesignTypography.button,
                  ),
                ),
              ),

              // Cancel button
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: DesignTypography.body.copyWith(
                    color: DesignColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
