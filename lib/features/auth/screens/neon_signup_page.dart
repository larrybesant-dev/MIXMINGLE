  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_analytics/firebase_analytics.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../../core/theme/neon_colors.dart';
  import '../../../core/analytics/analytics_events.dart';
  import '../../../core/routing/app_routes.dart';
  import '../../../shared/widgets/neon_components.dart';
  import '../providers/age_gate_provider.dart';

  int _onboardingStep = 1;
  bool _showWelcomeOverlay = false;

/// ============================================================================
/// NEON SIGNUP SCREEN - Electric Lounge Brand
/// Dark theme with neon styling, logo branding
/// ============================================================================

class NeonSignupPage extends ConsumerStatefulWidget {
  const NeonSignupPage({super.key});

  @override
  ConsumerState<NeonSignupPage> createState() => _NeonSignupPageState();
}

class _NeonSignupPageState extends ConsumerState<NeonSignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If the age gate hasn't been passed (e.g. direct navigation attempt),
    // redirect back to the age gate screen.
    final ageGateState = ref.read(ageGateProvider);
    if (!ageGateState.isVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.ageGate);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user account
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Retrieve verified birthdate from age gate provider
      final ageGateState = ref.read(ageGateProvider);
      final birthdate    = ageGateState.birthdate;
      final ageAtSignup  = ageGateState.computedAge;

      // Create user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'displayName': _usernameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageUrl': '',
        'bio': '',
        'isVerified': false,
        // ── 18+ AGE GATE ──────────────────────────────────────
        'ageVerified': true,
        if (birthdate != null) 'birthdate': Timestamp.fromDate(birthdate),
        if (ageAtSignup != null) 'ageAtSignup': ageAtSignup,
      });

      // Log analytics event
      await FirebaseAnalytics.instance.logEvent(
        name: AnalyticsEvents.userSignup18Plus,
        parameters: {
          if (ageAtSignup != null) 'age_at_signup': ageAtSignup,
        },
      );

      // Reset age gate session state after successful account creation
      ref.read(ageGateProvider.notifier).reset();

      debugPrint('âœ… [Signup] Account created. Navigating to /app...');
      if (mounted) {
        setState(() {
          _showWelcomeOverlay = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/app',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Signup failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        // Onboarding progress indicator
        final Widget progressBar = Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(
            value: _onboardingStep / 3,
            backgroundColor: NeonColors.darkBg2,
            valueColor: const AlwaysStoppedAnimation(NeonColors.neonBlue),
          ),
        );
    return Stack(
      children: [
        Scaffold(
          backgroundColor: NeonColors.darkBg,
          body: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NeonColors.darkBg2.withValues(alpha: 0.8),
                    NeonColors.darkBg,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo section
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                      _buildLogoSection(),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                      progressBar,
                      // Signup form
                      NeonGlowCard(
                        glowColor: NeonColors.neonPurple,
                        glowRadius: 20,
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            const NeonText(
                              'JOIN THE PARTY',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              textColor: Colors.white,
                              glowColor: NeonColors.neonBlue,
                              glowRadius: 10,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your MIXVY account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: NeonColors.textSecondary,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: NeonColors.errorRed.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: NeonColors.errorRed,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: NeonColors.errorRed,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: NeonColors.errorRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_errorMessage != null) const SizedBox(height: 16),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Username field
                                  NeonInputField(
                                    controller: _usernameController,
                                    hint: 'Choose a username',
                                    label: 'Username',
                                    prefixIcon: Icons.person_outline,
                                    focusGlowColor: NeonColors.neonBlue,
                                  ),
                                  const SizedBox(height: 16),

                                  // Email field
                                  NeonInputField(
                                    controller: _emailController,
                                    hint: 'Enter your email',
                                    label: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    focusGlowColor: NeonColors.neonBlue,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  _buildPasswordField(),
                                  const SizedBox(height: 16),

                                  // Confirm password field
                                  _buildConfirmPasswordField(),
                                  const SizedBox(height: 24),

                                  // Sign up button
                                  NeonButton(
                                    label:
                                        _isLoading ? 'CREATING ACCOUNT...' : 'SIGN UP',
                                    onPressed: _handleSignup,
                                    glowColor: NeonColors.neonBlue,
                                    isLoading: _isLoading,
                                    height: 54,
                                  ),

                                  const SizedBox(height: 20),

                                  // Terms agreement
                                  _buildTermsCheckbox(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            NeonDivider(
                              startColor:
                                  NeonColors.neonBlue.withValues(alpha: 0.2),
                              endColor:
                                  NeonColors.neonPurple.withValues(alpha: 0.2),
                              height: 1.5,
                            ),

                            const SizedBox(height: 24),

                            // Sign in link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: NeonColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.of(context).pushNamed('/login'),
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      color: NeonColors.neonOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_showWelcomeOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeonText(
                      'Welcome to MIXVY!',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      textColor: NeonColors.neonBlue,
                      glowColor: NeonColors.neonPurple,
                      glowRadius: 16,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your account is ready. Let’s get started!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: NeonColors.neonBlue.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: NeonColors.neonPurple.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeonColors.neonBlue.withValues(alpha: 0.15),
                    NeonColors.neonPurple.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: NeonColors.neonBlue.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Image.asset(
                'assets/brand/png/app_icon/mixvy_icon_96x96.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          NeonColors.neonBlue,
                          NeonColors.neonPurple,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const NeonText(
          'MIXVY',
          fontSize: 24,
          fontWeight: FontWeight.w900,
          textColor: Colors.white,
          glowColor: NeonColors.neonBlue,
          glowRadius: 10,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Material(
      color: NeonColors.darkCard,
      borderRadius: BorderRadius.circular(12),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: NeonColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: NeonColors.divider,
                width: 1.5,
              ),
            ),
          ),
        ),
        child: TextField(
          controller: _passwordController,
          obscureText: _hidePassword,
          style: const TextStyle(
            color: NeonColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            labelText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: NeonColors.neonBlue,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _hidePassword ? Icons.visibility_off : Icons.visibility,
                color: NeonColors.neonBlue,
              ),
              onPressed: () {
                setState(() => _hidePassword = !_hidePassword);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Material(
      color: NeonColors.darkCard,
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: _confirmPasswordController,
        obscureText: _hideConfirmPassword,
        style: const TextStyle(
          color: NeonColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Confirm your password',
          labelText: 'Confirm Password',
          prefixIcon: const Icon(
            Icons.lock_outlined,
            color: NeonColors.neonBlue,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: NeonColors.neonBlue,
            ),
            onPressed: () {
              setState(() => _hideConfirmPassword = !_hideConfirmPassword);
            },
          ),
          filled: true,
          fillColor: NeonColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: NeonColors.divider,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: NeonColors.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: NeonColors.neonBlue,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            fillColor: WidgetStateProperty.resolveWith<Color>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return NeonColors.neonBlue;
                }
                return NeonColors.darkCard;
              },
            ),
            side: const BorderSide(
              color: NeonColors.neonBlue,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      color: NeonColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: NeonColors.neonBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    // Add tap handler if needed
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(
                      color: NeonColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: NeonColors.neonBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
