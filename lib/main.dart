import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    developer.log(
      'FIREBASE INIT FAILED: $error',
      error: error,
      stackTrace: stackTrace,
      name: 'main',
    );
  }

  runApp(
    ProviderScope(
      child: const MixVyApp(),
    ),
  );
}
