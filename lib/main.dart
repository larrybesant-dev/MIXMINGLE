import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/boot_state.dart';
import 'app/boot_state_notifier.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var initialBootState = BootState.loading;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    initialBootState = BootState.loading;
  } catch (error, stackTrace) {
    initialBootState = BootState.failed;
    developer.log(
      'FIREBASE INIT FAILED: $error',
      error: error,
      stackTrace: stackTrace,
      name: 'main',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        bootStateProvider.overrideWith(
          (ref) => BootStateNotifier(initialState: initialBootState),
        ),
      ],
      child: const MixVyApp(),
    ),
  );
}
