import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../providers/all_providers.dart';
// TEMP DISABLED: import '../../models/speed_dating.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/neon_button.dart';

class SpeedDatingRoomPage extends ConsumerStatefulWidget {
  final SpeedDatingSession session;

  const SpeedDatingRoomPage({super.key, required this.session});

  @override
  ConsumerState<SpeedDatingRoomPage> createState() => _SpeedDatingRoomPageState();
}

class _SpeedDatingRoomPageState extends ConsumerState<SpeedDatingRoomPage> with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _timerBarController;
  late Animation<double> _timerBarAnimation;
  bool _isAgoraInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize timer bar animation
    _timerBarController = AnimationController(duration: const Duration(minutes: 10), vsync: this);

    _timerBarAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_timerBarController);

    // Start the session if it's matched
    _startSessionIfNeeded();

    // Initialize Agora
    _initializeAgora();

    // Start the timer
    _startTimer();

    // Start timer bar animation
    _timerBarController.forward();
  }

  Future<void> _startSessionIfNeeded() async {
    if (widget.session.status.name == 'matched') {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.startSpeedDatingSession(widget.session.id);
      } catch (e) {
        debugPrint('Failed to start session: $e');
      }
    }
  }

  Future<void> _initializeAgora() async {
    try {
      final agoraService = ref.read(agoraVideoServiceProvider);

      // Initialize Agora engine if needed
      if (!agoraService.isInitialized) {
        await agoraService.initialize();
      }

      // Join the speed dating channel
      await agoraService.joinRoom('speed_dating_${widget.session.id}');

      setState(() {
        _isAgoraInitialized = true;
      });
    } catch (e) {
      debugPrint('Failed to initialize Agora: $e');
    }
  }

  void _startTimer() {
    // TODO: Fix timer provider
    // ref.read(speedDatingTimerProvider.notifier).startTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // final remaining = ref.read(speedDatingTimerProvider) - const Duration(seconds: 1);
      // ref.read(speedDatingTimerProvider.notifier).updateTimer(remaining);

      // if (remaining.inSeconds <= 0) {
      //   _timer.cancel();
      //   _onTimeUp();
      // }
    });
  }

  // ignore: unused_element
  void _onTimeUp() {
    // Navigate to decision page
    Navigator.of(context).pushReplacementNamed('/speed-dating-decision', arguments: widget.session);
  }

  @override
  void dispose() {
    _timer.cancel();
    _timerBarController.dispose();
    // Leave the Agora room
    if (_isAgoraInitialized) {
      try {
        ref.read(agoraVideoServiceProvider).leaveRoom();
      } catch (e) {
        debugPrint('Error leaving speed dating room: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final remainingTime = ref.watch(speedDatingTimerProvider);
    // final sessionAsync = ref.watch(speedDatingSessionProvider(widget.session.id));

    // Temporary: render with dummy data for Agora testing
    final remainingTime = Duration.zero;
    final sessionAsync = AsyncData(widget.session);

    return sessionAsync.when(
      data: (currentSession) {
        return _buildRoomScreen(currentSession, remainingTime);
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error.toString()),
    );
  }

  Widget _buildLoadingScreen() {
    return ClubBackground(
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C)))),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF4C4C)),
              const SizedBox(height: 16),
              GlowText(text: 'Error', fontSize: 24, color: const Color(0xFFFF4C4C), glowColor: const Color(0xFFFF4C4C)),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              NeonButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomScreen(SpeedDatingSession session, Duration remainingTime) {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Video area with Agora video views
            Container(
              color: const Color(0xFF1A1A2E),
              child: _isAgoraInitialized
                  ? Stack(
                      children: [
                        // Remote video (full screen background)
                        AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: ref.read(agoraVideoServiceProvider).engine!,
                            canvas: const VideoCanvas(uid: 0),
                            connection: RtcConnection(channelId: 'speed_dating_${widget.session.id}'),
                          ),
                        ),
                        // Local video (small overlay)
                        Positioned(
                          top: 20,
                          right: 20,
                          width: 120,
                          height: 160,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: ref.read(agoraVideoServiceProvider).engine!,
                                  canvas: const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFF4C4C)),
                          SizedBox(height: 16),
                          Text('Initializing video...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
            ),

            // Timer overlay
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Animated timer bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(color: const Color(0xFF2A2A3D), borderRadius: BorderRadius.circular(4)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: _timerBarAnimation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _timerBarAnimation.value,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(_getTimerBarColor(_timerBarAnimation.value)),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timer display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getTimerBorderColor(remainingTime), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, color: _getTimerColor(remainingTime), size: 20),
                        const SizedBox(width: 8),
                        GlowText(
                          text: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getTimerColor(remainingTime),
                          glowColor: _getTimerGlowColor(remainingTime),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Control buttons
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: ref.watch(agoraVideoServiceProvider).isMicMuted ? Icons.mic_off : Icons.mic,
                    label: ref.watch(agoraVideoServiceProvider).isMicMuted ? 'Unmute' : 'Mute',
                    onPressed: () async {
                      try {
                        await ref.read(agoraVideoServiceProvider).toggleMic();
                        setState(() {}); // Trigger rebuild to update icon
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed to toggle microphone: $e')));
                        }
                      }
                    },
                  ),
                  _buildControlButton(
                    icon: ref.watch(agoraVideoServiceProvider).isVideoMuted ? Icons.videocam_off : Icons.videocam,
                    label: ref.watch(agoraVideoServiceProvider).isVideoMuted ? 'Camera On' : 'Camera Off',
                    onPressed: () async {
                      try {
                        await ref.read(agoraVideoServiceProvider).toggleVideo();
                        setState(() {}); // Trigger rebuild to update icon
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed to toggle camera: $e')));
                        }
                      }
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    backgroundColor: const Color(0xFFFF4C4C),
                    onPressed: () => _showEndCallDialog(),
                  ),
                ],
              ),
            ),

            // Partner info
            Positioned(
              top: 120,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3D).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('Chatting with', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    GlowText(
                      text: 'Anonymous User', // TODO: Get actual user name
                      fontSize: 14,
                      color: const Color(0xFFFFD700),
                      glowColor: const Color(0xFFFF4C4C),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF2A2A3D),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Color _getTimerBarColor(double progress) {
    if (progress > 0.5) {
      return const Color(0xFFFFD700); // Yellow
    } else if (progress > 0.2) {
      return const Color(0xFFFF8C00); // Orange
    } else {
      return const Color(0xFFFF4C4C); // Red
    }
  }

  Color _getTimerColor(Duration remaining) {
    if (remaining.inMinutes >= 5) {
      return const Color(0xFFFFD700);
    } else if (remaining.inMinutes >= 2) {
      return const Color(0xFFFF8C00);
    } else {
      return const Color(0xFFFF4C4C);
    }
  }

  Color _getTimerGlowColor(Duration remaining) {
    if (remaining.inMinutes >= 5) {
      return const Color(0xFFFF4C4C);
    } else if (remaining.inMinutes >= 2) {
      return const Color(0xFFFF8C00);
    } else {
      return const Color(0xFFFF4C4C);
    }
  }

  Color _getTimerBorderColor(Duration remaining) {
    if (remaining.inMinutes >= 5) {
      return const Color(0xFFFFD700).withValues(alpha: 0.5);
    } else if (remaining.inMinutes >= 2) {
      return const Color(0xFFFF8C00).withValues(alpha: 0.5);
    } else {
      return const Color(0xFFFF4C4C).withValues(alpha: 0.5);
    }
  }

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: const GlowText(
          text: 'End Speed Date?',
          fontSize: 20,
          color: Color(0xFFFFD700),
          glowColor: Color(0xFFFF4C4C),
        ),
        content: const Text(
          'Are you sure you want to end this speed dating session early?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endSessionEarly();
            },
            child: const Text('End Call', style: TextStyle(color: Color(0xFFFF4C4C))),
          ),
        ],
      ),
    );
  }

  void _endSessionEarly() {
    // Cancel the session and go back to lobby
    // TODO: Fix speed dating lobby provider
    // ref.read(speedDatingLobbyProvider.notifier).leaveLobby();
    Navigator.of(context).pop();
  }
}
