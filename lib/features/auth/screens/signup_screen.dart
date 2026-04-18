import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mixvy/core/layout/app_layout.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/shared/widgets/app_page_scaffold.dart';
import 'package:mixvy/services/analytics_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AppPageScaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: EdgeInsets.all(context.pageHorizontalPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset(
                'assets/images/branding/mixvy_logo.png',
                height: 72,
                semanticLabel: 'MixVy logo',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(label: Text("Username")),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return "Enter username";
                  if (value.length < 3) return "Username too short";
                  return null;
                },
              ),
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
                onPressed: authState.isLoading ? null : _signup,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up"),
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
      ),
    );
  }

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() != true) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.signup(
      _email.text.trim(),
      _password.text.trim(),
      _username.text.trim(),
    );
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.error == null) {
      // Log signup event
      await AnalyticsService().logEvent('signup', params: {'method': 'email_password'});
      if (!mounted) return;
      await Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
