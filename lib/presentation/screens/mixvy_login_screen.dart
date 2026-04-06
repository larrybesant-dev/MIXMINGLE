import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/services/analytics_service.dart';

// ── colour aliases for this screen ───────────────────────────────────────────
const _surface        = Color(0xFF0B0E14);
const _surfaceHighest = Color(0xFF22262F);
const _primary        = Color(0xFFBA9EFF);
const _primaryDim     = Color(0xFF8455EF);
const _secondary      = Color(0xFF00E3FD);
const _onSurface      = Color(0xFFECEDF6);
const _onVariant      = Color(0xFFA9ABB3);
const _ghostBorder    = Color(0x1A73757D);

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

  void _togglePassword() => setState(() => _obscurePassword = !_obscurePassword);

  Future<void> _showMessage(String message, {bool isError = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFFF6E84) : const Color(0xFF00E3FD),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    final authController = ref.read(authControllerProvider.notifier);
    await authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      await _showMessage(authState.error ?? '', isError: true);
    }
    if (authState.uid != null && mounted) {
      await AnalyticsService().logLogin(method: 'email_password');
      if (mounted) context.go('/');
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
      if (mounted) context.go('/');
    }
  }

  Future<void> _signInWithApple() async {
    final authController = ref.read(authControllerProvider.notifier);
    await authController.signInWithApple();
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      await _showMessage(authState.error ?? '', isError: true);
      return;
    }
    if (authState.uid != null) {
      await AnalyticsService().logLogin(method: 'apple');
      if (mounted) context.go('/');
    }
  }

  bool _supportsAppleSignIn() {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Ambient gradient blobs
            Positioned(
              top: -120, left: -120,
              child: _ambientBlob(_primary.withAlpha(25), 320),
            ),
            Positioned(
              bottom: -100, right: -100,
              child: _ambientBlob(_secondary.withAlpha(18), 280),
            ),
            // Main layout
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 760) {
                    return _wideLayout(authState);
                  }
                  return _narrowLayout(authState);
                },
              ),
            ),
            // System live indicator — bottom-left
            Positioned(
              bottom: 20,
              left: 24,
              child: _systemLiveIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  // ── ambient blob ─────────────────────────────────────────────────────────
  Widget _ambientBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── system live indicator ─────────────────────────────────────────────────
  Widget _systemLiveIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _secondary,
            boxShadow: [BoxShadow(color: _secondary.withAlpha(80), blurRadius: 6, spreadRadius: 2)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'SYSTEM LIVE',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
              color: _secondary, letterSpacing: 1.2),
        ),
      ],
    );
  }

  // ── logo widget ───────────────────────────────────────────────────────────
  Widget _logoText({double size = 42}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MIX',
          style: GoogleFonts.inter(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: _onSurface,
            fontStyle: FontStyle.italic,
            letterSpacing: -2,
          ),
        ),
        Text(
          'Vy',
          style: GoogleFonts.inter(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: _primary,
            fontStyle: FontStyle.italic,
            letterSpacing: -2,
          ),
        ),
      ],
    );
  }

  // ── wide two-column layout ────────────────────────────────────────────────
  Widget _wideLayout(dynamic authState) {
    return Row(
      children: [
        // Left panel – branding
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoText(size: 52),
                const SizedBox(height: 16),
                Text(
                  'The Midnight Kinetic.\nWhere live culture finds its pulse.',
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w400,
                    color: _onVariant, height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Staggered image preview cards
                _brandingCards(),
                const SizedBox(height: 32),
                // Avatar stack + streamer count
                _streamerCount(),
              ],
            ),
          ),
        ),
        // Right panel – glassmorphic auth card
        Container(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Center(child: _authCard(authState)),
        ),
      ],
    );
  }

  // ── narrow single-column layout ───────────────────────────────────────────
  Widget _narrowLayout(dynamic authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _logoText(size: 42),
          const SizedBox(height: 12),
          Text(
            'Where live culture finds its pulse.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: _onVariant),
          ),
          const SizedBox(height: 32),
          _authCard(authState),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── branding decorative cards ─────────────────────────────────────────────
  Widget _brandingCards() {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0,
            child: _brandingCard(
              width: 220, height: 140,
              gradient: const LinearGradient(
                colors: [Color(0xFF1C2028), Color(0xFF161A21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.headset_mic_rounded,
              label: 'Live Audio Room',
            ),
          ),
          Positioned(
            right: 0, top: 40,
            child: _brandingCard(
              width: 200, height: 130,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1D2A), Color(0xFF161A21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.videocam_rounded,
              label: 'Live Video Room',
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandingCard({
    required double width,
    required double height,
    required LinearGradient gradient,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ghostBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _onSurface)),
        ],
      ),
    );
  }

  Widget _streamerCount() {
    return Row(
      children: [
        _avatarStack(),
        const SizedBox(width: 12),
        Text(
          'Joined by 2.4k streamers tonight',
          style: GoogleFonts.inter(fontSize: 13, color: _onVariant),
        ),
      ],
    );
  }

  Widget _avatarStack() {
    final avatarColors = [
      const Color(0xFF8455EF),
      const Color(0xFF00E3FD),
      const Color(0xFFBA9EFF),
    ];
    return SizedBox(
      width: 70,
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColors[i],
                  border: Border.all(color: _surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── glassmorphic auth card ────────────────────────────────────────────────
  Widget _authCard(dynamic authState) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF161A21).withAlpha(153), // 0.6 opacity
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _ghostBorder),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w700, color: _onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your details to rejoin the pulse.',
                  style: GoogleFonts.inter(fontSize: 14, color: _onVariant),
                ),
                const SizedBox(height: 24),

                // Google sign-in button
                _socialButton(
                  onPressed: authState.isLoading ? null : _signInWithGoogle,
                  icon: _googleIcon(),
                  label: 'Continue with Google',
                ),

                // Apple sign-in (when supported)
                if (_supportsAppleSignIn()) ...[
                  const SizedBox(height: 10),
                  _socialButton(
                    onPressed: authState.isLoading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple, size: 20, color: _onSurface),
                    label: 'Continue with Apple',
                  ),
                ],

                const SizedBox(height: 20),
                _orDivider(),
                const SizedBox(height: 20),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: _onSurface, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 18, color: _onVariant),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: _onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: _onVariant),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18, color: _onVariant,
                      ),
                      onPressed: _togglePassword,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading ? null : _resetPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    ),
                    child: Text('Forgot password?',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _primary, fontWeight: FontWeight.w500)),
                  ),
                ),

                const SizedBox(height: 12),

                // Gradient Sign In button
                _gradientButton(
                  onPressed: authState.isLoading ? null : _login,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _surface),
                        )
                      : Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: _surface),
                        ),
                ),

                const SizedBox(height: 20),

                // Create account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New to MixVy? ',
                        style: GoogleFonts.inter(fontSize: 13, color: _onVariant)),
                    GestureDetector(
                      onTap: authState.isLoading
                          ? null
                          : () => context.go('/register'),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _secondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Footer links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _footerLink('Terms'),
                    Text(' · ', style: GoogleFonts.inter(fontSize: 11, color: _onVariant)),
                    _footerLink('Privacy'),
                    Text(' · ', style: GoogleFonts.inter(fontSize: 11, color: _onVariant)),
                    _footerLink('Support'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _surfaceHighest,
          side: const BorderSide(color: _ghostBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500, color: _onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20, height: 20,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(2),
            child: const Icon(Icons.g_mobiledata_rounded,
                size: 16, color: Color(0xFF4285F4)),
          ),
        ],
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: _ghostBorder),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR EMAIL',
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: _onVariant, letterSpacing: 1.0),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: _ghostBorder),
        ),
      ],
    );
  }

  Widget _gradientButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: onPressed == null
                  ? null
                  : const LinearGradient(
                      colors: [_primary, _primaryDim],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: onPressed == null ? _surfaceHighest : null,
              borderRadius: BorderRadius.circular(999),
              boxShadow: onPressed == null
                  ? null
                  : [
                      BoxShadow(
                        color: _primaryDim.withAlpha(76),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
          ),
          // Tap ripple + content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return GestureDetector(
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, color: _onVariant,
              decoration: TextDecoration.underline,
              decorationColor: _onVariant)),
    );
  }
}
