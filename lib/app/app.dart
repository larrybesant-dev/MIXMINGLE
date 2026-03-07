// Removed invalid imports
// import 'dart:js_util' as js_util;
// import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/neon_theme.dart';

class MixMingleApp extends StatelessWidget {
  const MixMingleApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('ðŸ—ï¸ Building MixMingleApp...');

    return ProviderScope(
      child: MaterialApp(
        title: 'Mix & Mingle - Global DJ Vibes',
        debugShowCheckedModeBanner: false,
        theme: NeonTheme.darkTheme,
        // Use the app routing system
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: AppRoutes.landing,
        // Handle unknown routes
        onUnknownRoute: (settings) {
          debugPrint('âš ï¸ Unknown route: ${settings.name}');
          return MaterialPageRoute(
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Route not found',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(ctx).pushNamedAndRemoveUntil(
                            AppRoutes.landing,
                            (route) => false,
                          ),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
