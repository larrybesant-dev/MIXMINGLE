import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../shared/widgets/app_debug_overlay.dart';
import '../shared/widgets/incoming_call_overlay.dart';
import '../features/after_dark/providers/after_dark_provider.dart';
import '../features/after_dark/theme/after_dark_theme.dart';
import '../features/profile/profile_controller.dart';
import '../services/presence_controller.dart';
import '../core/events/event_providers.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  if (Firebase.apps.isEmpty) return;

  final auth = FirebaseAuth.instance;

  try {
    await auth
        .authStateChanges()
        .timeout(
          const Duration(seconds: 3),
          onTimeout: (sink) {
            sink.add(auth.currentUser);
            sink.close();
          },
        )
        .first;
  } catch (_) {
    // Non-fatal bootstrap safety
  }

  if (!kIsWeb) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
});

class MixVyApp extends ConsumerStatefulWidget {
  const MixVyApp({super.key});

  @override
  ConsumerState<MixVyApp> createState() => _MixVyAppState();
}

class _MixVyAppState extends ConsumerState<MixVyApp> {
  bool _runtimeStarted = false;
  bool _runtimeQueued = false;

  Future<void> _startRuntimeServices() async {
    if (_runtimeStarted || _runtimeQueued) return;

    _runtimeQueued = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await ref
            .read(profileControllerProvider.notifier)
            .loadCurrentProfile();
      }

      ref.read(presenceControllerProvider);
      ref.read(eventPipelineProvider);
    } catch (_) {
      // keep startup resilient
    } finally {
      if (mounted) {
        setState(() => _runtimeStarted = true);
      }
    }
  }

  Widget _buildBootShell({String message = 'Starting MixVy...'}) {
    final body = Scaffold(
      backgroundColor: VelvetNoir.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: VelvetNoir.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: VelvetNoir.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return MaterialApp(
      title: 'MixVy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: midnightCreativeTheme,
      home: body,
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(appBootstrapProvider);

    return boot.when(
      loading: () => _buildBootShell(),
      error: (_, __) =>
          _buildBootShell(message: 'Recovering startup...'),
      data: (_) {
        if (!_runtimeStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_startRuntimeServices());
          });

          return _buildBootShell(message: 'Preparing your rooms...');
        }

        final router = ref.watch(routerProvider);

        final settings =
            ref.watch(appSettingsControllerProvider).valueOrNull ??
            const AppSettings.defaults();

        final locale = Locale(settings.localeCode);
        final afterDark = ref.watch(afterDarkSessionProvider);

        return MaterialApp.router(
          title: 'MixVy',
          theme: afterDark ? afterDarkTheme : AppTheme.light,
          darkTheme:
              afterDark ? afterDarkTheme : midnightCreativeTheme,
          themeMode:
              afterDark ? ThemeMode.dark : settings.themeMode,
          locale: locale,
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
          builder: (context, child) {
            return DefaultTextStyle.merge(
              style: const TextStyle(
                fontFamilyFallback: mixvyFontFamilyFallback,
              ),
              child: IncomingCallOverlay(
                child: BetaFeedbackOverlay(
                  child: AppDebugOverlay(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
