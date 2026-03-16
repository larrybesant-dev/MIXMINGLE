import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...existing code...
import '../router/app_router.dart';
import '../theme/custom_theme.dart';

class MixVyApp extends StatelessWidget {
  const MixVyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'MixVy',
        theme: customTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
