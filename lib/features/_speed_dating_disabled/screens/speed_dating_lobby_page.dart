import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/design_system/design_constants.dart';
// TEMP DISABLED: import '../../../services/speed_dating_service.dart';
import '../../../providers/auth_providers.dart';
// TEMP DISABLED: import 'speed_dating_call_page.dart';

/// Speed Dating Lobby Page
/// Users wait here to be matched with another participant for a 3-5 minute video call
class SpeedDatingLobbyPage extends ConsumerStatefulWidget {
  const SpeedDatingLobbyPage({super.key});

  @override
  ConsumerState<SpeedDatingLobbyPage> createState() => _SpeedDatingLobbyPageState();
}

class _SpeedDatingLobbyPageState extends ConsumerState<SpeedDatingLobbyPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isSearching = false;
  bool _isMatched = false;
  String? _matchedUserId;
  String? _sessionId;
  Timer? _searchTimer;
  int _searchSeconds = 0;
  StreamSubscription? _matchSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchTimer?.cancel();
    _matchSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startSearching() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use Speed Dating')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchSeconds = 0;
    });

    // Start search timer
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _searchSeconds++);
      }
    });

    // Join the speed dating queue
    final service = SpeedDatingService();
    final sessionId = await service.joinQueue(user.id);

    if (sessionId != null) {
      _sessionId = sessionId;
      _listenForMatch(sessionId, user.id);
    }
  }

  void _listenForMatch(String sessionId, String userId) {
    final service = SpeedDatingService();
    _matchSubscription = service.listenForMatch(sessionId, userId).listen((matchData) {
      if (matchData != null && mounted) {
        setState(() {
          _isMatched = true;
          _matchedUserId = matchData['matchedUserId'];
        });

        _searchTimer?.cancel();

        // Navigate to call page after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _matchedUserId != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SpeedDatingCallPage(
                  sessionId: sessionId,
                  matchedUserId: _matchedUserId!,
                ),
              ),
            );
          }
        });
      }
    });
  }

  Future<void> _cancelSearch() async {
    _searchTimer?.cancel();
    _matchSubscription?.cancel();

    if (_sessionId != null) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final service = SpeedDatingService();
        await service.leaveQueue(_sessionId!, user.id);
      }
    }

    setState(() {
      _isSearching = false;
      _searchSeconds = 0;
      _sessionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Speed Dating',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isSearching) {
              _cancelSearch();
            }
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated heart/radar icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isSearching ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _isMatched
                                ? Colors.green.withValues(alpha: 0.8)
                                : DesignColors.accent.withValues(alpha: 0.8),
                            _isMatched
                                ? Colors.green.withValues(alpha: 0.2)
                                : DesignColors.accent.withValues(alpha: 0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isMatched ? Colors.green : DesignColors.accent)
                                .withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isMatched
                            ? Icons.favorite
                            : (_isSearching ? Icons.radar : Icons.favorite_border),
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Status text
              Text(
                _isMatched
                    ? 'Match Found!'
                    : (_isSearching
                        ? 'Finding your match...'
                        : 'Ready for Speed Dating?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Search timer or description
              if (_isSearching && !_isMatched)
                Text(
                  'Searching for ${_formatDuration(_searchSeconds)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                )
              else if (_isMatched)
                Text(
                  'Connecting you now...',
                  style: TextStyle(
                    color: Colors.green.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                )
              else
                Text(
                  'You\'ll be matched with someone for a 3-minute video call.\nAfter the call, decide if you want to connect!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),

              const SizedBox(height: 40),

              // Action button
              if (!_isMatched)
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSearching ? _cancelSearch : _startSearching,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSearching
                          ? Colors.red
                          : DesignColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      _isSearching ? 'Cancel' : 'Start Matching',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Tips
              if (!_isSearching)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTip(Icons.lightbulb, 'Be yourself and have fun!'),
                      const SizedBox(height: 8),
                      _buildTip(Icons.timer, 'Calls last 3 minutes'),
                      const SizedBox(height: 8),
                      _buildTip(Icons.favorite, 'If you both like each other, you can exchange info'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: DesignColors.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
