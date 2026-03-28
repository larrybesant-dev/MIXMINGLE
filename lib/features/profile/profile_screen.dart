import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_controller.dart';


class ProfileScreen extends StatelessWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const SafeArea(child: ProfileFormView()),
    );
  }
}

class ProfileFormView extends ConsumerStatefulWidget {
  const ProfileFormView({super.key});

  @override
  ConsumerState<ProfileFormView> createState() => _ProfileFormViewState();
}

class _ProfileFormViewState extends ConsumerState<ProfileFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  String? _loadedUserId;
  bool _isUploadingPhoto = false;
  bool _isUploadingVideo = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).loadCurrentProfile(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<String> _uploadToStorage({
    required Uint8List bytes,
    required String userId,
    required String folder,
    required String extension,
    required String contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$userId/$folder/$timestamp.$extension';
    final ref = FirebaseStorage.instance.ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<void> _uploadPhoto() async {
    if (_isUploadingPhoto) return;
    final state = ref.read(profileControllerProvider);
    final userId = state.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to upload a photo.')),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final photoUrl = await _uploadToStorage(
        bytes: bytes,
        userId: userId,
        folder: 'profile_photos',
        extension: 'jpg',
        contentType: 'image/jpeg',
      );

      final controller = ref.read(profileControllerProvider.notifier);
      final current = ref.read(profileControllerProvider);
      await controller.updateProfile(current.copyWith(avatarUrl: photoUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo uploaded.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_isUploadingVideo) return;
    final state = ref.read(profileControllerProvider);
    final userId = state.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to upload a video.')),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 45));
    if (file == null) return;

    setState(() => _isUploadingVideo = true);
    try {
      final bytes = await file.readAsBytes();
      final videoUrl = await _uploadToStorage(
        bytes: bytes,
        userId: userId,
        folder: 'intro_videos',
        extension: 'mp4',
        contentType: 'video/mp4',
      );

      final controller = ref.read(profileControllerProvider.notifier);
      final current = ref.read(profileControllerProvider);
      await controller.updateProfile(current.copyWith(introVideoUrl: videoUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intro video uploaded.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
      }
    }
  }

  List<String> _parseInterests(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  void _hydrateForm(ProfileState state) {
    if (state.userId == null || state.userId == _loadedUserId) {
      return;
    }
    _loadedUserId = state.userId;
    _nameController.text = state.username ?? '';
    _emailController.text = state.email ?? '';
    _bioController.text = state.bio ?? '';
    _interestsController.text = state.interests.join(', ');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(profileControllerProvider.notifier);
    final current = ref.read(profileControllerProvider);
    await controller.updateProfile(
      current.copyWith(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
        interests: _parseInterests(_interestsController.text),
      ),
    );
    if (!mounted) return;
    final state = ref.read(profileControllerProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    _hydrateForm(state);

    if (state.isLoading && state.userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Name input field',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final normalized = (value ?? '').trim();
                    if (normalized.isEmpty) {
                      return 'Please enter a display name';
                    }
                    if (normalized.length < 2) {
                      return 'Display name must be at least 2 characters';
                    }
                    if (normalized.length > 30) {
                      return 'Display name must be 30 characters or less';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Email input field',
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final normalized = (value ?? '').trim();
                    if (normalized.isEmpty || !normalized.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: (state.avatarUrl != null && state.avatarUrl!.isNotEmpty)
                        ? NetworkImage(state.avatarUrl!)
                        : null,
                    child: (state.avatarUrl == null || state.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (state.isLoading || _isUploadingPhoto) ? null : _uploadPhoto,
                      icon: _isUploadingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(_isUploadingPhoto ? 'Uploading photo...' : 'Upload profile photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: (state.isLoading || _isUploadingVideo) ? null : _uploadVideo,
                icon: _isUploadingVideo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.videocam_outlined),
                label: Text(
                  _isUploadingVideo
                      ? 'Uploading video...'
                      : (state.introVideoUrl?.isNotEmpty == true ? 'Replace intro video' : 'Upload intro video'),
                ),
              ),
              if (state.introVideoUrl?.isNotEmpty == true)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Intro video uploaded.'),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  hintText: 'Tell people about yourself',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _interestsController,
                decoration: const InputDecoration(
                  labelText: 'Interests (optional)',
                  hintText: 'music, gaming, travel',
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final interests = _parseInterests(value ?? '');
                  if (interests.length > 8) {
                    return 'Add up to 8 interests';
                  }
                  final hasTooLong = interests.any((interest) => interest.length > 24);
                  if (hasTooLong) {
                    return 'Each interest must be 24 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (state.error != null)
                Semantics(
                  label: 'Error message',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
              Semantics(
                label: 'Save profile button',
                button: true,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _saveProfile,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Save and Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
