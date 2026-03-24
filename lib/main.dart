import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mixvy/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const isTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  if (!isTest) {
    await dotenv.load();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const ProviderScope(child: MixVyApp()));
}
