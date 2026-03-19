import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // TODO: Implement profile update logic
    await Future.delayed(const Duration(seconds: 1)); // Placeholder
    setState(() {
      _isLoading = false;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
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
                if (_error != null)
                  Semantics(
                    label: 'Error message',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Semantics(
                  label: 'Save profile button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Save', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
