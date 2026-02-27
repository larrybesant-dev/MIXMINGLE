// lib/features/speed_dating/screens/speed_dating_session_screen.dart
//
// Tinder-style Speed Dating — Live Session Screen
//
// Shows a 60-second 1-on-1 video round between two matched users.
// Agora RTC channel name = sessionId.
// Decisions written to Firestore; if both "like" → match popup → chat.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/constants.dart';
import '../../../core/platform/web_platform_view_helper.dart';
import '../../../services/agora/agora_service.dart';
import '../../../services/infra/token_service.dart';
import '../../../shared/models/icebreaker_prompts.dart';
import '../../../services/social/friend_service.dart';
import '../../../services/notifications/app_notification_service.dart';
import '../../match_inbox/services/match_inbox_service.dart';
import '../../match_inbox/models/match_inbox_item.dart';
import '../../../core/analytics/analytics_service.dart';

enum _Decision { none, liked, skipped }

class SpeedDatingSessionScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const SpeedDatingSessionScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  State<SpeedDatingSessionScreen> createState() =>
      _SpeedDatingSessionScreenState();
}

class _SpeedDatingSessionScreenState extends State<SpeedDatingSessionScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Session state ────────────────────────────────────────
  late int _secondsLeft;
  Timer? _countdownTimer;
  StreamSubscription<DocumentSnapshot>? _sessionSub;

  _Decision _myDecision = _Decision.none;
  bool _showMatchOverlay = false;
  bool _sessionEnded = false;

  late final String _myUid;
  late final String _partnerUid;
  late final String _icebreaker;

  // ── Agora ─────────────────────────────────────────────────
  final _agora = AgoraService();
  bool _micMuted = false;
  bool _videoMuted = false;
  bool _agoraJoined = false;

  // ── Animations ───────────────────────────────────────────
  late final AnimationController _countdownGlowCtrl;
  late final AnimationController _decisionCtrl;
  late final Animation<double> _decisionScale;

  // ── Session config ───────────────────────────────────────
  static const _roundSeconds = 60;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _roundSeconds;
    _myUid = _auth.currentUser?.uid ?? '';

    final participants =
        List<String>.from(widget.sessionData['participants'] ?? []);
    _partnerUid = participants.firstWhere(
      (uid) => uid != _myUid,
      orElse: () => '',
    );

    const prompts = icebreakerPrompts;
    _icebreaker = prompts.isNotEmpty
        ? prompts[widget.sessionId.hashCode.abs() % prompts.length]
        : "What's something that made you smile today?";

    _countdownGlowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);

    _decisionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _decisionScale =
        Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _decisionCtrl,
      curve: Curves.elasticOut,
    ));

    _startCountdown();
    _listenToSession();
    _initAgora();
    AnalyticsService.instance.logScreenView(screenName: 'screen_speed_dating_session');
    AnalyticsService.instance.logSpeedDatingRoundStarted(sessionId: widget.sessionId);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sessionSub?.cancel();
    _countdownGlowCtrl.dispose();
    _decisionCtrl.dispose();
    // Leave Agora channel on screen exit
    _agora.leaveChannel().catchError((_) {});
    super.dispose();
  }

  // ── Agora lifecycle ──────────────────────────────────────
  Future<void> _initAgora() async {
    if (!kIsWeb) return; // web-only bridge
    try {
      final appId = AppConstants.agoraAppId;
      if (appId.isEmpty) {
        debugPrint('[SpeedDating] AGORA_APP_ID not configured — skipping Agora init');
        return;
      }

      // ── 1. Fetch token from Cloud Function (production mode) ──────────
      String agoraToken;
      String agoraNumericUid;
      try {
        final tokenData = await TokenService().generateAgoraTokenData(
          channelName: widget.sessionId,
          userId: _myUid,
        );
        agoraToken = tokenData.token;
        agoraNumericUid = tokenData.uid.toString();
        debugPrint('[SpeedDating] Token obtained, numeric uid=$agoraNumericUid');
      } catch (e) {
        debugPrint('[SpeedDating] Token generation failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not connect video: ${_shortError(e)}'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _initAgora,
              ),
            ),
          );
        }
        return;
      }

      // ── 2. Register platform view factories for in-widget video ───────
      registerVideoViewFactory(
        'agora-local-speed-dating-$_myUid',
        'agora-local-speed-dating-$_myUid',
      );
      registerVideoViewFactory(
        'agora-remote-speed-dating-video',
        'agora-remote-speed-dating-video',
      );

      // ── 3. Init Agora SDK ─────────────────────────────────────────────
      final ready = await _agora.init(appId);
      if (!ready) {
        debugPrint('[SpeedDating] Agora bridge not ready');
        return;
      }

      // ── 4. Join channel with valid token and Agora numeric uid ────────
      final joined = await _agora.joinChannel(
        token: agoraToken,
        channelId: widget.sessionId,
        uid: agoraNumericUid,
      );
      if (joined && mounted) {
        setState(() => _agoraJoined = true);

        // ── 5. Start local mic and camera ─────────────────────────────
        await _agora.startMic();
        await _agora.startCamera('agora-local-speed-dating-$_myUid');

        // ── 6. Subscribe remote video to the HtmlElementView container ─
        await _agora.subscribeRemoteVideoTo('agora-remote-speed-dating-video');

        debugPrint('[SpeedDating] Joined channel: ${widget.sessionId}');
      }
    } catch (e) {
      debugPrint('[SpeedDating] Agora init error: $e');
    }
  }

  /// Returns a short, user-friendly string from any error.
  String _shortError(Object e) {
    final full = e.toString();
    // Trim Firebase/cloud function prefix noise
    if (full.contains(']')) {
      final afterBracket = full.split(']').last.trim();
      if (afterBracket.isNotEmpty) return afterBracket;
    }
    return full.length > 80 ? '${full.substring(0, 80)}…' : full;
  }

  Future<void> _toggleMic() async {
    final next = !_micMuted;
    await _agora.setMicrophoneMuted(next).catchError((_) {});
    if (mounted) setState(() => _micMuted = next);
  }

  Future<void> _toggleVideo() async {
    final next = !_videoMuted;
    await _agora.setVideoCameraMuted(next).catchError((_) {});
    if (mounted) setState(() => _videoMuted = next);
  }

  // ── Countdown ────────────────────────────────────────────
  void _startCountdown() {
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _countdownTimer?.cancel();
        if (_myDecision == _Decision.none) {
          await _submitDecision(liked: false);
        }
        if (!_sessionEnded) _endSession();
      }
    });
  }

  // ── Decision ─────────────────────────────────────────────
  Future<void> _submitDecision({required bool liked}) async {
    if (_myDecision != _Decision.none) return;
    setState(() =>
        _myDecision = liked ? _Decision.liked : _Decision.skipped);
    _decisionCtrl.forward(from: 0);

    await _db
        .collection('speedDatingSessions')
        .doc(widget.sessionId)
        .set(
          {'decisions': {_myUid: liked}},
          SetOptions(merge: true),
        )
        .catchError((_) {});
  }

  // ── Listen for mutual match ───────────────────────────────
  void _listenToSession() {
    _sessionSub = _db
        .collection('speedDatingSessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data() ?? {};
      final decisions =
          Map<String, dynamic>.from(data['decisions'] ?? {});

      // Check if both participants have liked
      final participants =
          List<String>.from(data['participants'] ?? []);
      final isMutualMatch = participants.every(
          (uid) => decisions[uid] == true);

      if (isMutualMatch && !_showMatchOverlay) {
        _countdownTimer?.cancel();
        setState(() => _showMatchOverlay = true);
        // Auto-friend both users on mutual match
        _handleMutualMatch();
      }
    });
  }

  // ── Mutual match handler ─────────────────────────────────
  Future<void> _handleMutualMatch() async {
    try {
      // Auto-friend both participants
      await FriendService.instance.autoFriend(_myUid, _partnerUid);

      // Fetch partner display name for notification text
      final partnerDoc =
          await _db.collection('users').doc(_partnerUid).get();
      final partnerName =
          (partnerDoc.data()?['displayName'] as String?) ?? 'Someone';
      final partnerAvatar =
          partnerDoc.data()?['photoURL'] as String?;

      final myDoc = await _db.collection('users').doc(_myUid).get();
      final myName =
          (myDoc.data()?['displayName'] as String?) ?? 'Someone';
      final myAvatar = myDoc.data()?['photoURL'] as String?;

      // Notify both users
      await AppNotificationService.instance.notifySpeedDatingMatch(
        receiverId: _partnerUid,
        matchName: myName,
        matchAvatarUrl: myAvatar,
      );
      await AppNotificationService.instance.notifySpeedDatingMatch(
        receiverId: _myUid,
        matchName: partnerName,
        matchAvatarUrl: partnerAvatar,
      );

      // ── Create Match Inbox entries for both users ─────────────────────────
      await MatchInboxService.instance.createMatch(
        _myUid,
        _partnerUid,
        source: MatchSource.speedDating,
        metadata: {'sessionId': widget.sessionId},
        userAName: myName,
        userAAvatarUrl: myAvatar,
        userBName: partnerName,
        userBAvatarUrl: partnerAvatar,
      );
      AnalyticsService.instance.logSpeedDatingMatchCreated(
        sessionId: widget.sessionId,
        partnerId: _partnerUid,
      );
      AnalyticsService.instance.logFirstMatch(matchId: widget.sessionId);
      debugPrint('[SpeedDating] ✅ Match inbox entries created for mutual match');
    } catch (e) {
      debugPrint('[SpeedDating] _handleMutualMatch error: $e');
    }
  }

  void _endSession() {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _countdownTimer?.cancel();

    // Leave Agora channel when round ends
    _agora.leaveChannel().catchError((_) {});

    // Mark session complete
    _db
        .collection('speedDatingSessions')
        .doc(widget.sessionId)
        .set({'status': 'completed'}, SetOptions(merge: true))
        .catchError((_) {});

    if (mounted && !_showMatchOverlay) {
      _showNoMatchDialog();
    }
  }

  void _showNoMatchDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: DesignColors.surfaceLight,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Round Over',
            style: TextStyle(color: DesignColors.white)),
        content: Text(
          _myDecision == _Decision.liked
              ? 'You liked them, but they passed. Keep going!'
              : 'Round ended. Ready for the next one?',
          style: const TextStyle(color: DesignColors.textLightGray),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to lobby
            },
            child: const Text('Back to Lobby',
                style: TextStyle(color: DesignColors.accent)),
          ),
        ],
      ),
    );
  }

  void _goToChat() {
    // Derive or create a chat ID from both UIDs (sorted for consistency)
    final ids = [_myUid, _partnerUid]..sort();
    final chatId = ids.join('_');
    Navigator.pop(context); // close match overlay / go back
    Navigator.pushNamed(context, '/chat', arguments: {
      'chatId': chatId,
      'peerId': _partnerUid,
    });
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video layer (full screen)
          _buildVideoLayer(),
          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Top bar: countdown + icebreaker
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildTopBar())),
          // Bottom bar: like / skip buttons
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildBottomBar())),
          // Local video PiP (bottom-right)
          Positioned(
            right: 16,
            bottom: 120,
            child: _buildLocalPip(),
          ),
          // Match overlay
          if (_showMatchOverlay) _buildMatchOverlay(),
        ],
      ),
    );
  }

  // ── Video Layer ───────────────────────────────────────────
  Widget _buildVideoLayer() {
    // On web: use HtmlElementView so the Agora remote video track is rendered
    // directly inside the Flutter widget tree. The platform view factory was
    // registered in _initAgora() via registerVideoViewFactory().
    // The agora_bridge.js subscribeRemoteVideoTo() call routes the first remote
    // user's video track into this element as soon as they publish.
    if (kIsWeb && _agoraJoined) {
      return const SizedBox.expand(
        child: HtmlElementView(viewType: 'agora-remote-speed-dating-video'),
      );
    }

    // Fallback placeholder (pre-join or non-web)
    return Container(
      color: const Color(0xFF0A0A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.sizeOf(context).height * 0.55,
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _agoraJoined ? Icons.videocam : Icons.videocam_off_outlined,
                      size: 48,
                      color: _agoraJoined ? DesignColors.accent : DesignColors.textGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _agoraJoined ? 'Waiting for partner...' : 'Connecting video...',
                      style: TextStyle(
                        color: _agoraJoined ? DesignColors.textLightGray : DesignColors.textGray,
                      ),
                    ),
                    if (_agoraJoined) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Channel: ${widget.sessionId}',
                        style: const TextStyle(color: DesignColors.textGray, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar() {
    final urgency = _secondsLeft <= 10;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Countdown circle
          AnimatedBuilder(
            animation: _countdownGlowCtrl,
            builder: (_, child) => Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: urgency
                      ? Color.lerp(Colors.red, DesignColors.gold,
                              _countdownGlowCtrl.value)!
                      : DesignColors.gold,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (urgency ? Colors.red : DesignColors.gold)
                        .withValues(alpha: 0.4 * _countdownGlowCtrl.value),
                    blurRadius: 16,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  '$_secondsLeft',
                  style: TextStyle(
                    color: urgency ? Colors.red : DesignColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icebreaker chip
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: DesignColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: DesignColors.gold, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _icebreaker,
                      style: const TextStyle(
                        color: DesignColors.white,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip button
          _decisionButton(
            icon: Icons.close,
            color: Colors.redAccent,
            label: 'Skip',
            active: _myDecision == _Decision.skipped,
            onTap: _myDecision == _Decision.none
                ? () => _submitDecision(liked: false)
                : null,
          ),
          // Like button
          _decisionButton(
            icon: Icons.favorite,
            color: const Color(0xFF00E87D),
            label: 'Like',
            active: _myDecision == _Decision.liked,
            onTap: _myDecision == _Decision.none
                ? () => _submitDecision(liked: true)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _decisionButton({
    required IconData icon,
    required Color color,
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    return ScaleTransition(
      scale: active ? _decisionScale : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? color.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.5),
            border: Border.all(
              color: active ? color : color.withValues(alpha: 0.4),
              width: active ? 3 : 2,
            ),
            boxShadow: active
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Local PiP ─────────────────────────────────────────────
  Widget _buildLocalPip() {
    return Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: DesignColors.accent.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Local camera feed (web) or fallback icon
            if (kIsWeb && _agoraJoined && !_videoMuted)
              HtmlElementView(
                viewType: 'agora-local-speed-dating-$_myUid',
              )
            else
              Center(
                child: Icon(
                  _videoMuted ? Icons.videocam_off : Icons.person,
                  color: _videoMuted ? Colors.redAccent : DesignColors.textGray,
                  size: 28,
                ),
              ),
            // Mic / video toggle overlay (bottom)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleMic,
                    child: Icon(
                      _micMuted ? Icons.mic_off : Icons.mic,
                      color: _micMuted ? Colors.redAccent : Colors.white54,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _toggleVideo,
                    child: Icon(
                      _videoMuted ? Icons.videocam_off : Icons.videocam,
                      color: _videoMuted ? Colors.redAccent : Colors.white54,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Match Overlay ─────────────────────────────────────────
  Widget _buildMatchOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated heart
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: const Icon(Icons.favorite,
                  color: Color(0xFFFF4D8B), size: 90),
            ),
            const SizedBox(height: 24),
            const Text(
              "IT'S A MATCH! 🎉",
              style: TextStyle(
                color: DesignColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: DesignColors.primaryGlow,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You both liked each other!',
              style: TextStyle(
                color: DesignColors.textLightGray,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            // Send message button
            GestureDetector(
              onTap: _goToChat,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D8B), Color(0xFFFF6B35)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFF4D8B).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('SEND MESSAGE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Keep speed dating
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Keep Speed Dating',
                style: TextStyle(
                    color: DesignColors.textGray, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
