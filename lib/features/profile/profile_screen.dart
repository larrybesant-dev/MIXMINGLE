import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  // Remove local loading/error, use ProfileState

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final controller = ref.read(profileControllerProvider.notifier);
    await controller.updateProfile(
      ref.read(profileControllerProvider).copyWith(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
    if (!mounted) return;
    final state = ref.read(profileControllerProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Name input field',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Email input field',
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  textInputAction: TextInputAction.done,
                ),
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
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
              // ...existing code...
            ],
          ),
        ),
      ),
    );
  }
}
