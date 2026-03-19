import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/payment_constants.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Only initialize Stripe for non-web platforms
  if (!kIsWeb) {
    Stripe.publishableKey = PaymentConstants.stripePublishableKey;
  }
  runApp(
    const ProviderScope(
      child: MixVyApp(),
    ),
  );
}
