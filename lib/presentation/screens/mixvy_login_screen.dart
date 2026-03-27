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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authControllerProvider);
        final isLoading = authState.isLoading;
        final error = authState.error;
        return Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 600;
              final isTablet = width >= 600 && width < 1024;
              double containerWidth = isMobile
                  ? double.infinity
                  : (isTablet ? 500 : 420);
              EdgeInsets containerMargin = isMobile
                  ? const EdgeInsets.symmetric(horizontal: 12)
                  : EdgeInsets.symmetric(
                      horizontal: (width - containerWidth) / 2,
                    );
              double formPadding = isMobile ? 16 : (isTablet ? 32 : 40);
              double titleFontSize = isMobile ? 24 : (isTablet ? 28 : 32);
              double inputFontSize = isMobile ? 15 : (isTablet ? 17 : 18);
              double buttonFontSize = isMobile ? 16 : (isTablet ? 18 : 20);
              double buttonPadding = isMobile ? 14 : (isTablet ? 18 : 20);
              double iconSize = isMobile ? 22 : (isTablet ? 26 : 28);
              return Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 24 : (isTablet ? 48 : 64),
                    ),
                    child: Container(
                      width: containerWidth,
                      margin: containerMargin,
                      padding: EdgeInsets.all(formPadding),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withAlpha((0.95 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign in to MixVy',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isMobile ? 24 : 32),
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: inputFontSize,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: inputFontSize,
                                ),
                                filled: true,
                                fillColor: Colors.grey[850],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.deepPurpleAccent,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.white54,
                                  size: iconSize,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter your email.';
                                }
                                final emailRegex = RegExp(
                                  r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}",
                                );
                                if (!emailRegex.hasMatch(v)) {
                                  return 'Enter a valid email.';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            SizedBox(height: isMobile ? 14 : 18),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: inputFontSize,
                              ),
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: inputFontSize,
                                ),
                                filled: true,
                                fillColor: Colors.grey[850],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.deepPurpleAccent,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.white54,
                                  size: iconSize,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white54,
                                    size: iconSize,
                                  ),
                                  onPressed: _togglePassword,
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter your password.';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(ref),
                            ),
                            SizedBox(height: isMobile ? 20 : 28),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.deepPurpleAccent,
                                        strokeWidth: isMobile ? 3 : 4,
                                      ),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.deepPurpleAccent,
                                        padding: EdgeInsets.symmetric(
                                          vertical: buttonPadding,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _login(ref),
                                      child: Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            // ...existing code for other widgets...
                            SizedBox(height: isMobile ? 12 : 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.of(context).pushNamed('/forgot-password');
                                        },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.of(context).pushNamed('/register');
                                        },
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 18 : 28),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white24)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'or',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white24)),
                              ],
                            ),
                            SizedBox(height: isMobile ? 10 : 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialLoginButton(
                                  icon: Icons.g_mobiledata,
                                  label: 'Sign in with Google',
                                  color: Colors.white,
                                  textColor: Colors.black,
                                  onTap: isLoading
                                      ? null
                                      : () async {
                                          final authController = ref.read(authControllerProvider.notifier);
                                          await authController.signInWithGoogle();
                                          if (!mounted) return;
                                          final authState = ref.read(authControllerProvider);
                                          if (authState.error != null) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    authState.error ?? '',
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            });
                                          }
                                        },
                                  fontSize: buttonFontSize,
                                  iconSize: iconSize,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 10 : 16,
                                    vertical: isMobile ? 10 : 14,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 10 : 16),
                                _SocialLoginButton(
                                  icon: Icons.apple,
                                  label: 'Sign in with Apple',
                                  color: Colors.black,
                                  textColor: Colors.white,
                                  onTap: isLoading ? null : () {},
                                  fontSize: buttonFontSize,
                                  iconSize: iconSize,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 10 : 16,
                                    vertical: isMobile ? 10 : 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              label: 'Login form',
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? padding;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
    this.fontSize,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: iconSize ?? 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize ?? 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
