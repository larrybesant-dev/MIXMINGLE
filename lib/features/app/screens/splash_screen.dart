import 'package:flutter/material.dart';
import 'package:mix_and_mingle/app_routes.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mix & Mingle',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E6FF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
