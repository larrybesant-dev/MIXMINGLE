import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  final _vibeController = TextEditingController();
  final _firstDateController = TextEditingController();
  final _musicTasteController = TextEditingController();
  String? _loadedUserId;
  bool _isUploadingPhoto = false;
  bool _isUploadingVideo = false;
  bool _isUploadingGallery = false;
  static const int _maxPhotoBytes = 20 * 1024 * 1024;
  static const int _maxVideoBytes = 120 * 1024 * 1024;

  double _profileCompleteness(ProfileState state) {
    var score = 0;
    if ((state.username ?? '').trim().length >= 2) score++;
    if ((state.avatarUrl ?? '').trim().isNotEmpty) score++;
    if ((state.bio ?? '').trim().isNotEmpty) score++;
    if (state.interests.isNotEmpty) score++;
    if ((state.introVideoUrl ?? '').trim().isNotEmpty) score++;
    return score / 5;
  }

  Future<void> _openIntroVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid intro video URL.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open intro video.')),
      );
    }
  }

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
    _bioController.dispose();
    _interestsController.dispose();
    _vibeController.dispose();
    _firstDateController.dispose();
    _musicTasteController.dispose();
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
    final userId = state.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to upload a photo.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (file == null) return;

      final photoSize = await file.length();
      if (photoSize > _maxPhotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is too large. Choose one under 20MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);

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
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      final message = switch (code) {
        'unauthenticated' || 'permission-denied' => 'Upload blocked. Please sign in again and retry.',
        'object-not-found' => 'Storage path not found. Please retry.',
        'quota-exceeded' => 'Storage quota exceeded. Please try again later.',
        'unauthorized' => 'Not allowed to upload this file. Please retry with a different photo.',
        _ => 'Photo upload failed: ${e.message ?? e.code}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final userId = state.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to upload a video.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 45));
      if (file == null) return;

      final videoSize = await file.length();
      if (videoSize > _maxVideoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is too large. Choose one under 120MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isUploadingVideo = true);

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

  Future<void> _uploadGalleryPhoto() async {
    if (_isUploadingGallery) return;
    final state = ref.read(profileControllerProvider);
    final userId = state.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to upload a gallery photo.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (file == null) return;

      final photoSize = await file.length();
      if (photoSize > _maxPhotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is too large. Choose one under 20MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isUploadingGallery = true);

      final bytes = await file.readAsBytes();
      final photoUrl = await _uploadToStorage(
        bytes: bytes,
        userId: userId,
        folder: 'gallery_photos',
        extension: 'jpg',
        contentType: 'image/jpeg',
      );

      final controller = ref.read(profileControllerProvider.notifier);
      final current = ref.read(profileControllerProvider);
      final updatedGallery = [...current.galleryUrls, photoUrl].toSet().toList();
      await controller.updateProfile(current.copyWith(galleryUrls: updatedGallery));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery photo uploaded.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery upload failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
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
    _bioController.text = state.bio ?? '';
    _interestsController.text = state.interests.join(', ');
    _vibeController.text = state.vibePrompt ?? '';
    _firstDateController.text = state.firstDatePrompt ?? '';
    _musicTasteController.text = state.musicTastePrompt ?? '';
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
        bio: _bioController.text.trim(),
        interests: _parseInterests(_interestsController.text),
        vibePrompt: _vibeController.text.trim(),
        firstDatePrompt: _firstDateController.text.trim(),
        musicTastePrompt: _musicTasteController.text.trim(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: (state.avatarUrl != null && state.avatarUrl!.trim().isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                state.avatarUrl!.trim(),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 32),
                              ),
                            )
                          : const Icon(Icons.person, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (state.username ?? '').trim().isEmpty ? 'Your profile' : state.username!.trim(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _profileCompleteness(state),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profile strength ${(100 * _profileCompleteness(state)).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Followers',
                            value: '${state.followers.length}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'Coins',
                            value: '${state.coinBalance}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'Interests',
                            value: '${state.interests.length}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text('Identity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
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
              const SizedBox(height: 18),

              Text('Media', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
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
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (state.isLoading || _isUploadingGallery) ? null : _uploadGalleryPhoto,
                icon: _isUploadingGallery
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.collections_outlined),
                label: Text(_isUploadingGallery ? 'Uploading to gallery...' : 'Add gallery photo'),
              ),
              if (state.galleryUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.galleryUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final url = state.galleryUrls[index].trim();
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 88,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (state.introVideoUrl?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(child: Text('Intro video uploaded.')),
                      TextButton(
                        onPressed: () => _openIntroVideo(state.introVideoUrl!.trim()),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),

              Text('About You', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _vibeController,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Your vibe',
                  hintText: 'Late-night talks, rooftop playlists, city walks',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _firstDateController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Ideal first date',
                  hintText: 'Coffee + arcade + sunset',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _musicTasteController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Music taste',
                  hintText: 'Afrobeats, R&B, house, hip-hop',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              if (state.interests.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.interests
                      .take(8)
                      .map((interest) => Chip(label: Text(interest), side: BorderSide.none))
                      .toList(),
                ),
              if (state.interests.isNotEmpty) const SizedBox(height: 16),
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
                child: FilledButton(
                  onPressed: state.isLoading ? null : _saveProfile,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
