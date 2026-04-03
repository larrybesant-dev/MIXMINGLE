import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mixvy/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mixvy/dev/firebase_emulator_bootstrap.dart';
import 'package:mixvy/services/push_messaging_service.dart';
import 'package:mixvy/router/app_router.dart' show rootNavigatorKey;

void _bootstrapLog(String message) {
  developer.log(message, name: 'Bootstrap');
  debugPrint('[BOOT] $message');
}

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
            FirebaseFirestore.instance.settings = const Settings(
              sslEnabled: true,
              persistenceEnabled: true,
              webExperimentalForceLongPolling: true,
            );
            _bootstrapLog('Firestore web transport fallback enabled');
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

            if (!kIsWeb) {
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

            if (!kIsWeb) {
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

          // Crashlytics collection (not supported on web)
          if (!kIsWeb) {
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

      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
    },
  );
}
