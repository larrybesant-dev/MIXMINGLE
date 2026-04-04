import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _profilePictureUrlController = TextEditingController();
  bool _showPassword = false;

  bool _isValidImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && (uri.host.isNotEmpty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _profilePictureUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileControllerProvider);
    _nameController.text = state.username ?? '';
    _emailController.text = state.email ?? '';
    _profilePictureUrlController.text = state.avatarUrl ?? '';
  }

  Future<void> _saveProfile() async {
    final profilePictureUrl = _profilePictureUrlController.text.trim();
    if (profilePictureUrl.isNotEmpty && !_isValidImageUrl(profilePictureUrl)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Picture URL must be a valid http/https link.')),
      );
      return;
    }

    final controller = ref.read(profileControllerProvider.notifier);
    await controller.updateProfile(
      ref.read(profileControllerProvider).copyWith(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        avatarUrl: profilePictureUrl,
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
    final profilePictureUrl = _profilePictureUrlController.text.trim();
    final hasValidProfilePicture = _isValidImageUrl(profilePictureUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: hasValidProfilePicture
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profilePictureUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _profilePictureUrlController,
                decoration: const InputDecoration(labelText: 'Profile Picture URL'),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
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
