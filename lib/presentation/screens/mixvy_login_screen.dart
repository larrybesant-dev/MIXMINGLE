import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/services/analytics_service.dart';

class MixVyLoginScreen extends ConsumerStatefulWidget {
  const MixVyLoginScreen({super.key});

  @override
  ConsumerState<MixVyLoginScreen> createState() => _MixVyLoginScreenState();
}

class _MixVyLoginScreenState extends ConsumerState<MixVyLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _showMessage(String message, {bool isError = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Read all necessary values before starting async operations
    final authController = ref.read(authControllerProvider.notifier);
    
    await authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    
    // Check if widget is still mounted before accessing ref or context
    if (!mounted) return;
    
    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      await _showMessage(authState.error ?? '', isError: true);
    }
    if (authState.uid != null && mounted) {
      // Log login event
      await AnalyticsService().logLogin(method: 'email_password');
      if (mounted) {
        // Navigate to home or dashboard after successful login
        context.go('/');
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      await _showMessage('Enter your email first to reset password', isError: true);
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    await authController.resetPassword(email);

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      await _showMessage(authState.error ?? '', isError: true);
      return;
    }

    await _showMessage('Password reset email sent');
  }

  Future<void> _signInWithGoogle() async {
    final authController = ref.read(authControllerProvider.notifier);
    await authController.signInWithGoogle();

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      await _showMessage(authState.error ?? '', isError: true);
      return;
    }

    if (authState.uid != null) {
      await AnalyticsService().logLogin(method: 'google');
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: _togglePassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: authState.isLoading ? null : _resetPassword,
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => context.go('/register'),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
