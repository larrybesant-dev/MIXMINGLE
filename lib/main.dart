import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mixvy/firebase_options.dart';
import 'config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to Firestore emulator in dev mode only
  if (currentEnv == Environment.dev) {
    // ignore: avoid_print
    print('Connecting to Firestore emulator...');
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  runApp(const ProviderScope(child: MixVyApp()));
}
