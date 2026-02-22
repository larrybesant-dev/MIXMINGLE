// Stub implementation for non-web platforms.
// The real HealthDashboard requires dart:js_interop / package:web (web-only).
import 'package:flutter/material.dart';

class HealthDashboard extends StatelessWidget {
  final String? agoraAppId;

  const HealthDashboard({this.agoraAppId, super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Health Dashboard is only available on the web platform.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
