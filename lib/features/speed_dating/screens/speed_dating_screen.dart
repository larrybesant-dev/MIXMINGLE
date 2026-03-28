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

class _SpeedDatingScreenState extends State<SpeedDatingScreen> {
  static const int _sessionLengthSeconds = 90;

  final SpeedDatingService _service = SpeedDatingService();
  int _candidateIndex = 0;
  int _secondsLeft = _sessionLengthSeconds;
  Timer? _timer;
  bool _isSubmitting = false;

  double get _progress => _secondsLeft / _sessionLengthSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _sessionLengthSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _nextCandidate();
        return;
      }
      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  void _nextCandidate() {
    setState(() {
      _candidateIndex += 1;
    });
    _startTimer();
  }

  Future<void> _handleDecision({
    required SpeedDateCandidate candidate,
    required bool liked,
    required String currentUserId,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = await _service.submitDecision(
        fromUserId: currentUserId,
        toUserId: candidate.id,
        liked: liked,
        sessionSeconds: _sessionLengthSeconds - _secondsLeft,
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
          title: const Text('It\'s a match'),
          content: Text('You and ${candidate.username} liked each other.'),
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
              child: const Text('Start Live Date'),
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No one is in the speed-dating queue right now. Check back in a moment.'),
              ),
            );
          }

          final activeCandidate = candidates[_candidateIndex % candidates.length];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.secondary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urban Speed Round',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Move fast, match real, then jump into a live date.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.timer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Time left: ${_secondsLeft}s',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text('Queue: ${candidates.length}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCandidateCard(activeCandidate, theme, user.uid),
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
