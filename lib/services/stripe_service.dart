import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static void init({required String publishableKey}) {
    Stripe.publishableKey = publishableKey;
    // Optionally set merchant identifier and other settings here
  }

  // Add methods for payment intent, customer, etc. as needed
}
