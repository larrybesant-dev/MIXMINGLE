/// Profile Setup Screen
///
/// Second screen of the onboarding flow.
/// User sets up their VIP profile with name, age, and mood.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
import '../models/onboarding_data.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_chip.dart';

class ProfileSetupScreen extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const ProfileSetupScreen({
    super.key,
    required this.data,
    required this.onUpdate,
    this.onContinue,
    this.onBack,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  String? _selectedMood;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.name ?? '');
    _ageController = TextEditingController(
      text: (widget.data.age ?? 0) > 0 ? widget.data.age.toString() : '',
    );
    _selectedMood = widget.data.mood;

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _updateData() {
    final age = int.tryParse(_ageController.text) ?? 0;
    widget.onUpdate(widget.data.copyWith(
      name: _nameController.text.trim(),
      age: age,
      mood: _selectedMood,
    ));
  }

  bool get _canContinue {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text) ?? 0;
    return name.length >= 2 && age >= 18 && _selectedMood != null;
  }

  Future<void> _pickProfileImage() async {
    // TODO: Implement image picker integration
    // For now, just show a placeholder message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile photo selection coming soon!'),
        backgroundColor: DesignColors.surfaceAlt,
      ),
    );
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Profile Photo
                    _buildProfilePhoto(),

                    const SizedBox(height: 40),

                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Display Name',
                      hint: 'How should we call you?',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v?.length ?? 0) >= 2
                          ? null
                          : 'At least 2 characters',
                    ),

                    const SizedBox(height: 20),

                    // Age Field
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: '18+',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (v) {
                        final age = int.tryParse(v ?? '') ?? 0;
                        return age >= 18 ? null : 'Must be 18+';
                      },
                    ),

                    const SizedBox(height: 32),

                    // Mood Selector
                    _buildMoodSelector(),

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
                    colors: [NeonColors.neonOrange, DesignColors.gold],
                  ).createShader(bounds),
                  child: const Text(
                    'Your VIP Pass',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step 1 of 5',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeonColors.neonOrange.withValues(alpha: _glowAnimation.value),
                  NeonColors.neonBlue.withValues(alpha: _glowAnimation.value),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.neonOrange.withValues(
                    alpha: _glowAnimation.value * 0.5,
                  ),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignColors.surfaceDark,
                ),
                child: _profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: NeonColors.neonOrange,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: DesignColors.textGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: NeonColors.neonBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: DesignColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NeonColors.neonOrange.withValues(alpha: 0.3),
            ),
            color: DesignColors.surfaceAlt.withValues(alpha: 0.5),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: DesignColors.textGray.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) {
              setState(() {});
              _updateData();
            },
          ),
        ),
        // Validation hint
        if (validator != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Builder(
              builder: (context) {
                final error = validator(controller.text);
                return Text(
                  error ?? '',
                  style: TextStyle(
                    color: error != null
                        ? Colors.red.shade300
                        : Colors.transparent,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              color: NeonColors.neonBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "What's your vibe tonight?",
              style: TextStyle(
                color: DesignColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: MoodOptions.moods.map((mood) {
            final isSelected = _selectedMood == mood;
            return NeonChip(
              label: mood,
              isSelected: isSelected,
              useGoldGlow: isSelected,
              onTap: () {
                setState(() {
                  _selectedMood = mood;
                });
                _updateData();
              },
            );
          }).toList(),
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
          if (!_canContinue)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Please complete all fields to continue',
                style: TextStyle(
                  color: DesignColors.textGray.withValues(alpha: 0.7),
                  fontSize: 12,
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
