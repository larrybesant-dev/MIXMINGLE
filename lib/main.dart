import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mixvy/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:mixvy/dev/firebase_emulator_bootstrap.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

      if (!isTest) {
        try {
          // Load environment variables
          try {
            await dotenv.load(fileName: 'assets/.env');
          } catch (_) {
            await dotenv.load();
          }

          // Initialize Firebase
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );

          await FirebaseEmulatorBootstrap.configure();

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

          PlatformDispatcher.instance.onError = (error, stack) {
            developer.log(
              'Uncaught platform error',
              name: 'AppError',
              error: error,
              stackTrace: stack,
            );

            if (!kIsWeb) {
              FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            }

            // Mark as handled so web async plugin errors do not bubble as fatal uncaught errors.
            return true;
          };

          // Crashlytics collection (not supported on web)
          if (!kIsWeb) {
            FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
          }
        } catch (e) {
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

      runApp(const ProviderScope(child: MixVyApp()));
    },
    (error, stackTrace) {
      developer.log(
        'Uncaught zone error',
        name: 'AppError',
        error: error,
        stackTrace: stackTrace,
      );

      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      }
    },
  );
}