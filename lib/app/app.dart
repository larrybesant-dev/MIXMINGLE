import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/app_settings_service.dart';
import '../router/app_router.dart';
import '../presentation/providers/app_settings_provider.dart';
import '../theme/app_theme.dart';
import '../core/theme.dart';

class MixVyApp extends ConsumerWidget {
  const MixVyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull ?? const AppSettings.defaults();
    final appLocale = Locale(settings.localeCode);

    return MaterialApp.router(
      title: 'MixVy',
      theme: AppTheme.light,
      darkTheme: midnightCreativeTheme,
      themeMode: settings.themeMode,
      locale: appLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
