import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/app_settings_service.dart';
import '../router/app_router.dart';
import '../core/theme/electric_velvet_theme.dart';
import '../presentation/providers/app_settings_provider.dart';
import '../theme/app_theme.dart';

class MixVyApp extends ConsumerWidget {
  const MixVyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull ?? const AppSettings.defaults();

    return MaterialApp.router(
      title: 'MixVy',
      theme: AppTheme.light,
      darkTheme: electricVelvetTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
