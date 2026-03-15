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
            Text('MIXVY', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            Text(productTagline, style: TextStyle(fontSize: 18, color: Colors.white70)),
            SizedBox(height: 20),
            Text('The Hangout • Silent Whispers', style: TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
