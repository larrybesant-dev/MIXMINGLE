import 'package:flutter/material.dart';

class SimpleSplashPage extends StatefulWidget {
  const SimpleSplashPage({super.key});

  @override
  State<SimpleSplashPage> createState() => _SimpleSplashPageState();
}

class _SimpleSplashPageState extends State<SimpleSplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎵',
              style: TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 20),
            const Text(
              'MIX & MINGLE',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.pink.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
