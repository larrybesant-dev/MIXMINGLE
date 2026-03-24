import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../core/theme/electric_velvet_theme.dart';
import '../theme/app_theme.dart';

class MixVyApp extends ConsumerWidget {
  const MixVyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // For now, use system theme. For user toggle, add a provider.
    return MaterialApp.router(
      title: 'MixVy',
      theme: AppTheme.light,
      darkTheme: electricVelvetTheme,
      themeMode: ThemeMode.system, // Change to ThemeMode.light/dark for fixed mode
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
