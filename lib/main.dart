import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mixvy/firebase_options.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mixvy/dev/firebase_emulator_bootstrap.dart';
import 'package:mixvy/services/push_messaging_service.dart';
import 'package:mixvy/router/app_router.dart' show rootNavigatorKey;
// Desktop window management (no-op on web/mobile via conditional export)
import 'package:window_manager/window_manager.dart';
import 'services/desktop_window_service.dart';
import 'utils/platform_args.dart';
import 'features/messaging/screens/whisper_popout_screen.dart';
import 'features/room/screens/cam_popout_screen.dart';

void _bootstrapLog(String message) {
  developer.log(message, name: 'Bootstrap');
  debugPrint('[BOOT] $message');
}

/// Crashlytics is only supported on Android, iOS, and macOS.
/// Windows and Linux desktop builds must be excluded.
bool get _crashlyticsSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

void main() async {
  runZonedGuarded(
    () async {
      _bootstrapLog('main() entered');
      WidgetsFlutterBinding.ensureInitialized();
      _bootstrapLog('WidgetsFlutterBinding initialized');

      const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
      _bootstrapLog('isTest=$isTest kIsWeb=$kIsWeb');

      if (kIsWeb) {
        // Use path-based URLs so direct navigation, refresh, and browser history work naturally.
        usePathUrlStrategy();
        _bootstrapLog('Path URL strategy enabled');
      }

      if (!isTest) {
        try {
          // Load environment variables. On web, hidden files like .env may be ignored by hosting.
          _bootstrapLog('Loading environment variables');
          try {
            await dotenv.load(fileName: 'assets/env/app_env');
            _bootstrapLog('Loaded env from assets/env/app_env');
          } catch (_) {
            try {
              await dotenv.load(fileName: 'assets/.env');
              _bootstrapLog('Loaded env from assets/.env');
            } catch (_) {
              await dotenv.load();
              _bootstrapLog('Loaded env from default .env');
            }
          }

          // Initialize Firebase
          _bootstrapLog('Initializing Firebase');
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          _bootstrapLog('Firebase initialized');

          if (kIsWeb) {
            await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
            _bootstrapLog('FirebaseAuth local persistence enabled for web');
          }

          if (kIsWeb) {
            FirebaseFirestore.instance.settings = const Settings(
              sslEnabled: true,
              persistenceEnabled: true,
              webExperimentalAutoDetectLongPolling: true,
            );
            _bootstrapLog('Firestore web transport auto-detect enabled');
          } else {
            FirebaseFirestore.instance.settings = const Settings(
              persistenceEnabled: true,
            );
            _bootstrapLog('Firestore offline persistence enabled');
          }

          if (!kIsWeb) {
            FirebaseMessaging.onBackgroundMessage(
              firebaseMessagingBackgroundHandler,
            );
            _bootstrapLog('Registered Firebase background messaging handler');
          }

          if (FirebaseEmulatorBootstrap.enabled) {
            _bootstrapLog('Configuring Firebase emulators');
            await FirebaseEmulatorBootstrap.configure();
            _bootstrapLog('Firebase emulator bootstrap complete');
          } else {
            _bootstrapLog('Firebase emulators disabled — using production');
          }

          _bootstrapLog('Initializing push messaging service');
          await PushMessagingService.instance.initialize();
          PushMessagingService.instance.setNavigatorKey(rootNavigatorKey);
          _bootstrapLog('Push messaging service initialized');

          // Global async/sync error handling for all platforms.
          FlutterError.onError = (FlutterErrorDetails details) {
            FlutterError.presentError(details);
            developer.log(
              'Flutter framework error',
              name: 'AppError',
              error: details.exception,
              stackTrace: details.stack,
            );

            if (_crashlyticsSupported) {
              FirebaseCrashlytics.instance.recordFlutterError(details);
            }
          };
          _bootstrapLog('FlutterError handler installed');

          PlatformDispatcher.instance.onError = (error, stack) {
            developer.log(
              'Uncaught platform error',
              name: 'AppError',
              error: error,
              stackTrace: stack,
            );

            if (_crashlyticsSupported) {
              FirebaseCrashlytics.instance.recordError(
                error,
                stack,
                fatal: true,
              );
            }

            // Mark as handled so web async plugin errors do not bubble as fatal uncaught errors.
            return true;
          };
          _bootstrapLog('PlatformDispatcher error handler installed');

          // Crashlytics collection (only on Android/iOS/macOS)
          if (_crashlyticsSupported) {
            FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
            _bootstrapLog('Crashlytics collection enabled');
          }
        } catch (e) {
          _bootstrapLog('Bootstrap failed: $e');
          // If Firebase fails to initialize, show a fallback UI.
          runApp(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text(
                    'Failed to initialize Firebase.\n$e',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
          return;
        }
      }

      _bootstrapLog('Calling runApp(MixVyApp)');
      // Desktop pop-out window handling (Windows/macOS/Linux only)
      if (!kIsWeb) {
        try {
          final args = _getCommandLineArgs();
          final whisperArg = args.firstWhere(
            (a) => a.startsWith('--popout-whisper='),
            orElse: () => '',
          );
          final camArg = args.firstWhere(
            (a) => a.startsWith('--popout-cam='),
            orElse: () => '',
          );
          if (whisperArg.isNotEmpty) {
            final userId = whisperArg.substring('--popout-whisper='.length);
            await windowManager.ensureInitialized();
            await windowManager.setSize(const Size(420, 640));
            await windowManager.setTitle('Whisper');
            await windowManager.show();
            runApp(
              ProviderScope(
                child: MaterialApp(
                  home: WhisperPopoutScreen(targetUserId: userId),
                ),
              ),
            );
            return;
          } else if (camArg.isNotEmpty) {
            final userId = camArg.substring('--popout-cam='.length);
            await windowManager.ensureInitialized();
            await windowManager.setSize(const Size(520, 480));
            await windowManager.setTitle('Cam');
            await windowManager.show();
            runApp(
              ProviderScope(
                child: MaterialApp(home: CamPopoutScreen(targetUserId: userId)),
              ),
            );
            return;
          }
          // Main window: initialise window_manager with platform defaults
          await windowManager.ensureInitialized();
          await windowManager.setMinimumSize(const Size(400, 600));
        } catch (_) {
          // window_manager not supported on this platform — continue normally
        }
      }
      runApp(const ProviderScope(child: MixVyApp()));
      _bootstrapLog('runApp(MixVyApp) returned');
    },
    (error, stackTrace) {
      developer.log(
        'Uncaught zone error',
        name: 'AppError',
        error: error,
        stackTrace: stackTrace,
      );

      if (_crashlyticsSupported) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
    },
  );
}

/// Returns command-line arguments safely. Returns empty list on web/mobile.
List<String> _getCommandLineArgs() => getCommandLineArgs();

/// Unused import suppressor — DesktopWindowService is declared but the
/// pop-out buttons in live_room_screen use it via WebPopoutService (web)
/// or FloatingWhisperPanel (mobile). On desktop the native Whisper action
/// uses DesktopWindowService directly from there.
// ignore: unused_element
DesktopWindowService? _desktopWindowServiceRef;
