import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/speed_dating_models.dart';
import '../services/speed_dating_service.dart';

class SpeedDatingScreen extends StatefulWidget {
  const SpeedDatingScreen({super.key});

  @override
  State<SpeedDatingScreen> createState() => _SpeedDatingScreenState();
}

class _SpeedDatingScreenState extends State<SpeedDatingScreen>
    with SingleTickerProviderStateMixin {
  static const int _sessionLengthSeconds = 90;

  final SpeedDatingService _service = SpeedDatingService();
  final ValueNotifier<int> _secondsLeftNotifier = ValueNotifier<int>(
    _sessionLengthSeconds,
  );
  int _candidateIndex = 0;
  Timer? _timer;
  bool _isSubmitting = false;

  // Session stats
  int _likesCount = 0;
  int _passesCount = 0;

  // Swipe drag state
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secondsLeftNotifier.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeftNotifier.value = _sessionLengthSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeftNotifier.value <= 1) {
        timer.cancel();
        _nextCandidate();
        return;
      }
      _secondsLeftNotifier.value = _secondsLeftNotifier.value - 1;
    });
  }

  void _nextCandidate() {
    setState(() {
      _candidateIndex += 1;
      _dragOffset = 0;
      _isDragging = false;
    });
    _startTimer();
  }

  Future<void> _handleDecision({
    required SpeedDateCandidate candidate,
    required bool liked,
    required String currentUserId,
  }) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      if (liked) { _likesCount++; } else { _passesCount++; }
    });

    try {
      final result = await _service.submitDecision(
        fromUserId: currentUserId,
        toUserId: candidate.id,
        liked: liked,
        sessionSeconds: _sessionLengthSeconds - _secondsLeftNotifier.value,
      );

      if (!mounted) return;

      if (result.isMatch && result.matchId != null) {
        await _showMatchDialog(candidate: candidate, currentUserId: currentUserId, matchId: result.matchId!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save decision: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _nextCandidate();
      }
    }
  }

  Future<void> _showMatchDialog({
    required SpeedDateCandidate candidate,
    required String currentUserId,
    required String matchId,
  }) async {
    final pageContext = context;
    await showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('🎉 It\'s a Match!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'You and ${candidate.username} liked each other.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Keep Browsing'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final roomId = await _service.startLiveDateRoom(
                  hostUserId: currentUserId,
                  targetUserId: candidate.id,
                  matchId: matchId,
                );
                if (!mounted) return;
                if (!pageContext.mounted) return;
                pageContext.go('/room/$roomId');
              },
              child: const Text('Start Live Date 🚀'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCandidateCard(SpeedDateCandidate candidate, ThemeData theme, String currentUserId) {
    final hasAvatar = candidate.avatarUrl != null && candidate.avatarUrl!.trim().isNotEmpty;
    final displayName = candidate.username.trim().isEmpty ? 'MixVy user' : candidate.username.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: hasAvatar
                ? ClipOval(
                    child: Image.network(
                      candidate.avatarUrl!.trim(),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 42),
                    ),
                  )
                : const Icon(Icons.person, size: 42),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Live now • Speed date ready',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (candidate.bio ?? '').trim().isEmpty ? 'Ready for a quick live date.' : candidate.bio!.trim(),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (candidate.interests.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: candidate.interests.take(6).map((interest) {
                return Chip(
                  label: Text(interest),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.14),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/profile/${candidate.id}'),
                icon: const Icon(Icons.person_outline),
                label: const Text('View profile'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleDecision(candidate: candidate, liked: false, currentUserId: currentUserId),
                  icon: const Icon(Icons.close),
                  label: const Text('Pass'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.pinkAccent.shade200,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleDecision(candidate: candidate, liked: true, currentUserId: currentUserId),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Like'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting ? null : _nextCandidate,
            child: const Text('Skip to next person'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Speed Dating')),
        body: const Center(child: Text('Please sign in to use speed dating.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live Speed Dating')),
      body: StreamBuilder<List<SpeedDateCandidate>>(
        stream: _service.candidatesStream(currentUserId: user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load queue: ${snapshot.error}'));
          }

          final candidates = snapshot.data ?? const [];
          if (candidates.isEmpty) {
            // Session done — show summary
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎊', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text('Session complete!',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatBadge(label: 'Liked', value: _likesCount, color: Colors.pinkAccent),
                        const SizedBox(width: 16),
                        _StatBadge(label: 'Passed', value: _passesCount, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        _candidateIndex = 0;
                        _likesCount = 0;
                        _passesCount = 0;
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check back later'),
                    ),
                  ],
                ),
              ),
            );
          }

          final activeCandidate = candidates[_candidateIndex % candidates.length];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header with circular countdown timer
              Row(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _secondsLeftNotifier,
                    builder: (context, secondsLeft, _) {
                      final progress = secondsLeft / _sessionLengthSeconds;
                      final Color countdownColor = secondsLeft > 30
                          ? theme.colorScheme.primary
                          : secondsLeft > 10
                              ? Colors.orange
                              : Colors.red;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 5,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                countdownColor,
                              ),
                            ),
                          ),
                          Text(
                            '$secondsLeft',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: countdownColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speed Round',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${candidates.length} in queue  •  $_likesCount ❤️  $_passesCount ✗',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Swipeable candidate card
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset += details.delta.dx;
                    _isDragging = true;
                  });
                },
                onHorizontalDragEnd: (details) {
                  const threshold = 100.0;
                  if (_dragOffset > threshold) {
                    // Swipe right = like
                    _handleDecision(
                      candidate: activeCandidate,
                      liked: true,
                      currentUserId: user.uid,
                    );
                  } else if (_dragOffset < -threshold) {
                    // Swipe left = pass
                    _handleDecision(
                      candidate: activeCandidate,
                      liked: false,
                      currentUserId: user.uid,
                    );
                  } else {
                    setState(() {
                      _dragOffset = 0;
                      _isDragging = false;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(_dragOffset, 0, 0)
                    ..rotateZ(_dragOffset * 0.002),
                  child: Stack(
                    children: [
                      _buildCandidateCard(activeCandidate, theme, user.uid),
                      // Swipe overlay hints
                      if (_dragOffset > 40)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.pinkAccent, width: 2),
                            ),
                            child: const Text(
                              '❤️ LIKE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      if (_dragOffset < -40)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 2),
                            ),
                            child: const Text(
                              '✗ PASS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<SpeedDatingMatch>>(
                stream: _service.matchesStream(user.uid),
                builder: (context, matchSnapshot) {
                  final matches = matchSnapshot.data ?? const [];
                  if (matches.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent matches', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...matches.take(5).map((match) {
                        final otherId = match.otherUserId(user.uid);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                              child: const Icon(Icons.favorite),
                            ),
                            title: Text('Match with $otherId'),
                            subtitle: Text(match.latestRoomId == null
                                ? 'No live date started yet'
                                : 'Tap to rejoin your last live date room'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: match.latestRoomId == null ? null : () => context.go('/room/${match.latestRoomId}'),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widget: session stat badge
// ---------------------------------------------------------------------------
class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

