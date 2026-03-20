import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
// Removed unused imports

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

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
        _error = 'Email and password are required.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.signup(email, password);
      setState(() {
        _isLoading = false;
        _error = ref.read(authControllerProvider).error;
      });
      if (_error == null) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_error != null)
                    Semantics(
                      label: 'Error message',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Semantics(
                    label: 'Register button',
                    button: true,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Register', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
                    ),
                  ),
                const SizedBox(height: 16),
                  Semantics(
                    label: 'Login navigation button',
                    button: true,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed('/login'),
                      child: Text('Already have an account? Login', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 16 : 14)),
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
