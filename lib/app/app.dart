import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/app_settings_service.dart';
import '../router/app_router.dart';
import '../presentation/providers/app_settings_provider.dart';
import '../theme/font_fallbacks.dart';
import '../theme/app_theme.dart';
import '../core/theme.dart';
import '../shared/widgets/beta_feedback_overlay.dart';
import '../shared/widgets/incoming_call_overlay.dart';
import '../features/after_dark/providers/after_dark_provider.dart';
import '../features/after_dark/theme/after_dark_theme.dart';

class MixVyApp extends ConsumerWidget {
  const MixVyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull ?? const AppSettings.defaults();
    final appLocale = Locale(settings.localeCode);
    final afterDarkActive = ref.watch(afterDarkSessionProvider);

    return MaterialApp.router(
      title: 'MixVy',
      theme: afterDarkActive ? afterDarkTheme : AppTheme.light,
      darkTheme: afterDarkActive ? afterDarkTheme : midnightCreativeTheme,
      themeMode: afterDarkActive ? ThemeMode.dark : settings.themeMode,
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: const TextStyle(fontFamilyFallback: mixvyFontFamilyFallback),
          child: IncomingCallOverlay(
            child: BetaFeedbackOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
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
