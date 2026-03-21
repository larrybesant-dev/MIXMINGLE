import 'package:flutter_stripe/flutter_stripe.dart';
// Handles business ad payments
import '../payments/payment_intent_service.dart';
class AdPayment {
  // Integrates Stripe for ad payments
  static Future<void> payForAd(String businessId, double amount) async {
    // Import createPaymentIntent
    // Import createPaymentIntent
    // Call backend to create payment intent
    final clientSecret = await createPaymentIntent(amount.toInt());
    if (clientSecret == null) {
      throw Exception('Failed to create payment intent');
    }
    // Present Stripe payment sheet using clientSecret
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'MixVy',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      // Handle payment sheet errors
      rethrow;
    }
  }
}
