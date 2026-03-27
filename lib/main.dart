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
  WidgetsFlutterBinding.ensureInitialized();

  const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  if (!isTest) {
    try {
      // Load environment variables
      await dotenv.load();

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseEmulatorBootstrap.configure();

      // Crashlytics (not supported on web)
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          FirebaseCrashlytics.instance.recordFlutterError(details);
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (e) {
      // If Firebase fails to initialize, show a fallback UI
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

  // Run the actual app
  runApp(const ProviderScope(child: MixVyApp()));
}