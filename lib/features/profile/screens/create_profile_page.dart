import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../core/responsive/responsive_utils.dart';
import '../../../core/animations/app_animations.dart';
import '../../../shared/providers/all_providers.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/glow_text.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/vibe_genres.dart';
import '../../../core/routing/app_routes.dart';

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
  final _zipController = TextEditingController();

  // ZIP lookup state
  String? _zipResolvedCity;   // "Chicago, IL"
  bool _zipLooking = false;
  String? _zipError;

  Future<void> _lookupZip(String zip) async {
    if (zip.length != 5) return;
    setState(() { _zipLooking = true; _zipError = null; _zipResolvedCity = null; });
    try {
      final res = await http.get(Uri.parse('https://api.zippopotam.us/us/$zip'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final places = data['places'] as List<dynamic>;
        if (places.isNotEmpty) {
          final city = places[0]['place name'] as String;
          final state = places[0]['state abbreviation'] as String;
          final resolved = '$city, $state';
          setState(() { _zipResolvedCity = resolved; _zipError = null; });
          _locationController.text = resolved;
        }
      } else {
        setState(() { _zipError = 'ZIP code not found'; });
      }
    } catch (_) {
      setState(() { _zipError = 'Could not look up ZIP code'; });
    } finally {
      setState(() { _zipLooking = false; });
    }
  }

  final ImagePicker _imagePicker = ImagePicker();
  String? _profileImageUrl;
  String? _selectedGender;
  final List<String> _selectedInterests = [];

  // ── Sprint 1: Vibe, Music, Country ────────────────────────
  String? _selectedVibeTag;
  final List<String> _selectedMusicGenres = [];
  String? _selectedCountryCode;

  // ── Loading guards ────────────────────────────────────────
  bool _isLoading = false;
  bool _isUploadingImage = false;

  int _currentStep = 0;
  // Step count: 0-Basic, 1-Interests, 2-Vibe, 3-Photo
  static const int _totalSteps = 4;

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
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isUploadingImage) return;
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() => _isUploadingImage = true);

        // Use Firebase Auth UID directly — currentUserProvider.future returns
        // null for brand-new users who have no Firestore document yet, which
        // silently aborted the upload. Auth UID is always available on this
        // page because the auth gate guarantees the user is signed in.
        final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          if (mounted) {
            setState(() => _isUploadingImage = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not authenticated — please sign in again.')),
            );
          }
          return;
        }

        final controller = ref.read(storageControllerProvider.notifier);
        final url = await controller.uploadImage(pickedFile, uid);
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
            if (url != null) {
              _profileImageUrl = url;
            }
          });
          if (url == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo upload failed — please try again.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _createProfile() async {
    if (_isLoading) return; // prevent double-submit
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

    setState(() => _isLoading = true);

    // Use Firebase Auth directly — this page is only reachable when the user
    // is authenticated. currentUserProvider.future returns null for users who
    // have no Firestore document yet (the exact case we're handling here).
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired — please sign in again.')),
        );
      }
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    DateTime? birthday;
    if (age != null) {
      birthday = DateTime(DateTime.now().year - age, 1, 1);
    }

    final userProfile = UserProfile(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: _usernameController.text.trim(),
      photoUrl: _profileImageUrl,
      interests: _selectedInterests,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      birthday: birthday,
      gender: _selectedGender,
      // Sprint 1 vibe fields
      vibeTag: _selectedVibeTag,
      musicGenres: _selectedMusicGenres.isNotEmpty ? List.unmodifiable(_selectedMusicGenres) : null,
      countryCode: _selectedCountryCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(profileControllerProvider).updateProfile(
            userProfile,
          );

      if (mounted) {
        // Use pushNamedAndRemoveUntil('/app') so that the RootAuthGate
        // re-evaluates now that the profile exists; avoids being trapped
        // inside _ProfileIncompleteApp's locked navigator.
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.app, (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: $e')),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
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
                    children: List.generate(_totalSteps, (index) {
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
                          onPressed: (_isLoading || _isUploadingImage) ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.responsiveSpacing(context, 16),
                            ),
                          ),
                          child: (_isLoading && _currentStep == _totalSteps - 1)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_currentStep < _totalSteps - 1 ? 'Next' : 'Create Profile'),
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
        return _buildVibeStep(context);
      case 3:
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

        // Location via ZIP code
        TextFormField(
          controller: _zipController,
          decoration: InputDecoration(
            labelText: 'ZIP Code (Optional)',
            hintText: '90210',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _zipLooking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _zipResolvedCity != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
            errorText: _zipError,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          onChanged: (val) {
            if (val.length == 5) _lookupZip(val);
            if (val.length < 5) {
              setState(() {
                _zipResolvedCity = null;
                _zipError = null;
                _locationController.clear();
              });
            }
          },
        ),
        if (_zipResolvedCity != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                _zipResolvedCity!,
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ),
        ],
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

  // ── Sprint 1: Vibe & Music step ────────────────────────────────────────────
  Widget _buildVibeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowText(
          text: 'Your Vibe',
          fontSize: Responsive.responsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 8)),
        Text(
          'Pick your energy and favourite music',
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 16),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 24)),

        // Vibe tags
        const Text(
          'Energy vibe',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VibeTags.all.map((tag) {
            final color = VibeTags.colorFor(tag);
            final isSelected = _selectedVibeTag == tag;
            return GestureDetector(
              onTap: () => setState(() => _selectedVibeTag = isSelected ? null : tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.45),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '${VibeTags.emojiFor(tag)} $tag',
                  style: TextStyle(
                    color: isSelected ? color : color.withValues(alpha: 0.75),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: Responsive.responsiveSpacing(context, 24)),

        // Music genres
        const Text(
          'Music genres  (pick as many as you like)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MusicGenres.all.map((genre) {
            final isSelected = _selectedMusicGenres.contains(genre);
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) => setState(() {
                if (selected) {
                  _selectedMusicGenres.add(genre);
                } else {
                  _selectedMusicGenres.remove(genre);
                }
              }),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),

        SizedBox(height: Responsive.responsiveSpacing(context, 24)),

        // Country picker
        const Text(
          'Country (optional)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 10)),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.flag_outlined),
            hintText: 'Select your country',
          ),
          initialValue: _selectedCountryCode,
          items: CountryFlags.commonCountries.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text('${CountryFlags.toEmoji(e.key)}  ${e.value}'),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCountryCode = v),
        ),
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
            behavior: HitTestBehavior.opaque,
            onTap: _isUploadingImage ? null : _pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
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
                  child: (!_isUploadingImage && _profileImageUrl == null)
                      ? Icon(
                          Icons.add_a_photo,
                          size: Responsive.responsiveIconSize(context, 60),
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                if (_isUploadingImage)
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
        SizedBox(height: Responsive.responsiveSpacing(context, 16)),
        Center(
          child: TextButton.icon(
            onPressed: _isUploadingImage ? null : _pickImage,
            icon: const Icon(Icons.photo_library),
            label: Text(_isUploadingImage
                ? 'Uploading…'
                : _profileImageUrl == null
                    ? 'Choose Photo'
                    : 'Change Photo'),
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
