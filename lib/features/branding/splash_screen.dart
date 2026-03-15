import 'package:flutter/material.dart';
import 'product_identity.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nightlife, size: 64, color: Color(0xFF6C63FF)),
            SizedBox(height: 20),
            Text('MIXVY', style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text(productTagline, style: TextStyle(fontSize: 20, color: Colors.white70, fontStyle: FontStyle.italic)),
            SizedBox(height: 20),
            Text('Welcome to your grown, curated lounge.', style: TextStyle(fontSize: 18, color: Colors.white70)),
            SizedBox(height: 10),
            Text('Where the night begins.', style: TextStyle(fontSize: 16, color: Color(0xFF6C63FF))),
          ],
        ),
      ),
    );
  }
}
