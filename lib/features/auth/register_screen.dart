import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/services/analytics_service.dart';

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
    if (_formKey.currentState?.validate() != true) return;
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

  Future<void> _signInWithGoogle() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signInWithGoogle();
    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    setState(() {
      _localError = authState.error;
    });
    if (authState.error == null && authState.uid != null) {
      await AnalyticsService().logLogin(method: 'google');
      if (!mounted) return;
      context.go('/');
    }
  }

  Future<void> _signInWithApple() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signInWithApple();
    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    setState(() {
      _localError = authState.error;
    });
    if (authState.error == null && authState.uid != null) {
      await AnalyticsService().logLogin(method: 'apple');
      if (!mounted) return;
      context.go('/');
    }
  }

  bool _supportsAppleSignIn() {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 120),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.person_add_alt_1, size: 52, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Create your MixVy account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your account now, then complete your profile and start matching instantly.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Email input field',
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
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
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
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
                            : const Text('Register'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or continue with'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  if (_supportsAppleSignIn()) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _signInWithApple,
                        icon: const Icon(Icons.apple),
                        label: const Text('Continue with Apple'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Login navigation button',
                    button: true,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/login'),
                      child: const Text('Already have an account? Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
