import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(label: Text('Email')),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(label: Text('Password')),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _login,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              if (authState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  authState.error ?? '',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.login(_emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.error == null) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
