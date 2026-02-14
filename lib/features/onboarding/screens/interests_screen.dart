/// Interests Screen
///
/// Third screen of the onboarding flow.
/// User selects their interests/vibes with neon chip grid.
library;

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
import '../models/onboarding_data.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_chip.dart';

class InterestsScreen extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const InterestsScreen({
    super.key,
    required this.data,
    required this.onUpdate,
    this.onContinue,
    this.onBack,
  });

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  late Set<String> _selectedInterests;

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set.from(widget.data.interests);
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
    widget.onUpdate(widget.data.copyWith(
      interests: _selectedInterests.toList(),
    ));
  }

  bool get _canContinue => _selectedInterests.length >= 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSubtitle(),
                    const SizedBox(height: 24),
                    ..._buildCategorySections(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: DesignColors.textGray,
            ),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [NeonColors.neonBlue, NeonColors.neonOrange],
                  ).createShader(bounds),
                  child: const Text(
                    'Choose Your Vibe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step 2 of 5',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignColors.surfaceAlt.withValues(alpha: 0.8),
            DesignColors.surfaceDark.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: _canContinue
              ? DesignColors.gold.withValues(alpha: 0.5)
              : NeonColors.neonBlue.withValues(alpha: 0.2),
          width: _canContinue ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _canContinue
                    ? [DesignColors.gold, NeonColors.neonOrange]
                    : [NeonColors.neonBlue.withValues(alpha: 0.5), NeonColors.neonOrange.withValues(alpha: 0.3)],
              ),
            ),
            child: Center(
              child: Text(
                '${_selectedInterests.length}',
                style: TextStyle(
                  color: DesignColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _canContinue
                      ? "You're ready!"
                      : 'Select at least 3 interests',
                  style: TextStyle(
                    color: _canContinue
                        ? DesignColors.gold
                        : DesignColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _canContinue
                      ? "Great vibes selected"
                      : '${3 - _selectedInterests.length} more to go',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_canContinue)
            Icon(
              Icons.check_circle,
              color: DesignColors.gold,
              size: 28,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    // Convert InterestItems to NeonChipData
    final chips = InterestCategories.items.map((item) => NeonChipData(
      id: item.id,
      label: item.label,
      emoji: item.icon,
    )).toList();

    return [
      _buildCategorySection('Your Interests', chips),
    ];
  }

  Widget _buildCategorySection(String category, List<NeonChipData> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [NeonColors.neonOrange, NeonColors.neonBlue],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category,
                style: TextStyle(
                  color: DesignColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        NeonChipGrid(
          chips: chips,
          selectedIds: _selectedInterests.toList(),
          onToggle: _toggleInterest,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignColors.background.withValues(alpha: 0.0),
            DesignColors.background,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected chips preview
          if (_selectedInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedInterests.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final interest = _selectedInterests.elementAt(index);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: NeonColors.neonOrange.withValues(alpha: 0.2),
                        border: Border.all(
                          color: NeonColors.neonOrange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: NeonColors.neonOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          OnboardingNeonButton(
            text: 'Continue',
            onPressed: _canContinue ? widget.onContinue : null,
            enabled: _canContinue,
            useGoldTrim: _canContinue,
            width: double.infinity,
            height: 56,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}
