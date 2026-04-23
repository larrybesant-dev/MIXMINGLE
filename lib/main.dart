import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/mixvy_app.dart';
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
    debugPrint('FIREBASE INIT FAILED: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MixVyApp());
}
