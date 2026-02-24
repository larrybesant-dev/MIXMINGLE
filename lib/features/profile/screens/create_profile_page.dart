import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/responsive/responsive_utils.dart';
import '../../../core/animations/app_animations.dart';
import '../../../shared/providers/all_providers.dart';
import 'package:mixmingle/app/app_routes.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/glow_text.dart';
import '../../../shared/models/user_profile.dart';

class CreateProfilePage extends ConsumerStatefulWidget {
  const CreateProfilePage({super.key});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  String? _profileImageUrl;
  String? _selectedGender;
  final List<String> _selectedInterests = [];
  int _currentStep = 0;

  final List<String> _availableInterests = [
    'Music',
    'Sports',
    'Travel',
    'Food',
    'Movies',
    'Books',
    'Gaming',
    'Art',
    'Photography',
    'Fitness',
    'Dancing',
    'Cooking',
    'Technology',
    'Nature',
    'Pets',
    'Fashion',
    'Shopping',
    'Nightlife',
    'Volunteering',
  ];

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        // CRITICAL FIX: Use .future to ensure we get a user, not just .value
        final currentUser = await ref.read(currentUserProvider.future);
        if (currentUser == null) return;

        final controller = ref.read(storageControllerProvider.notifier);
        final url = await controller.uploadImage(
          pickedFile,
          currentUser.id,
        );
        if (url != null) {
          setState(() => _profileImageUrl = url);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    // CRITICAL FIX: Use .future to ensure we get a user, not just .value
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    final age = int.tryParse(_ageController.text.trim());
    DateTime? birthday;
    if (age != null) {
      birthday = DateTime(DateTime.now().year - age, 1, 1);
    }

    final userProfile = UserProfile(
      id: currentUser.id,
      email: currentUser.email,
      displayName: _usernameController.text.trim(),
      photoUrl: _profileImageUrl,
      interests: _selectedInterests,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      birthday: birthday,
      gender: _selectedGender,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(profileControllerProvider).updateProfile(
            userProfile,
          );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: $e')),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _createProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Create Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: Responsive.responsivePadding(context),
                  child: Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: Responsive.responsivePadding(context),
                    child: AppAnimations.fadeIn(
                      child: _buildStepContent(context),
                    ),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: Responsive.responsivePadding(context),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentStep > 0) SizedBox(width: Responsive.responsiveSpacing(context, 16)),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.responsiveSpacing(context, 16),
                            ),
                          ),
                          child: Text(_currentStep < 2 ? 'Next' : 'Create Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.responsiveSpacing(context, 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(context);
      case 1:
        return _buildInterestsStep(context);
      case 2:
        return _buildPhotoStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowText(
          text: 'Basic Information',
          fontSize: Responsive.responsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 8)),
        Text(
          'Let\'s start with the essentials',
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 16),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 32)),

        // Username
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Choose a unique username',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            if (value.trim().length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 16)),

        // Age
        TextFormField(
          controller: _ageController,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Your age',
            prefixIcon: Icon(Icons.cake),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Age is required';
            }
            final age = int.tryParse(value.trim());
            if (age == null || age < 18 || age > 100) {
              return 'Please enter a valid age (18-100)';
            }
            return null;
          },
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 16)),

        // Gender
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.wc),
          ),
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
            if (value == null || value.isEmpty) {
              return 'Please select your gender';
            }
            return null;
          },
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 16)),

        // Location
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location (Optional)',
            hintText: 'City, Country',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 16)),

        // Bio
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell others about yourself',
            prefixIcon: Icon(Icons.edit),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildInterestsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowText(
          text: 'Your Interests',
          fontSize: Responsive.responsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 8)),
        Text(
          'Select at least one interest',
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 16),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 24)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return AppAnimations.scaleIn(
              beginScale: 0.9,
              child: FilterChip(
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
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
        if (_selectedInterests.isNotEmpty) ...[
          SizedBox(height: Responsive.responsiveSpacing(context, 24)),
          Text(
            'Selected: ${_selectedInterests.length}',
            style: TextStyle(
              fontSize: Responsive.responsiveFontSize(context, 14),
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowText(
          text: 'Profile Photo',
          fontSize: Responsive.responsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 8)),
        Text(
          'Add a great photo of yourself',
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 16),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 32)),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: Responsive.responsiveValue(
                context: context,
                mobile: 150.0,
                tablet: 200.0,
                desktop: 250.0,
              ),
              height: Responsive.responsiveValue(
                context: context,
                mobile: 150.0,
                tablet: 200.0,
                desktop: 250.0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                image: _profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImageUrl == null
                  ? Icon(
                      Icons.add_a_photo,
                      size: Responsive.responsiveIconSize(context, 60),
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 16)),
        Center(
          child: TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: Text(_profileImageUrl == null ? 'Choose Photo' : 'Change Photo'),
          ),
        ),
        if (_profileImageUrl == null) ...[
          SizedBox(height: Responsive.responsiveSpacing(context, 24)),
          Container(
            padding: Responsive.responsivePadding(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A profile photo helps others connect with you',
                    style: TextStyle(
                      fontSize: Responsive.responsiveFontSize(context, 14),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
