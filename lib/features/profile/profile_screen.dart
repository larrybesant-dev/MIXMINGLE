import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // Remove local loading/error, use ProfileState

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
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    if (_nameController.text.isEmpty && state.username != null) {
      _nameController.text = state.username!;
    }
    if (_emailController.text.isEmpty && state.email != null) {
      _emailController.text = state.email!;
    }

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
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a display name';
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
                    if (value == null || value.trim().isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
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
                  onPressed: state.isLoading ? null : _saveProfile,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
