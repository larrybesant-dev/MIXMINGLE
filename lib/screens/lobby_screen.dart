// lib/screens/lobby_screen.dart

import 'package:flutter/material.dart';
import '../theme/mix_mingle_theme.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MixMingleTheme.background,
      appBar: AppBar(
        title: Text('Lobby', style: MixMingleTheme.title.copyWith(color: Colors.white)),
        backgroundColor: MixMingleTheme.primary,
        elevation: MixMingleTheme.elevation,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Mix & Mingle!', style: MixMingleTheme.title),
            SizedBox(height: MixMingleTheme.spacing),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/room');
              },
              child: Text('Join a Room', style: MixMingleTheme.button),
            ),
            SizedBox(height: MixMingleTheme.spacing),
            Text('No rooms available? Create one!', style: MixMingleTheme.body),
            // Add onboarding hints
            SizedBox(height: MixMingleTheme.spacing * 2),
            Text('First time? Tap the mic/camera/reactions in the room to see hints.', style: MixMingleTheme.caption),
          ],
        ),
      ),
    );
  }
}
