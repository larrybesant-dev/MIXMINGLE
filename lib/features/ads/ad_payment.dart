import 'package:flutter_stripe/flutter_stripe.dart';
// Handles business ad payments
// import '../payments/payment_intent_service.dart'; // Unused, can be removed
import '../../core/error_handler.dart';
import '../../core/logger.dart';
import '../../services/payment_api.dart';

class AdPayment {
  // Integrates Stripe for ad payments
  static Future<void> payForAd(String businessId, double amount) async {
    // Use PaymentApi to create a payment intent for ad payments
    try {
      final clientSecret = await PaymentApi.createIntent(
        amount: amount,
        currency: 'usd',
        recipientId: businessId,
      );
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'MixVy',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      Logger.log('Payment successful for business: $businessId');
    } catch (e) {
      ErrorHandler.handle(e);
    }
  }
}
