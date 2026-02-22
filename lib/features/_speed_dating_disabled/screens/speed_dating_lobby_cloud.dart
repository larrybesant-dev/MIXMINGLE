library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Speed Dating Lobby Page - PRODUCTION VERSION
/// Uses Cloud Functions for matching

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
// TEMP DISABLED: import '../../../shared/models/speed_dating_preferences.dart';
// TEMP DISABLED: import '../providers/speed_dating_queue_cloud.dart';

/// Speed Dating Lobby - Queue + Matching
class SpeedDatingLobbyPageCloud extends ConsumerStatefulWidget {
  const SpeedDatingLobbyPageCloud({super.key});

  @override
  ConsumerState<SpeedDatingLobbyPageCloud> createState() =>
      _SpeedDatingLobbyPageCloudState();
}

class _SpeedDatingLobbyPageCloudState
    extends ConsumerState<SpeedDatingLobbyPageCloud>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Preferences
  SpeedDatingPreferences _preferences = SpeedDatingPreferences.defaultPreferences();

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
    super.dispose();
  }

  Future<void> _startMatching() async {
    await ref
        .read(speedDatingQueueProvider.notifier)
        .joinQueue(_preferences);
  }

  Future<void> _stopMatching() async {
    await ref.read(speedDatingQueueProvider.notifier).leaveQueue();
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(speedDatingQueueProvider);
    final currentMatchId = ref.watch(currentMatchIdProvider);
    final queueCount = ref.watch(queueCountProvider);

    // Auto-navigate when matched
    ref.listen(currentMatchIdProvider, (previous, next) {
      if (next != null && previous != next) {
        debugPrint('ðŸŽ‰ Match found! Navigating to session: $next');
        Navigator.pushReplacementNamed(
          context,
          '/speed-dating/session',
          arguments: next,
        );
      }
    });

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: NeonText(
            'SPEED DATING',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showPreferencesDialog(),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status card
                _buildStatusCard(queueState, queueCount),

                const SizedBox(height: 24),

                // Action button
                if (!queueState.isInQueue)
                  _buildStartButton(queueState)
                else
                  _buildWaitingCard(),

                const SizedBox(height: 24),

                // Error message
                if (queueState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            queueState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // How it works
                _buildHowItWorks(),

                const SizedBox(height: 24),

                // Preferences summary
                _buildPreferencesSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(QueueState queueState, int queueCount) {
    return NeonGlowCard(
      glowColor: DesignColors.accent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('IN QUEUE', '$queueCount', Icons.people),
              _buildStatItem(
                'YOUR STATUS',
                queueState.isInQueue ? 'Waiting' : 'Idle',
                Icons.access_time,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: DesignColors.gold, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: DesignColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(QueueState queueState) {
    return NeonButton(
      label: queueState.isLoading ? 'JOINING...' : 'START MATCHING',
      onPressed: queueState.isLoading ? null : _startMatching,
      glowColor: DesignColors.accent,
      icon: Icons.favorite,
      width: double.infinity,
    );
  }

  Widget _buildWaitingCard() {
    return NeonGlowCard(
      glowColor: DesignColors.gold,
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Icon(
              Icons.search,
              size: 64,
              color: DesignColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ðŸ” Searching for your match...',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cloud matching in progress',
            style: TextStyle(
              color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: 'CANCEL',
            onPressed: _stopMatching,
            glowColor: Colors.red,
            icon: Icons.close,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return NeonGlowCard(
      glowColor: DesignColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStep('1', 'Set your preferences', Icons.tune),
          _buildStep('2', 'Join the queue', Icons.queue),
          _buildStep('3', 'Cloud matches you automatically', Icons.auto_awesome),
          _buildStep('4', '5-minute video call', Icons.videocam),
          _buildStep('5', 'Like or pass', Icons.favorite_border),
          _buildStep('6', 'Match if both like!', Icons.celebration),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: DesignColors.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: DesignColors.gold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSummary() {
    return NeonGlowCard(
      glowColor: DesignColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Preferences',
                style: TextStyle(
                  color: DesignColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _showPreferencesDialog,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPrefItem('Age', '${_preferences.minAge}-${_preferences.maxAge}'),
          _buildPrefItem(
            'Gender',
            _preferences.genderPreferences.isEmpty
                ? 'Any'
                : _preferences.genderPreferences.join(', '),
          ),
          if (_preferences.onlyVerified)
            _buildPrefItem('Verified', 'Only verified users'),
        ],
      ),
    );
  }

  Widget _buildPrefItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: DesignColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPreferencesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.background,
        title: const Text(
          'Matching Preferences',
          style: TextStyle(color: DesignColors.white),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age range
                Text(
                  'Age: ${_preferences.minAge} - ${_preferences.maxAge}',
                  style: const TextStyle(color: DesignColors.white),
                ),
                RangeSlider(
                  values: RangeValues(
                    _preferences.minAge.toDouble(),
                    _preferences.maxAge.toDouble(),
                  ),
                  min: 18,
                  max: 80,
                  activeColor: DesignColors.accent,
                  onChanged: (values) {
                    setDialogState(() {
                      _preferences = _preferences.copyWith(
                        minAge: values.start.round(),
                        maxAge: values.end.round(),
                      );
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Gender preferences
                const Text(
                  'Gender Preferences',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['male', 'female', 'non-binary', 'other']
                      .map((gender) => FilterChip(
                            label: Text(gender),
                            selected:
                                _preferences.genderPreferences.contains(gender),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  _preferences = _preferences.copyWith(
                                    genderPreferences: [
                                      ..._preferences.genderPreferences,
                                      gender
                                    ],
                                  );
                                } else {
                                  _preferences = _preferences.copyWith(
                                    genderPreferences: _preferences
                                        .genderPreferences
                                        .where((g) => g != gender)
                                        .toList(),
                                  );
                                }
                              });
                            },
                            backgroundColor:
                                DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                            selectedColor: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                            checkmarkColor: DesignColors.white,
                            labelStyle:
                                const TextStyle(color: DesignColors.white),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 16),

                // Verified only
                CheckboxListTile(
                  title: const Text(
                    'Verified users only',
                    style: TextStyle(color: DesignColors.white),
                  ),
                  value: _preferences.onlyVerified,
                  onChanged: (value) {
                    setDialogState(() {
                      _preferences =
                          _preferences.copyWith(onlyVerified: value ?? false);
                    });
                  },
                  activeColor: DesignColors.accent,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    setState(() {}); // Refresh UI with new preferences
  }
}
