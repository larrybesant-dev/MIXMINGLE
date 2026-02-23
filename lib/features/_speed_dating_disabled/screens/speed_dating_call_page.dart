import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/design_system/design_constants.dart';
// TEMP DISABLED: import '../../../services/speed_dating_service.dart';
// TEMP DISABLED: import 'speed_dating_decision_page.dart';

/// Speed Dating Call Page
/// The actual 3-5 minute video call between matched users
class SpeedDatingCallPage extends ConsumerStatefulWidget {
  final String sessionId;
  final String matchedUserId;

  const SpeedDatingCallPage({
    required this.sessionId,
    required this.matchedUserId,
    super.key,
  });

  @override
  ConsumerState<SpeedDatingCallPage> createState() => _SpeedDatingCallPageState();
}

class _SpeedDatingCallPageState extends ConsumerState<SpeedDatingCallPage> {
  static const int callDurationSeconds = 300; // 5 minutes (matches server)

  Timer? _countdownTimer;
  int _remainingSeconds = callDurationSeconds;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isConnecting = true;
  String? _matchedUserName;
  String? _matchedUserPhoto;

  // Video placeholders (would integrate with Agora in production)
  bool _remoteVideoReady = false;

  // Server status listener
  StreamSubscription? _sessionStatusSubscription;
  bool _sessionExpiredByServer = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _listenToServerStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sessionStatusSubscription?.cancel();
    _endAgoraCall();
    super.dispose();
  }

  /// CRITICAL: Listen for server-forced disconnects
  /// Server will mark session as 'expired' after 5 minutes
  void _listenToServerStatus() {
    final service = SpeedDatingService();

    _sessionStatusSubscription = service
        .listenToSessionStatus(widget.sessionId)
        .listen((statusData) {
      if (statusData == null) return;
      final status = statusData['status'] as String;
      final forceDisconnect = statusData['forceDisconnect'] as bool;

      debugPrint('ðŸ”” [SpeedDating CallPage] Server status: $status (force: $forceDisconnect)');

      if (status == 'expired' || status == 'abandoned' || forceDisconnect) {
        // SERVER FORCED DISCONNECT
        if (!_sessionExpiredByServer && mounted) {
          _sessionExpiredByServer = true;
          _countdownTimer?.cancel();

          debugPrint('â° [SpeedDating] SESSION EXPIRED BY SERVER - Forcing disconnect');

          // Show alert and force disconnect
          _handleServerForcedDisconnect(status);
        }
      }
    });
  }

  /// Handle server-forced disconnect
  void _handleServerForcedDisconnect(String status) {
    // Immediately end Agora call
    _endAgoraCall();

    if (!mounted) return;

    // Show dialog explaining what happened
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Ended'),
        content: Text(
          status == 'expired'
              ? 'Your speed dating session has ended (5 minute limit).'
              : 'The session was ended unexpectedly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _onCallEnded(); // Navigate to decision page
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCall() async {
    // Load matched user info
    await _loadMatchedUserInfo();

    // Initialize Agora call
    await _startAgoraCall();

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });

      // Start countdown timer
      _startCountdown();

      // Simulate remote user joining after 1-2 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _remoteVideoReady = true);
        }
      });
    }
  }

  Future<void> _loadMatchedUserInfo() async {
    final service = SpeedDatingService();
    final userInfo = await service.getUserInfo(widget.matchedUserId);
    if (mounted && userInfo != null) {
      setState(() {
        _matchedUserName = userInfo['displayName'] ?? 'Anonymous';
        _matchedUserPhoto = userInfo['photoUrl'];
      });
    }
  }

  Future<void> _startAgoraCall() async {
    try {
      // In production, this would initialize Agora with the session channel
      // For now, simulate connection
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Error starting Agora call: $e');
    }
  }

  Future<void> _endAgoraCall() async {
    try {
      // Clean up Agora resources
      // In production: integrate with room's Agora instance
      debugPrint('ðŸ“¹ [SpeedDating] Ending Agora call...');
    } catch (e) {
      debugPrint('Error ending Agora call: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() => _remainingSeconds--);
        }
      } else {
        timer.cancel();

        // Local timer expired - but let server be authoritative
        // Server will send forced disconnect if not already
        debugPrint('â° [SpeedDating] Local timer expired, waiting for server confirmation...');

        // Failsafe: if server doesn't respond in 5 seconds, force end
        Future.delayed(const Duration(seconds: 5), () {
          if (!_sessionExpiredByServer && mounted) {
            debugPrint('âš ï¸ [SpeedDating] Server timeout - forcing local end');
            _onCallEnded();
          }
        });
      }
    });
  }

  void _onCallEnded() {
    if (!mounted) return;

    // Navigate to decision page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SpeedDatingDecisionPage(
          sessionId: widget.sessionId,
          matchedUserId: widget.matchedUserId,
          matchedUserName: _matchedUserName ?? 'Your Match',
          matchedUserPhoto: _matchedUserPhoto,
        ),
      ),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    // In production: AgoraService.instance.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoOff = !_isVideoOff);
    // In production: AgoraService.instance.muteLocalVideoStream(_isVideoOff);
  }

  Future<void> _endCallEarly() async {
    _countdownTimer?.cancel();

    // Notify server that user is leaving (stub - feature disabled)
    final service = SpeedDatingService();
    await service.leaveSession(widget.sessionId, '');

    _onCallEnded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          _buildRemoteVideo(),

          // Local video (picture-in-picture)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _buildLocalVideo(),
          ),

          // Top bar with timer and name
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // Connecting overlay
          if (_isConnecting)
            _buildConnectingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (!_remoteVideoReady) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: DesignColors.accent.withValues(alpha: 0.3),
                backgroundImage: _matchedUserPhoto != null
                    ? NetworkImage(_matchedUserPhoto!)
                    : null,
                child: _matchedUserPhoto == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _matchedUserName ?? 'Connecting...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for video...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // In production, this would be the Agora remote video view
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: DesignColors.accent.withValues(alpha: 0.3),
              backgroundImage: _matchedUserPhoto != null
                  ? NetworkImage(_matchedUserPhoto!)
                  : null,
              child: _matchedUserPhoto == null
                  ? const Icon(Icons.person, size: 80, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _matchedUserName ?? 'Your Match',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Video Connected',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: _isVideoOff ? Colors.grey[800] : Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.accent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _isVideoOff
            ? const Icon(Icons.videocam_off, color: Colors.white54, size: 40)
            : const Icon(Icons.person, color: Colors.white54, size: 40),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 140, // Space for PiP video
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _remainingSeconds <= 30
                  ? Colors.red.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Match name
          if (_matchedUserName != null)
            Expanded(
              child: Text(
                _matchedUserName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onTap: _toggleMute,
            isActive: !_isMuted,
          ),

          // End call button
          _buildEndCallButton(),

          // Video toggle button
          _buildControlButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            label: _isVideoOff ? 'Video On' : 'Video Off',
            onTap: _toggleVideo,
            isActive: !_isVideoOff,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCallEarly,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'End Call',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: DesignColors.accent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up your video call',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
