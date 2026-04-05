import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isUploadingPhoto = false;
  String? _avatarUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileControllerProvider);
    _nameController.text = state.username ?? '';
    _emailController.text = state.email ?? '';
    _avatarUrl = state.avatarUrl;
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final ref = FirebaseStorage.instance.ref('users/$uid/avatar.$ext');
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      if (mounted) setState(() => _avatarUrl = url);
    } catch (e, st) {
      developer.log('Avatar upload failed', name: 'EditProfile', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    final controller = ref.read(profileControllerProvider.notifier);
    await controller.updateProfile(
      ref.read(profileControllerProvider).copyWith(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        avatarUrl: _avatarUrl ?? '',
      ),
    );
    if (!mounted) return;
    final state = ref.read(profileControllerProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.pop();
    }
  }

  void _cancel() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture — tap to upload
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: _isUploadingPhoto
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _avatarUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, url, error) => Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to change photo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Private account'),
                subtitle: Text(
                  state.privacy.isPrivate
                      ? 'Only followers can view your profile'
                      : 'Anyone can view your profile',
                ),
                value: state.privacy.isPrivate,
                onChanged: (val) {
                  ref.read(profileControllerProvider.notifier).updateDraft(
                    state.copyWith(
                      privacy: state.privacy.copyWith(isPrivate: val),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _saveProfile,
                    child: state.isLoading ? const CircularProgressIndicator() : const Text('Save'),
                  ),
                  OutlinedButton(
                    onPressed: state.isLoading ? null : _cancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
