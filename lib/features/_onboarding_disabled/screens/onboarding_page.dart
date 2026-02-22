import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_providers.dart';
import '../../../services/profile_service.dart';
import '../../../services/photo_upload_service.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/club_background.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Other';
  List<String> _selectedInterests = [];
  XFile? _selectedPhoto;
  bool _isDiscoverable = true;
  bool _allowNotifications = true;
  bool _isLoading = false;

  Map<String, dynamic>? _interestsData;

  @override
  void initState() {
    super.initState();
    _loadInterests();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInterests() async {
    try {
      final String data = await rootBundle.loadString('assets/data/interests.json');
      setState(() {
        _interestsData = json.decode(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load interests: $e')),
        );
      }
    }
  }

  Future<void> _loadExistingProfile() async {
    final currentUserProfile = ref.read(currentUserProfileProvider).value;
    if (currentUserProfile != null) {
      setState(() {
        _nameController.text = currentUserProfile.displayName ?? '';
        if (currentUserProfile.age != null) {
          _ageController.text = currentUserProfile.age.toString();
        }
        _selectedGender = currentUserProfile.gender ?? 'Other';
        _selectedInterests = List<String>.from(currentUserProfile.interests ?? []);
        _isDiscoverable = currentUserProfile.privateMode == true ? false : true;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _nameController.text.trim().isNotEmpty &&
            _ageController.text.trim().isNotEmpty &&
            int.tryParse(_ageController.text) != null &&
            int.parse(_ageController.text) >= 18;
      case 2:
        return _selectedInterests.length >= 3;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_canProceed()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserProfile = ref.read(currentUserProfileProvider).value;
      if (currentUserProfile == null) throw Exception('User not authenticated');

      String? photoUrl = currentUserProfile.photoUrl;
      if (_selectedPhoto != null) {
        final photoService = PhotoUploadService();
        photoUrl = await photoService.uploadProfilePhoto(_selectedPhoto!);
      }

      // Calculate birthday from age
      final age = int.parse(_ageController.text);
      final birthday = DateTime.now().subtract(Duration(days: age * 365));

      final profileService = ProfileService();
      final updatedProfile = UserProfile(
        id: currentUserProfile.id,
        email: currentUserProfile.email,
        displayName: _nameController.text.trim(),
        photoUrl: photoUrl,
        birthday: birthday,
        gender: _selectedGender,
        interests: _selectedInterests,
        privateMode: !_isDiscoverable,
        createdAt: currentUserProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      await profileService.updateUserProfile(updatedProfile);

      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete onboarding: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photoService = PhotoUploadService();
      final XFile? image = await photoService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedPhoto = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
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
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                ),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_currentStep + 1}/5',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentStep = index;
            });
          },
          children: [
            _buildWelcomeStep(),
            _buildBasicInfoStep(),
            _buildInterestsStep(),
            _buildPhotoStep(),
            _buildPreferencesStep(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: (_canProceed() && !_isLoading) ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      _currentStep == 4 ? 'Complete' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.waving_hand,
              size: 100,
              color: Color(0xFFFFD700),
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Mix & Mingle!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Let\'s set up your profile so you can start connecting with amazing people!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.favorite, 'Meet new people'),
                  const SizedBox(height: 16),
                  _buildFeatureItem(Icons.event, 'Join exciting events'),
                  const SizedBox(height: 16),
                  _buildFeatureItem(Icons.chat, 'Connect and chat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 24),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about yourself',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps others get to know you',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Your Name',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.person, color: Color(0xFFFFD700)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Your Age',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.cake, color: Color(0xFFFFD700)),
              helperText: 'Must be 18 or older',
              helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gender',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: ['Male', 'Female', 'Non-binary', 'Other'].map((gender) {
              final isSelected = _selectedGender == gender;
              return ChoiceChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    if (_interestsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = _interestsData!['categories'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you into?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 3 interests',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedInterests.length} selected',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...categories.map((category) {
            final categoryName = category['name'] as String;
            final interests = category['interests'] as List<dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...interests.map((interest) {
                      final interestStr = interest as String;
                      final isSelected = _selectedInterests.contains(interestStr);
                      return FilterChip(
                        label: Text(interestStr),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedInterests.add(interestStr);
                            } else {
                              _selectedInterests.remove(interestStr);
                            }
                          });
                        },
                        selectedColor: const Color(0xFFFFD700),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Add a profile photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Profiles with photos get 10x more matches!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 3,
                  ),
                ),
                child: _selectedPhoto != null
                    ? ClipOval(
                        child: Image.file(
                          File(_selectedPhoto!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        size: 80,
                        color: Color(0xFFFFD700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library),
              label: Text(_selectedPhoto != null ? 'Change Photo' : 'Choose Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPhoto = null;
                });
              },
              child: const Text(
                'Skip for now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy & Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control how others can find and interact with you',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Make profile discoverable',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isDiscoverable ? 'Others can find you in search and recommendations' : 'Your profile is private',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  value: _isDiscoverable,
                  activeThumbColor: const Color(0xFFFFD700),
                  onChanged: (value) {
                    setState(() {
                      _isDiscoverable = value;
                    });
                  },
                ),
                const Divider(color: Colors.white24),
                SwitchListTile(
                  title: const Text(
                    'Enable notifications',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _allowNotifications
                        ? 'Get notified about matches, messages, and events'
                        : 'You won\'t receive any notifications',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  value: _allowNotifications,
                  activeThumbColor: const Color(0xFFFFD700),
                  onChanged: (value) {
                    setState(() {
                      _allowNotifications = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'You can change these settings anytime in your profile settings.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
