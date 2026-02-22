library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Speed Dating Session Page
/// 5-minute video call with matched partner

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
// TEMP DISABLED: import '../providers/speed_dating_session_cloud.dart';
import '../../../providers/auth_providers.dart';

/// Speed Dating Session - Active video call
class SpeedDatingSessionPage extends ConsumerStatefulWidget {
  final String sessionId;

  const SpeedDatingSessionPage({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<SpeedDatingSessionPage> createState() =>
      _SpeedDatingSessionPageState();
}

class _SpeedDatingSessionPageState
    extends ConsumerState<SpeedDatingSessionPage> {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    try {
      final sessionAsync = ref.read(activeSessionProvider);
      final session = sessionAsync.value;
      if (session == null) return;

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: 'ec1b578586d24976a89d787d9ee4d5c7',
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('âœ… Joined channel: ${connection.channelId}');
            setState(() => _isInitialized = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('ðŸ‘¤ Remote user joined: $remoteUid');
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('ðŸ‘‹ Remote user left: $remoteUid');
            if (_remoteUid == remoteUid) {
              setState(() => _remoteUid = null);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('âŒ Agora Error: $err - $msg');
          },
        ),
      );

      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Join channel (in production, get token from backend)
      await _engine!.joinChannel(
        token: '', // TODO: Get from Cloud Function
        channelId: session.agoraChannelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      debugPrint('âŒ Error initializing Agora: $e');
    }
  }

  Future<void> _cleanup() async {
    await _engine?.leaveChannel();
    await _engine?.release();
  }

  Future<void> _makeDecision(String decision) async {
    await ref
        .read(speedDatingSessionProvider.notifier)
        .makeDecision(decision);

    // Check if both decided
    final sessionAsync = ref.read(activeSessionProvider);
    final session = sessionAsync;
    if (session.bothDecided ?? false) {
      _navigateToDecisionResults();
    }
  }

  void _navigateToDecisionResults() {
    Navigator.pushReplacementNamed(
      context,
      '/speed-dating/decision',
      arguments: widget.sessionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(activeSessionProvider);
    final timeRemaining = ref.watch(timeRemainingProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Session not found'),
                  const SizedBox(height: 16),
                  NeonButton(
                    label: 'Back to Lobby',
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/speed-dating'),
                    glowColor: DesignColors.accent,
                  ),
                ],
              ),
            ),
          );
        }

        // Check if time's up
        if (session.hasEnded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToDecisionResults();
          });
        }

        final minutes = timeRemaining ~/ 60;
        final seconds = timeRemaining % 60;

        return ClubBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  // Video views
                  Column(
                    children: [
                      // Remote video (partner)
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.black,
                          child: _remoteUid != null
                              ? AgoraVideoView(
                                  controller: VideoViewController.remote(
                                    rtcEngine: _engine!,
                                    canvas: VideoCanvas(uid: _remoteUid),
                                    connection: RtcConnection(
                                      channelId: session.agoraChannelName,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Waiting for partner...',
                                        style: TextStyle(
                                          color: DesignColors.white
                                              .withValues(alpha: 255, red: 255, green: 255, blue: 255),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      // Local video (you)
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.black87,
                          child: _engine != null
                              ? AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: _engine!,
                                    canvas: const VideoCanvas(uid: 0),
                                  ),
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // Top: Timer
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: NeonText(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          textColor: timeRemaining < 30
                              ? Colors.red
                              : DesignColors.accent,
                          glowColor: timeRemaining < 30
                              ? Colors.red
                              : DesignColors.accent,
                        ),
                      ),
                    ),
                  ),

                  // Bottom: Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Video controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                icon: _isMuted ? Icons.mic_off : Icons.mic,
                                label: _isMuted ? 'Unmute' : 'Mute',
                                onPressed: () async {
                                  await _engine?.muteLocalAudioStream(!_isMuted);
                                  setState(() => _isMuted = !_isMuted);
                                },
                              ),
                              _buildControlButton(
                                icon: _isVideoOff
                                    ? Icons.videocam_off
                                    : Icons.videocam,
                                label: _isVideoOff ? 'Camera On' : 'Camera Off',
                                onPressed: () async {
                                  await _engine
                                      ?.muteLocalVideoStream(!_isVideoOff);
                                  setState(() => _isVideoOff = !_isVideoOff);
                                },
                              ),
                              _buildControlButton(
                                icon: Icons.close,
                                label: 'End',
                                color: Colors.red,
                                onPressed: () async {
                                  await ref
                                      .read(speedDatingSessionProvider.notifier)
                                      .cancelSession();
                                  if (mounted) {
                                    Navigator.pushReplacementNamed(
                                        context, '/speed-dating');
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Decision buttons
                          if (!session.hasEnded)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: NeonButton(
                                    label: 'âŒ PASS',
                                    onPressed: () {},
                                    glowColor: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: NeonButton(
                                    label: 'ðŸ’– LIKE',
                                    onPressed: () {},
                                    glowColor: DesignColors.gold,
                                  ),
                                ),
                              ],
                            ),

                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              session.currentUserDecision == 'like'
                                  ? 'ðŸ’– You liked this person'
                                  : 'âŒ You passed',
                              style: TextStyle(
                                color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          iconSize: 32,
          color: color ?? DesignColors.white,
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            color: color ?? DesignColors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
