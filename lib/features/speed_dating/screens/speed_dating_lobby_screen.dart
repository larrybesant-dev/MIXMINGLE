// lib/features/speed_dating/screens/speed_dating_lobby_screen.dart
//
// Tinder-style Speed Dating — Lobby / Queue Screen
//
// Flow:
//   1. User taps "Join Queue" → writes to Firestore `speedDatingQueue`
//   2. Cloud Function (or a batch listener) pairs two users → creates
//      a `speedDatingSessions` doc with both UIDs + an Agora channel name
//   3. This screen listens for that session doc → navigates automatically
//      to SpeedDatingSessionScreen
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/icebreaker_prompts.dart';
import 'speed_dating_session_screen.dart';

class SpeedDatingLobbyScreen extends StatefulWidget {
  const SpeedDatingLobbyScreen({super.key});

  @override
  State<SpeedDatingLobbyScreen> createState() => _SpeedDatingLobbyScreenState();
}

class _SpeedDatingLobbyScreenState extends State<SpeedDatingLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _inQueue = false;
  bool _loading = false;
  int _queueCount = 0;
  int _dotCount = 0;

  String? _queueDocId;
  StreamSubscription<QuerySnapshot>? _sessionSub;
  StreamSubscription<QuerySnapshot>? _queueCountSub;
  Timer? _dotTimer;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.9, end: 1.1).animate(_pulseCtrl);

    _queueCountSub = _db
        .collection('speedDatingQueue')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _queueCount = snap.size);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotTimer?.cancel();
    _sessionSub?.cancel();
    _queueCountSub?.cancel();
    super.dispose();
  }

  // ── Join queue ──────────────────────────────────────────
  Future<void> _joinQueue() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);

    try {
      // Write queue entry
      final ref = await _db.collection('speedDatingQueue').add({
        'userId': uid,
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      _queueDocId = ref.id;

      setState(() {
        _inQueue = true;
        _loading = false;
      });

      _startDotAnimation();
      _listenForMatch(uid);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Leave queue ─────────────────────────────────────────
  Future<void> _leaveQueue() async {
    if (_queueDocId != null) {
      await _db
          .collection('speedDatingQueue')
          .doc(_queueDocId!)
          .delete()
          .catchError((_) {});
      _queueDocId = null;
    }
    _sessionSub?.cancel();
    _dotTimer?.cancel();
    setState(() => _inQueue = false);
  }

  // ── Listen for a matched session ────────────────────────
  void _listenForMatch(String uid) {
    _sessionSub?.cancel();
    _sessionSub = _db
        .collection('speedDatingSessions')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snap) async {
      if (snap.docs.isEmpty) return;
      final session = snap.docs.first;

      // Clean up queue entry before navigating
      if (_queueDocId != null) {
        await _db
            .collection('speedDatingQueue')
            .doc(_queueDocId!)
            .delete()
            .catchError((_) {});
        _queueDocId = null;
      }

      _sessionSub?.cancel();
      _dotTimer?.cancel();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SpeedDatingSessionScreen(
            sessionId: session.id,
            sessionData: session.data(),
          ),
        ),
      );
    });
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
    });
  }

  String get _waitingText =>
      'Finding your match${'.' * _dotCount}${' ' * (3 - _dotCount)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: DesignColors.white),
        title: const Text(
          '⚡ SPEED DATING',
          style: TextStyle(
            color: DesignColors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeroSection(),
            const SizedBox(height: 40),
            _buildStatsRow(),
            const SizedBox(height: 40),
            _buildIcebreakerPreview(),
            const SizedBox(height: 48),
            _buildActionButton(),
            const SizedBox(height: 24),
            _buildRulesCard(),
          ],
        ),
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _inQueue ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            DesignColors.gold.withValues(alpha: _inQueue ? 0.35 : 0.16),
            Colors.transparent,
          ]),
          border: Border.all(
            color: DesignColors.gold
                .withValues(alpha: _inQueue ? 0.9 : 0.5),
            width: 3,
          ),
        ),
        child: Icon(
          _inQueue ? Icons.access_time : Icons.bolt,
          size: 64,
          color: DesignColors.gold,
        ),
      ),
    );
  }

  // ── Stats ───────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat(
          icon: Icons.people_outline,
          value: '$_queueCount',
          label: 'In Queue',
          color: DesignColors.accent,
        ),
        _stat(
          icon: Icons.timer_outlined,
          value: '60s',
          label: 'Per Round',
          color: DesignColors.gold,
        ),
        _stat(
          icon: Icons.favorite_border,
          value: 'Match',
          label: 'Both Like',
          color: const Color(0xFFFF4D8B),
        ),
      ],
    );
  }

  Widget _stat(
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(
                color: DesignColors.textGray, fontSize: 11)),
      ],
    );
  }

  // ── Icebreaker ──────────────────────────────────────────
  Widget _buildIcebreakerPreview() {
    final prompt = icebreakerPrompts.isNotEmpty
        ? icebreakerPrompts[
            DateTime.now().millisecondsSinceEpoch % icebreakerPrompts.length]
        : "What's your go-to song right now?";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: DesignColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: DesignColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'Today\'s Icebreaker',
                style: TextStyle(
                    color: DesignColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$prompt"',
            style: const TextStyle(
              color: DesignColors.white,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Button ────────────────────────────────────────
  Widget _buildActionButton() {
    if (_loading) {
      return const CircularProgressIndicator(color: DesignColors.gold);
    }

    if (_inQueue) {
      return Column(
        children: [
          Text(
            _waitingText,
            style: const TextStyle(
              color: DesignColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _leaveQueue,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Leave Queue'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignColors.textGray,
              side: const BorderSide(color: DesignColors.textGray),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _joinQueue,
      child: Container(
        width: double.infinity,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [DesignColors.gold, Color(0xFFFF6B35)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: DesignColors.gold.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'JOIN QUEUE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rules ────────────────────────────────────────────────
  Widget _buildRulesCard() {
    const rules = [
      ('⚡', '60-second 1-on-1 video rounds'),
      ('💚', 'Swipe right to Like · 💔 left to Skip'),
      ('🎯', 'Both like = Instant Match!'),
      ('🔄', 'Auto-rotates to next person'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              color: DesignColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...rules.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(r.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: const TextStyle(
                            color: DesignColors.textLightGray,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
