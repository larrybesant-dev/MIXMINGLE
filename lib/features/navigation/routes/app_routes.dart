import 'package:flutter/material.dart';
import '../pages/main_shell_page.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Example: Pass userId via settings.arguments
    switch (settings.name) {
      case '/':
        final userId = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => MainShellPage(userId: userId));
      // Add additional routes as needed
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Page not found'))));
    }
  }
}
