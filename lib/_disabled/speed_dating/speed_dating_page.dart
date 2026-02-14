import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/speed_dating_round.dart';
import '../shared/models/speed_dating_result.dart';
import '../shared/models/user_profile.dart';
import '../providers/speed_dating_controller.dart';
import '../providers/profile_controller.dart';

class SpeedDatingPage extends ConsumerStatefulWidget {
  final String eventId;

  const SpeedDatingPage({super.key, required this.eventId});

  @override
  ConsumerState<SpeedDatingPage> createState() => _SpeedDatingPageState();
}

class _SpeedDatingPageState extends ConsumerState<SpeedDatingPage> {
  SpeedDatingRound? _currentRound;
  String? _currentMatchUserId;
  bool _isLoading = false;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveRounds();
  }

  Future<void> _loadActiveRounds() async {
    setState(() => _isLoading = true);
    try {
      final rounds = await ref.read(speedDatingServiceProvider).getActiveRoundsForEvent(widget.eventId);
      if (rounds.isNotEmpty) {
        setState(() => _currentRound = rounds.first);
        _findCurrentMatch();
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load speed dating rounds: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _findCurrentMatch() {
    if (_currentRound == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final matches = _currentRound!.matches[currentUserId];
    if (matches != null && matches.isNotEmpty) {
      setState(() => _currentMatchUserId = matches.first);
    }
  }

  void _startTimer() {
    if (_currentRound == null) return;

    final endTime = _currentRound!.startTime.add(
      Duration(minutes: _currentRound!.roundDurationMinutes),
    );
    final timeLeft = endTime.difference(DateTime.now()).inSeconds;

    setState(() => _timeLeft = timeLeft > 0 ? timeLeft : 0);

    // Update timer every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeLeft > 0) {
        _startTimer();
      }
    });
  }

  Future<void> _submitLike(bool liked) async {
    if (_currentRound == null || _currentMatchUserId == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final result = SpeedDatingResult(
        id: '${_currentRound!.id}_${currentUserId}_${_currentMatchUserId}_${_currentRound!.currentRound}',
        roundId: _currentRound!.id,
        userId: currentUserId,
        matchedUserId: _currentMatchUserId!,
        userLiked: liked,
        matchedUserLiked: false, // Will be updated when the other user responds
        isMutual: false,
        timestamp: DateTime.now(),
      );

      await ref.read(speedDatingControllerProvider.notifier).submitResult(result);

      // Move to next match or round
      _moveToNextMatch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit response: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _moveToNextMatch() {
    if (_currentRound == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final matches = _currentRound!.matches[currentUserId];
    if (matches == null || matches.length <= 1) {
      // No more matches in this round, advance to next round
      _advanceToNextRound();
      return;
    }

    // For simplicity, just move to the next match (in a real app, you'd track progress)
    final currentIndex = matches.indexOf(_currentMatchUserId!);
    final nextIndex = (currentIndex + 1) % matches.length;
    setState(() => _currentMatchUserId = matches[nextIndex]);
  }

  Future<void> _advanceToNextRound() async {
    if (_currentRound == null) return;

    try {
      await ref.read(speedDatingControllerProvider.notifier).advanceRound(_currentRound!.id);
      // Reload the round data
      await _loadActiveRounds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to advance to next round: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentRound == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Speed Dating'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No active speed dating rounds',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later or join an event!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${_currentRound!.currentRound}/${_currentRound!.totalRounds}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _formatTime(_timeLeft),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _currentMatchUserId == null
          ? const Center(
              child: Text('Waiting for match...'),
            )
          : FutureBuilder<UserProfile?>(
              future: ref.read(profileServiceProvider).getUserProfile(_currentMatchUserId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final matchUser = snapshot.data;
                if (matchUser == null) {
                  return const Center(child: Text('Match user not found'));
                }

                return Column(
                  children: [
                    // Match User Profile
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Profile Image
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: matchUser.photos.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(matchUser.photos.first),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey[300],
                              ),
                              child: matchUser.photos.isEmpty
                                  ? const Icon(Icons.person, size: 80, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Name and Age
                            Text(
                              '${matchUser.displayName}, ${matchUser.age}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Bio
                            if (matchUser.bio != null && matchUser.bio!.isNotEmpty)
                              Text(
                                matchUser.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Interests
                            if (matchUser.interests != null && matchUser.interests!.isNotEmpty) ...[
                              const Text(
                                'Interests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: matchUser.interests!.map((interest) {
                                  return Chip(
                                    label: Text(interest),
                                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('speedDatingPassButton'),
                              onPressed: () => _submitLike(false),
                              icon: const Icon(Icons.close, color: Colors.white),
                              label: const Text('Pass'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('speedDatingLikeButton'),
                              onPressed: () => _submitLike(true),
                              icon: const Icon(Icons.favorite, color: Colors.white),
                              label: const Text('Like'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
