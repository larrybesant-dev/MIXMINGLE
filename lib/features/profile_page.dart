import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/profile_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestsController = TextEditingController();

  String _gender = 'Not specified';
  DateTime? _birthday;
  List<String> _interests = [];
  List<String> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileAsync = ref.read(currentUserProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        _displayNameController.text = profile.displayName ?? '';
        _bioController.text = profile.bio ?? '';
        _ageController.text = profile.age?.toString() ?? '';
        _locationController.text = profile.location ?? '';
        _gender = profile.gender ?? 'Not specified';
        _birthday = profile.birthday;
        _interests = List.from(profile.interests ?? []);
        _photos = List.from(profile.photos);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentProfile = ref.read(currentUserProfileProvider).value;
      if (currentProfile == null) return;

      final updatedProfile = currentProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        birthday: _birthday ?? currentProfile.birthday,
        gender: _gender,
        interests: _interests,
        location: _locationController.text.trim(),
        galleryPhotos: _photos,
        updatedAt: DateTime.now(),
      );

      await ref.read(profileControllerProvider).updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  void _addInterest() {
    final interest = _interestsController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestsController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() => _interests.remove(interest));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => profile == null
            ? const Center(child: Text('No profile found'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photos Section
                      const Text('Profile Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _photos.length) {
                              return Card(
                                child: InkWell(
                                  onTap: () {
                                    // TODO: Implement photo picker
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Photo picker not implemented yet')),
                                    );
                                  },
                                  child: const SizedBox(
                                    width: 100,
                                    child: Icon(Icons.add_a_photo, size: 40),
                                  ),
                                ),
                              );
                            }
                            return Card(
                              child: Stack(
                                children: [
                                  Image.network(
                                    _photos[index],
                                    width: 100,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 40),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() => _photos.removeAt(index));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Basic Information
                      const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                          hintText: 'Tell others about yourself...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final age = int.tryParse(value ?? '');
                                if (age == null || age < 18 || age > 120) {
                                  return 'Please enter a valid age (18-120)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Not specified', 'Male', 'Female', 'Non-binary', 'Other']
                                  .map((gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _gender = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _selectBirthday,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Birthday',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _birthday != null ? DateFormat('MMM dd, yyyy').format(_birthday!) : 'Select birthday',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          hintText: 'City, Country',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interests Section
                      const Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _interestsController,
                              decoration: const InputDecoration(
                                labelText: 'Add interest',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., hiking, cooking, music',
                              ),
                              onSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addInterest,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _interests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            onDeleted: () => _removeInterest(interest),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
