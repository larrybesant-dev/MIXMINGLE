import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'google_sign_in_helper_stub.dart'
    if (dart.library.html) 'google_sign_in_helper_web.dart'
    if (dart.library.io) 'google_sign_in_helper_mobile.dart';

class MixVyLoginScreen extends StatefulWidget {
  const MixVyLoginScreen({super.key});

  @override
  State<MixVyLoginScreen> createState() => _MixVyLoginScreenState();
}

class _MixVyLoginScreenState extends State<MixVyLoginScreen> {
  bool _isLoadingGoogle = false;
  String? _error;

  late final dynamic _googleSignInHelper;

  @override
  void initState() {
    super.initState();
    _googleSignInHelper = getGoogleSignInHelper();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
      _error = null;
    });
    try {
      await _googleSignInHelper.signInWithGoogle();
      setState(() {
        _isLoadingGoogle = false;
      });
      // Optionally, navigate to home screen here
    } catch (e) {
      setState(() {
        _isLoadingGoogle = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                // Brand
                Column(
                  children: [
                    Text(
                      'MIXVY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: const Color(
                              0xFFB6A0FF,
                            ).withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00e3fd),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00e3fd,
                            ).withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'THE DIGITAL CURATOR EXPERIENCE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFadaaaa),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // Login Form (single set)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'EMAIL ADDRESS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFadaaaa),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF131313),
                            prefixIcon: const Icon(
                              Icons.mail_outline,
                              color: Color(0xFFadaaaa),
                            ),
                            hintText: 'name@domain.com',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 0,
                            ),
                          ),
                          autofillHints: const [AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PASSWORD',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFadaaaa),
                                letterSpacing: 2,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'FORGOT?',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00e3fd),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          obscureText: true,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF131313),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFFadaaaa),
                            ),
                            suffixIcon: const Icon(
                              Icons.visibility,
                              color: Color(0xFFadaaaa),
                            ),
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 0,
                            ),
                          ),
                          autofillHints: const [AutofillHints.password],
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            backgroundColor: const Color(0xFFb6a0ff),
                            foregroundColor: Colors.black,
                            elevation: 8,
                            shadowColor: const Color(
                              0xFFb6a0ff,
                            ).withValues(alpha: 0.2),
                          ),
                          child: Text(
                            'LOG IN',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: const Color(0xFF262626)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'Or connect with',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFadaaaa),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: const Color(0xFF262626)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingGoogle
                                    ? null
                                    : _handleGoogleSignIn,
                                icon: _isLoadingGoogle
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.account_circle,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  'Google',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFF20201f),
                                  side: const BorderSide(
                                    color: Color(0xFF484847),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.apple,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Apple',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFF20201f),
                                  side: const BorderSide(
                                    color: Color(0xFF484847),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.inter(
                                color: const Color(0xFFadaaaa),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Create One',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF00e3fd),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(
                                      0xFF00e3fd,
                                    ).withValues(alpha: 0.3),
                                    decorationThickness: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
