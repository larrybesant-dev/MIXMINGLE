import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:mix_and_mingle/shared/widgets/async_value_view_enhanced.dart';
import 'package:mix_and_mingle/providers/profile_controller.dart';
import 'package:mix_and_mingle/shared/models/user_profile.dart';
import 'package:mix_and_mingle/shared/validation.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  final picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;
  List<String> _selectedInterests = [];

  final List<String> _availableInterests = [
    'Music',
    'Sports',
    'Gaming',
    'Movies',
    'Travel',
    'Food',
    'Art',
    'Reading',
    'Dancing',
    'Technology',
    'Fitness',
    'Photography',
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(String userId, UserProfile currentProfile) async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final controller = ref.read(profileControllerProvider);
      final profileService = ref.read(profileServiceProvider);

      debugPrint('🔧 Starting avatar upload for user: $userId');
      final url = await controller.uploadAvatar(picked, userId);
      debugPrint('📸 Upload URL: $url');

      if (url == null) {
        throw Exception('Upload returned null URL');
      }

      if (!mounted) return;

      // Update the profile with the new photo URL
      final updatedProfile = currentProfile.copyWith(photoUrl: url);
      debugPrint('💾 Saving profile with new photo URL');
      await profileService.updateUserProfile(updatedProfile);
      debugPrint('✅ Profile saved successfully');

      // Invalidate the provider to refresh UI
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickAndUploadCoverPhoto(String userId, UserProfile currentProfile) async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final controller = ref.read(profileControllerProvider);
      final profileService = ref.read(profileServiceProvider);

      debugPrint('🔧 Starting cover photo upload for user: $userId');
      final url = await controller.uploadCoverPhoto(picked, userId);
      debugPrint('📸 Upload URL: $url');

      if (url == null) {
        throw Exception('Upload returned null URL');
      }

      if (!mounted) return;

      // Update the profile with the new cover photo URL
      final updatedProfile = currentProfile.copyWith(coverPhotoUrl: url);
      debugPrint('💾 Saving profile with new cover photo URL');
      await profileService.updateUserProfile(updatedProfile);
      debugPrint('✅ Profile saved successfully');

      // Invalidate the provider to refresh UI
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover photo updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('❌ Cover photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload cover photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile(UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = UserProfile(
        id: currentProfile.id,
        email: currentProfile.email,
        displayName: _displayNameController.text.trim().isNotEmpty
            ? ValidationHelpers.sanitizeInput(_displayNameController.text.trim())
            : currentProfile.displayName,
        nickname: _nicknameController.text.trim().isNotEmpty
            ? ValidationHelpers.sanitizeInput(_nicknameController.text.trim())
            : currentProfile.nickname,
        bio: _bioController.text.trim().isNotEmpty
            ? ValidationHelpers.sanitizeInput(_bioController.text.trim())
            : currentProfile.bio,
        location: _locationController.text.trim().isNotEmpty
            ? ValidationHelpers.sanitizeInput(_locationController.text.trim())
            : currentProfile.location,
        interests: _selectedInterests.isNotEmpty ? _selectedInterests : currentProfile.interests,
        photoUrl: currentProfile.photoUrl,
        coverPhotoUrl: currentProfile.coverPhotoUrl,
        galleryPhotos: currentProfile.galleryPhotos,
        birthday: currentProfile.birthday,
        gender: currentProfile.gender,
        pronouns: currentProfile.pronouns,
        lookingFor: currentProfile.lookingFor,
        relationshipType: currentProfile.relationshipType,
        minAgePreference: currentProfile.minAgePreference,
        maxAgePreference: currentProfile.maxAgePreference,
        preferredGenders: currentProfile.preferredGenders,
        personalityPrompts: currentProfile.personalityPrompts,
        musicTastes: currentProfile.musicTastes,
        lifestylePrompts: currentProfile.lifestylePrompts,
        isPhotoVerified: currentProfile.isPhotoVerified,
        isPhoneVerified: currentProfile.isPhoneVerified,
        isEmailVerified: currentProfile.isEmailVerified,
        isIdVerified: currentProfile.isIdVerified,
        socialLinks: currentProfile.socialLinks,
        verifiedOnlyMode: currentProfile.verifiedOnlyMode,
        privateMode: currentProfile.privateMode,
        latitude: currentProfile.latitude,
        longitude: currentProfile.longitude,
        createdAt: currentProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(profileControllerProvider);
      await controller.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeFields(UserProfile profile) {
    if (_displayNameController.text.isEmpty) {
      _displayNameController.text = profile.displayName ?? '';
    }
    if (_nicknameController.text.isEmpty) {
      _nicknameController.text = profile.nickname ?? '';
    }
    if (_bioController.text.isEmpty) {
      _bioController.text = profile.bio ?? '';
    }
    if (_locationController.text.isEmpty) {
      _locationController.text = profile.location ?? '';
    }
    if (_selectedInterests.isEmpty && profile.interests != null) {
      _selectedInterests = List.from(profile.interests!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AsyncValueViewEnhanced<UserProfile?>(
          value: profileAsync,
          maxRetries: 3,
          screenName: 'EditProfilePage',
          providerName: 'currentUserProfileProvider',
          onRetry: () => ref.invalidate(currentUserProfileProvider),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }

            _initializeFields(profile);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: profile.photoUrl != null
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                            child: profile.photoUrl == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          if (_isUploading)
                            const Positioned.fill(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: () => _pickAndUploadAvatar(profile.id, profile),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Cover photo button
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : () => _pickAndUploadCoverPhoto(profile.id, profile),
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Cover Photo'),
                    ),

                    const SizedBox(height: 24),

                    // Display name
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: ValidationConstants.displayNameMaxLength,
                      validator: (value) {
                        return ValidationHelpers.validateLengthOptional(
                          value,
                          ValidationConstants.displayNameMinLength,
                          ValidationConstants.displayNameMaxLength,
                          'Display Name',
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Nickname
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: ValidationConstants.displayNameMaxLength,
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                        hintText: 'Tell us about yourself',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Interests
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
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
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _saveProfile(profile),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Profile', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
