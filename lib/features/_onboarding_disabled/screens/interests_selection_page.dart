import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../providers/profile_controller.dart';

/// Interests Selection - Step 2 of onboarding
/// User selects interests for personalization
class InterestsSelectionPage extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const InterestsSelectionPage({super.key, required this.onComplete});

  @override
  ConsumerState<InterestsSelectionPage> createState() =>
      _InterestsSelectionPageState();
}

class _InterestsSelectionPageState
    extends ConsumerState<InterestsSelectionPage> {
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  final Map<String, List<String>> _interestCategories = {
    'Music': ['Pop', 'Rock', 'Hip-Hop', 'EDM', 'Jazz', 'Country'],
    'Gaming': ['FPS', 'RPG', 'Strategy', 'Casual', 'MMO', 'Sports Games'],
    'Lifestyle': ['Fitness', 'Wellness', 'Fashion', 'Travel', 'Food', 'Pets'],
    'Entertainment': ['Movies', 'TV Shows', 'Comedy', 'Podcasts', 'Reading'],
    'Sports': ['Football', 'Basketball', 'Soccer', 'Tennis', 'Gym', 'Running'],
    'Tech': ['Coding', 'AI', 'Crypto', 'Gadgets', 'Gaming Tech'],
  };

  bool _canContinue() {
    return _selectedInterests.isNotEmpty;
  }

  Future<void> _handleContinue() async {
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          backgroundColor: DesignColors.accent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(profileControllerProvider);
      final currentProfile = await ref.read(currentUserProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('No user profile found');
      }

      // Update profile with interests
      final updatedProfile = currentProfile.copyWith(
        interests: _selectedInterests,
        updatedAt: DateTime.now(),
      );

      await controller.updateProfile(updatedProfile);

      // Invalidate provider to refresh
      ref.invalidate(currentUserProfileProvider);

      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select Interests'),
          backgroundColor: DesignColors.accent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      NeonText(
                        'WHAT ARE YOU INTO?',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        textColor: DesignColors.white,
                        glowColor: DesignColors.gold,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pick a few so we can personalize your experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: DesignColors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedInterests.length} selected',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DesignColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interest categories
                      ..._interestCategories.entries.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.key,
                              style: const TextStyle(
                                color: DesignColors.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: category.value.map((interest) {
                                final isSelected =
                                    _selectedInterests.contains(interest);
                                return FilterChip(
                                  label: Text(interest),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedInterests.add(interest);
                                      } else {
                                        _selectedInterests.remove(interest);
                                      }
                                    });
                                  },
                                  backgroundColor: DesignColors.surfaceDefault,
                                  selectedColor: DesignColors.accent,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? DesignColors.white
                                        : DesignColors.accent,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(24),
                child: NeonButton(
                  label: _isLoading ? 'SAVING...' : 'CONTINUE',
                  onPressed: _isLoading ? () {} : _handleContinue,
                  glowColor: _canContinue()
                      ? DesignColors.gold
                      : DesignColors.accent20,
                  isLoading: _isLoading,
                  height: 54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
