import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mixvy/firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  if (!isTest) {
    await dotenv.load();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Set up global error handling for Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Report to Crashlytics
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  runApp(const ProviderScope(child: MixVyApp()));
}
