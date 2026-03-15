// lib/features/speed_dating/screens/speed_dating_matches_inbox.dart
//
// Speed Dating Match Inbox — neon-styled list of all mutual matches.
// Shows: matched user avatar, name, when you matched, + quick "Message" action.
//
// Firestore:
//   speedDatingResults/{docId}
//     userId         : String   (current user)
//     matchedUserId  : String
//     isMutual       : bool
//     timestamp      : Timestamp
//     matchedUserName: String?  (denormalized for fast reads)
//     matchedUserAvatar: String?
//     roundId        : String
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/models/speed_dating_result.dart';

// ── Neon palette
const _kPink   = Color(0xFFFF4D8B);
const _kPurple = Color(0xFF8B5CF6);

class SpeedDatingMatchesInbox extends StatefulWidget {
  const SpeedDatingMatchesInbox({super.key});

  @override
  State<SpeedDatingMatchesInbox> createState() =>
      _SpeedDatingMatchesInboxState();
}

class _SpeedDatingMatchesInboxState extends State<SpeedDatingMatchesInbox>
    with SingleTickerProviderStateMixin {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Entry animation
  late final AnimationController _anim;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Stream<List<SpeedDatingResult>> get _mutualMatchesStream => _db
      .collection('speedDatingResults')
      .where('userId', isEqualTo: _uid)
      .where('isMutual', isEqualTo: true)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => SpeedDatingResult.fromMap({'id': d.id, ...d.data()}))
          .toList());

  void _openChat(SpeedDatingResult match) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'otherUserId': match.matchedUserId,
        'otherUserName': match.matchedUserName ?? 'Match',
      },
    );
  }

  void _viewProfile(SpeedDatingResult match) {
    Navigator.pushNamed(
      context,
      '/profile/user',
      arguments: {'userId': match.matchedUserId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: StreamBuilder<List<SpeedDatingResult>>(
          stream: _mutualMatchesStream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _kPink));
            }
            if (snap.hasError) {
              return const Center(
                child: Text('Error loading matches',
                    style: TextStyle(color: DesignColors.white)),
              );
            }
            final matches = snap.data ?? [];
            if (matches.isEmpty) return _buildEmptyState();
            return _buildMatchList(matches);
          },
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: DesignColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _kPink.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: _kPink.withValues(alpha: 0.3), blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.favorite, color: _kPink, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'YOUR MATCHES',
            style: TextStyle(
              color: DesignColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: const Icon(Icons.timer_outlined, color: DesignColors.textGray),
            tooltip: 'Join Speed Dating',
            onPressed: () => Navigator.pushNamed(context, '/speed-dating'),
          ),
        ),
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated heart
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPink.withValues(alpha: 0.12),
                  border: Border.all(color: _kPink.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(color: _kPink.withValues(alpha: 0.3), blurRadius: 20)
                  ],
                ),
                child: const Icon(Icons.favorite_border, color: _kPink, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No matches yet',
              style: TextStyle(
                  color: DesignColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Join a Speed Dating session and connect\nwith people who vibe with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: DesignColors.textGray, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/speed-dating'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPink, _kPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: _kPink.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Join Speed Dating',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Match list ────────────────────────────────────────────────────────────
  Widget _buildMatchList(List<SpeedDatingResult> matches) {
    return Column(
      children: [
        // Banner count
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _kPink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPink.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: _kPink.withValues(alpha: 0.1), blurRadius: 10)
            ],
          ),
          child: Row(children: [
            const Icon(Icons.favorite, color: _kPink, size: 16),
            const SizedBox(width: 8),
            Text(
              '${matches.length} mutual match${matches.length == 1 ? '' : 'es'} — say hello! 👋',
              style: const TextStyle(
                  color: _kPink, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // List
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: matches.length,
            itemBuilder: (ctx, i) {
              final interval = (i * 0.1).clamp(0.0, 0.6);
              final fade = CurvedAnimation(
                parent: _anim,
                curve:
                    Interval(interval, (interval + 0.4).clamp(0.0, 1.0),
                        curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(fade),
                  child: _MatchCard(
                    match: matches[i],
                    onMessage: () => _openChat(matches[i]),
                    onProfile: () => _viewProfile(matches[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MATCH CARD
// ════════════════════════════════════════════════════════════════════════════
class _MatchCard extends StatelessWidget {
  final SpeedDatingResult match;
  final VoidCallback onMessage;
  final VoidCallback onProfile;

  const _MatchCard({
    required this.match,
    required this.onMessage,
    required this.onProfile,
  });

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final name = match.matchedUserName ?? 'Match';
    final avatar = match.matchedUserAvatar;

    return GestureDetector(
      onTap: onProfile,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kPink.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: _kPink.withValues(alpha: 0.08), blurRadius: 12)
          ],
        ),
        child: Row(
          children: [
            // ── Avatar with heart badge ──────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_kPink, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _kPink.withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 1)
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: CircleAvatar(
                      backgroundColor: DesignColors.surfaceDefault,
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: _kPink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800))
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kPink,
                      border: Border.all(
                          color: DesignColors.background, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: _kPink.withValues(alpha: 0.6),
                            blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // ── Name + time ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: DesignColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        size: 11, color: _kPink),
                    const SizedBox(width: 3),
                    Text(
                      'Matched ${_timeAgo(match.timestamp)}',
                      style: const TextStyle(
                          color: _kPink, fontSize: 11),
                    ),
                  ]),
                ],
              ),
            ),
            // ── Message button ───────────────────────────────────
            GestureDetector(
              onTap: onMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPink, _kPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _kPink.withValues(alpha: 0.35),
                        blurRadius: 10)
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text('Message',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fields are now direct model properties (matchedUserName, matchedUserAvatar)
