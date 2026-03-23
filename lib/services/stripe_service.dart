import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static void init() {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    Stripe.publishableKey = publishableKey;
    // Optionally set merchant identifier and other settings here
  }

  // Add methods for payment intent, customer, etc. as needed
}
