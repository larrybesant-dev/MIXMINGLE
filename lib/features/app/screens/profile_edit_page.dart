import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mix_and_mingle/shared/models/user_profile.dart';
import 'package:mix_and_mingle/services/profile_service.dart';
import 'package:mix_and_mingle/services/storage_service.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:mix_and_mingle/shared/validation.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileEditPage extends StatefulWidget {
  final UserProfile? initialProfile;

  const ProfileEditPage({super.key, this.initialProfile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _interestsController;
  bool _isLoading = false;
  String? _avatarUrl;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialProfile?.displayName ?? '');
    _bioController = TextEditingController(text: widget.initialProfile?.bio ?? '');
    _locationController = TextEditingController(text: widget.initialProfile?.location ?? '');
    _interestsController = TextEditingController(text: widget.initialProfile?.interests?.join(', ') ?? '');
    _avatarUrl = widget.initialProfile?.photoUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Cache theme color before async operations
      final primaryColor = Theme.of(context).primaryColor;

      // Show bottom sheet with options
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (_avatarUrl != null || _selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _avatarUrl = null;
                      });
                    },
                  ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Crop the image (skip on web for now due to cropper limitations)
        if (!kIsWeb) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Profile Photo',
                toolbarColor: primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: 'Crop Profile Photo',
                aspectRatioLockEnabled: true,
              ),
            ],
          );

          if (croppedFile != null && mounted) {
            setState(() {
              _selectedImage = XFile(croppedFile.path);
            });
            debugPrint('Image cropped and selected: ${croppedFile.path}');
          }
        } else {
          // Web - use image without cropping
          if (mounted) {
            setState(() {
              _selectedImage = image;
            });
          }
          debugPrint('Image selected (web): ${image.name}');
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      debugPrint('No image selected to upload');
      return _avatarUrl;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return null;
      }

      debugPrint('Starting profile photo upload for user: ${user.uid}');
      final storageService = StorageService();
      final downloadUrl = await storageService.uploadAvatar(_selectedImage!, user.uid);

      debugPrint('Profile photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
      return null;
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      // Show selected image preview
      if (kIsWeb) {
        return NetworkImage(_selectedImage!.path);
      } else {
        return FileImage(File(_selectedImage!.path));
      }
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload image if selected
      final photoUrl = await _uploadImage();

      final updatedProfile = UserProfile(
        id: user.uid,
        email: user.email!,
        displayName: ValidationHelpers.sanitizeInput(_displayNameController.text),
        photoUrl: photoUrl,
        bio: _bioController.text.trim().isEmpty ? null : ValidationHelpers.sanitizeInput(_bioController.text),
        location:
            _locationController.text.trim().isEmpty ? null : ValidationHelpers.sanitizeInput(_locationController.text),
        interests: _interestsController.text.trim().isEmpty
            ? null
            : _interestsController.text.trim().split(',').map((e) => ValidationHelpers.sanitizeInput(e)).toList(),
        createdAt: widget.initialProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ProfileService().updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Edit Profile'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _getProfileImage(),
                            child: _selectedImage == null && _avatarUrl == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _pickImage,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.edit),
                        label: Text(_avatarUrl != null || _selectedImage != null
                            ? 'Change Profile Picture'
                            : 'Add Profile Picture'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Profile Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Display Name
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter your display name',
                  ),
                  maxLength: ValidationConstants.displayNameMaxLength,
                  validator: (value) {
                    final user = FirebaseAuth.instance.currentUser;
                    // Basic length validation
                    final lengthError = ValidationHelpers.validateLengthRequired(
                      value,
                      ValidationConstants.displayNameMinLength,
                      ValidationConstants.displayNameMaxLength,
                      'Display name',
                    );
                    if (lengthError != null) return lengthError;

                    // EMAIL PRIVACY: Prevent email from being used as display name
                    if (user?.email != null &&
                        user?.email?.isNotEmpty == true &&
                        ValidationHelpers.areEqualIgnoreCase(value, user!.email)) {
                      return 'Display name cannot be your email address';
                    }

                    // EMAIL PRIVACY: Check for email patterns
                    final emailPatternError = ValidationHelpers.validateNoEmailPattern(
                      value,
                      'Display name',
                    );
                    if (emailPatternError != null) return emailPatternError;

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    hintText: 'Tell others about yourself...',
                  ),
                  maxLines: 3,
                  maxLength: ValidationConstants.bioMaxLength,
                  validator: (value) => ValidationHelpers.validateLengthOptional(
                    value,
                    1,
                    ValidationConstants.bioMaxLength,
                    'Bio',
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    hintText: 'City, Country',
                  ),
                ),
                const SizedBox(height: 16),

                // Interests
                TextFormField(
                  controller: _interestsController,
                  decoration: const InputDecoration(
                    labelText: 'Interests',
                    border: OutlineInputBorder(),
                    hintText: 'Music, Travel, Sports (comma separated)',
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
