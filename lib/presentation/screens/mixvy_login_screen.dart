import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/services/analytics_service.dart';

class MixVyLoginScreen extends StatefulWidget {
  const MixVyLoginScreen({super.key});

  @override
  State<MixVyLoginScreen> createState() => _MixVyLoginScreenState();
}

class _MixVyLoginScreenState extends State<MixVyLoginScreen>
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

  Future<void> _login(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    final authController = ref.read(authControllerProvider.notifier);
    await authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    final authState = ref.read(authControllerProvider);
    if (authState.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authState.error ?? '',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    if (authState.uid != null) {
      // Log login event
      await AnalyticsService().logLogin(method: 'email_password');
      if (mounted) {
        // Navigate to home or dashboard after successful login
        Navigator.of(context).pushReplacementNamed('/home');

      import 'package:flutter/material.dart';
      import 'package:flutter_riverpod/flutter_riverpod.dart';
      import 'package:firebase_auth/firebase_auth.dart';

      class MixvyLoginScreen extends ConsumerStatefulWidget {
        const MixvyLoginScreen({super.key});

        @override
        ConsumerState<MixvyLoginScreen> createState() => _MixvyLoginScreenState();
      }

      class _MixvyLoginScreenState extends ConsumerState<MixvyLoginScreen> {
        final _formKey = GlobalKey<FormState>();

        final TextEditingController _emailController = TextEditingController();
        final TextEditingController _passwordController = TextEditingController();

        bool _isLoading = false;

        @override
        void dispose() {
          _emailController.dispose();
          _passwordController.dispose();
          super.dispose();
        }

        Future<void> _login() async {
          if (!_formKey.currentState!.validate()) return;

          setState(() => _isLoading = true);

          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Login successful")),
            );

            // TODO: Navigate to home screen
            // Navigator.pushReplacementNamed(context, '/home');

          } on FirebaseAuthException catch (e) {
            if (!mounted) return;

            String message = "Login failed";

            if (e.code == 'user-not-found') {
              message = "No user found for that email.";
            } else if (e.code == 'wrong-password') {
              message = "Wrong password.";
            } else if (e.code == 'invalid-email') {
              message = "Invalid email format.";
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
            );
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        }

        @override
        Widget build(BuildContext context) {
          final width = MediaQuery.of(context).size.width;

          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width > 500 ? 400 : width,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "MixVy Login",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // EMAIL
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // PASSWORD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return "Minimum 6 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 25),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Login"),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // FIXED ROW (NO OVERFLOW)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to signup
                              },
                              child: const Text("Sign up"),
                            ),
                          ],
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
                                ),
