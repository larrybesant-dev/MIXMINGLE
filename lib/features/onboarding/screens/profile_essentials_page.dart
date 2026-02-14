import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../providers/profile_controller.dart';
import '../../../shared/models/user_profile.dart';

/// Profile Essentials - Step 1 of onboarding
/// Collects: Display Name, Age, Gender, Profile Photo
class ProfileEssentialsPage extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const ProfileEssentialsPage({super.key, required this.onComplete});

  @override
  ConsumerState<ProfileEssentialsPage> createState() =>
      _ProfileEssentialsPageState();
}

class _ProfileEssentialsPageState
    extends ConsumerState<ProfileEssentialsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedGender;
  XFile? _selectedPhoto;
  bool _isLoading = false;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() => _selectedPhoto = photo);
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  bool _canContinue() {
    return _nameController.text.trim().isNotEmpty &&
        _ageController.text.isNotEmpty &&
        _selectedGender != null &&
        _selectedPhoto != null;
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
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

      // Upload photo
      String? photoUrl;
      if (_selectedPhoto != null) {
        photoUrl = await controller.uploadAvatar(_selectedPhoto!, currentProfile.id);
      }

      // Calculate birthday from age
      final age = int.parse(_ageController.text);
      final birthday = DateTime.now().subtract(Duration(days: age * 365));

      // Update profile
      final updatedProfile = currentProfile.copyWith(
        displayName: _nameController.text.trim(),
        birthday: birthday,
        gender: _selectedGender,
        photoUrl: photoUrl ?? currentProfile.photoUrl,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
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
          title: const Text('Profile Setup'),
          backgroundColor: DesignColors.accent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  NeonText(
                    'LET\'S GET TO KNOW YOU',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    textColor: DesignColors.white,
                    glowColor: DesignColors.gold,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete your profile to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignColors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Photo picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DesignColors.accent,
                            width: 3,
                          ),
                          color: DesignColors.surfaceDefault,
                        ),
                        child: _selectedPhoto != null
                            ? ClipOval(
                                child: Image.network(
                                  _selectedPhoto!.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: DesignColors.accent,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: DesignColors.accent,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add Profile Photo *',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignColors.accent,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name *',
                      hintText: 'Your name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(color: DesignColors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Age
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Age *',
                      hintText: '18+',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(color: DesignColors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Age is required';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 18) {
                        return 'Must be 18 or older';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: const Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: DesignColors.surfaceDefault,
                    style: const TextStyle(color: DesignColors.white),
                    items: _genderOptions.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location (optional)
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'City, State/Country',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(color: DesignColors.white),
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  NeonButton(
                    label: _isLoading ? 'SAVING...' : 'CONTINUE',
                    onPressed: _isLoading ? () {} : _handleContinue,
                    glowColor: _canContinue()
                        ? DesignColors.gold
                        : DesignColors.accent20,
                    isLoading: _isLoading,
                    height: 54,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
