import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(label: Text("Email")),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter email" : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(label: Text("Password")),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter password" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _signup,
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up"),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.error ?? '',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .signup(_email.text.trim(), _password.text.trim());

    final state = ref.read(authControllerProvider);

    if (state.error == null && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
