import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix_and_mingle/services/email_verification_service.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:mix_and_mingle/shared/widgets/neon_button.dart';
import 'package:mix_and_mingle/app_routes.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final EmailVerificationService _verificationService =
      EmailVerificationService();
  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    _isVerified = _verificationService.isEmailVerified();
    setState(() => _isLoading = false);

    if (_isVerified) {
      await _verificationService.updateVerificationStatusInFirestore();
      _navigateToHome();
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await _verificationService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    _isVerified = await _verificationService.reloadAndCheckVerification();

    if (_isVerified) {
      await _verificationService.updateVerificationStatusInFirestore();
      _navigateToHome();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your email.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClubBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'ve sent a verification email to your inbox. Please click the link in the email to verify your account.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00E6FF)),
                  )
                else
                  Column(
                    children: [
                      NeonButton(
                          label: 'Resend Verification Email',
                          onPressed: _sendVerificationEmail),
                      const SizedBox(height: 16),
                      NeonButton(
                          label: 'I\'ve Verified My Email',
                          onPressed: _checkVerification),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.login);
                          }
                        },
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFF8F00FF),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
