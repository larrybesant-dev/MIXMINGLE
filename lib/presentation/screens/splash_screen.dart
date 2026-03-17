
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isOver21 = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo (placeholder)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25), // 0.1 opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flash_on, size: 60, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'MixVy',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              // Welcome Message
              Text(
                'Welcome to MixVy!\nConnect, chat, and go live with friends.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              // Age Confirmation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isOver21,
                    onChanged: (val) => setState(() => isOver21 = val ?? false),
                  ),
                  Flexible(
                    child: Text(
                      'I am 21 years of age or older',
                      style: GoogleFonts.poppins(fontSize: 14, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isOver21 ? () => Navigator.of(context).pushReplacementNamed('/login') : null,
                  child: const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              // Register Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isOver21 ? () => Navigator.of(context).pushReplacementNamed('/register') : null,
                  child: Text('Register', style: TextStyle(fontSize: 18, color: theme.colorScheme.primary)),
                ),
              ),
              const SizedBox(height: 32),
              // Optional: Loading indicator or animation
              // CircularProgressIndicator(color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
