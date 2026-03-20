import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/auth/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(label: Text("Email")),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _reset,
              child: authState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Send Reset Email"),
            ),
            if (authState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  authState.error ?? '',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reset() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.resetPassword(_email.text.trim());
  }
}
