import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_analytics/firebase_analytics.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../../core/theme/neon_colors.dart';
  import '../../../core/analytics/analytics_events.dart';
  import '../../../shared/providers/auth_providers.dart';
  import '../../../shared/widgets/neon_components.dart';
  import '../providers/age_gate_provider.dart';
  import '../../../providers/all_providers.dart';
  import '../../../shared/widgets/loading_widgets.dart';

  // Removed duplicate top-level variables

/// ============================================================================
/// NEON SIGNUP SCREEN - Electric Lounge Brand
/// Dark theme with neon styling, logo branding
/// ============================================================================
class NeonSignupPage extends ConsumerWidget {
  const NeonSignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Completing onboarding...'),
      error: (_, __) => const FullScreenLoader(message: 'Onboarding error'),
      data: (profile) {
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
                        children: [
                          SizedBox(height: 40),
                          _buildLogoSection(),
                          SizedBox(height: 40),
                          progressBar,
                          NeonGlowCard(
                            glowColor: NeonColors.neonPurple,
                            glowRadius: 20,
                            borderRadius: 20,
                            child: Column(
                              children: [
                                NeonText(
                                  'JOIN THE PARTY',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  textColor: Colors.white,
                                  glowColor: NeonColors.neonBlue,
                                  glowRadius: 10,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create your MIXVY account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: NeonColors.textSecondary,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 32),
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
                                        Icon(
                                          Icons.error_outline,
                                          color: NeonColors.errorRed,
                                          size: 18,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: NeonColors.errorRed,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_errorMessage != null) SizedBox(height: 16),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      NeonInputField(
                                        controller: _usernameController,
                                        hint: 'Choose a username',
                                        label: 'Username',
                                        prefixIcon: Icons.person_outline,
                                        focusGlowColor: NeonColors.neonBlue,
                                      ),
                                      SizedBox(height: 16),
                                      NeonInputField(
                                        controller: _emailController,
                                        hint: 'Enter your email',
                                        label: 'Email',
                                        prefixIcon: Icons.email_outlined,
                                        focusGlowColor: NeonColors.neonBlue,
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                      SizedBox(height: 16),
                                      _buildPasswordField(),
                                      SizedBox(height: 16),
                                      _buildConfirmPasswordField(),
                                      SizedBox(height: 24),
                                      NeonButton(
                                        label:
                                            _isLoading ? 'CREATING ACCOUNT...' : 'SIGN UP',
                                        onPressed: _handleSignup,
                                        glowColor: NeonColors.neonBlue,
                                        isLoading: _isLoading,
                                        height: 54,
                                      ),
                                      SizedBox(height: 20),
                                      _buildTermsCheckbox(),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                NeonDivider(
                                  startColor:
                                      NeonColors.neonBlue.withValues(alpha: 0.2),
                                  endColor:
                                      NeonColors.neonPurple.withValues(alpha: 0.2),
                                  height: 1.5,
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        color: NeonColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          Navigator.of(context).pushNamed('/login'),
                                      child: Text(
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
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
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
            if (_isLoading)
              const LoadingOverlay(isLoading: true, child: SizedBox.shrink()),
          ],
        );
      },
    );
  }

  // Widget builder helpers
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
        SizedBox(height: 12),
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
        SizedBox(width: 12),
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

  // Synchronous signup handler
  void _handleSignup() {
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'You must agree to the Terms of Service.';
      });
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _handleSignupAsync(() {
        setState(() {
          _showWelcomeOverlay = true;
        });
      }).then((_) async {
        // After onboarding completion:
        await ref.invalidate(currentUserProfileProvider); // Invalidate after onboarding
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          });
        }
      }).catchError((error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      });
    }
  }

  // Widget builder helpers are defined below (actual methods, not fragments)

  // Async signup logic
  Future<void> _handleSignupAsync(VoidCallback showOverlay) async {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    final ageGateState = ref.read(ageGateProvider);
    final birthdate = ageGateState.birthdate;
    final ageAtSignup = ageGateState.computedAge;
    await FirebaseFirestore.instance
      .collection('users')
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
                      children: [
                        SizedBox(height: 40),
                        _buildLogoSection(),
                        SizedBox(height: 40),
                        progressBar,
                        NeonGlowCard(
                          glowColor: NeonColors.neonPurple,
                          glowRadius: 20,
                          borderRadius: 20,
                          child: Column(
                            children: [
                              NeonText(
                                'JOIN THE PARTY',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                textColor: Colors.white,
                                glowColor: NeonColors.neonBlue,
                                glowRadius: 10,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create your MIXVY account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: NeonColors.textSecondary,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 32),
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
                                      Icon(
                                        Icons.error_outline,
                                        color: NeonColors.errorRed,
                                        size: 18,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: NeonColors.errorRed,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_errorMessage != null) SizedBox(height: 16),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    NeonInputField(
                                      controller: _usernameController,
                                      hint: 'Choose a username',
                                      label: 'Username',
                                      prefixIcon: Icons.person_outline,
                                      focusGlowColor: NeonColors.neonBlue,
                                    ),
                                    SizedBox(height: 16),
                                    NeonInputField(
                                      controller: _emailController,
                                      hint: 'Enter your email',
                                      label: 'Email',
                                      prefixIcon: Icons.email_outlined,
                                      focusGlowColor: NeonColors.neonBlue,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    SizedBox(height: 16),
                                    _buildPasswordField(),
                                    SizedBox(height: 16),
                                    _buildConfirmPasswordField(),
                                    SizedBox(height: 24),
                                    NeonButton(
                                      label:
                                          _isLoading ? 'CREATING ACCOUNT...' : 'SIGN UP',
                                      onPressed: _handleSignup,
                                      glowColor: NeonColors.neonBlue,
                                      isLoading: _isLoading,
                                      height: 54,
                                    ),
                                    SizedBox(height: 20),
                                    _buildTermsCheckbox(),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              NeonDivider(
                                startColor:
                                    NeonColors.neonBlue.withValues(alpha: 0.2),
                                endColor:
                                    NeonColors.neonPurple.withValues(alpha: 0.2),
                                height: 1.5,
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: NeonColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.of(context).pushNamed('/login'),
                                    child: Text(
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
            if (_showWelcomeOverlay)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
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
            if (_isLoading)
              const LoadingOverlay(isLoading: true, child: SizedBox.shrink()),
        ],
      );
    }
  }

  Future<void> _completeOnboarding(WidgetRef ref) async {
    // After onboarding mutation:
    ref.invalidate(currentUserProfileProvider); // Force reload profile
    final profile = await ref.read(currentUserProfileProvider.future);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, AppRoutes.home);
    });
  }
}
