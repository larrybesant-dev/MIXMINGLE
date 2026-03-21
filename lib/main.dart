import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/payment_constants.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Use Firebase Emulator Suite for local development
  const bool useEmulator = true; // Set to false for production
  if (useEmulator) {
    // Firestore emulator
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (_) {}
    // Auth emulator
    try {
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (_) {}
  }

  // Only initialize Stripe for non-web platforms
  if (!kIsWeb) {
    Stripe.publishableKey = PaymentConstants.stripePublishableKey;
  }
  runApp(
    ProviderScope(
      child: MixVyApp(),
    ),
  );
}
