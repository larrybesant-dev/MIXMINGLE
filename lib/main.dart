import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mixvy/firebase_options.dart';

import 'config/environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore emulator disabled: always use production Firebase

  runApp(const ProviderScope(child: MixVyApp()));
}
