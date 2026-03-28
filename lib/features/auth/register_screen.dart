import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!_formKey.currentState!.validate()) return;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _localError = 'Email and password are required.';
      });
      return;
    }
    setState(() {
      _localError = null;
    });
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signup(email, password);
    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    setState(() {
      _localError = authState.error;
    });
    if (authState.error == null && authState.uid != null) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Email input field',
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Password input field',
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(height: 24),
                if (_localError != null || authState.error != null)
                  Semantics(
                    label: 'Error message',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _localError ?? authState.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Semantics(
                  label: 'Register button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Register',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 400
                                  ? 20
                                  : 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Login navigation button',
                  button: true,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go('/login'),
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 400
                            ? 16
                            : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
