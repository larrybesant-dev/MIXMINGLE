import 'package:flutter_stripe/flutter_stripe.dart';
// Handles business ad payments
import '../payments/payment_intent_service.dart';
import '../../core/error_handler.dart';
import '../../core/logger.dart';
class AdPayment {
  // Integrates Stripe for ad payments
  static Future<void> payForAd(String businessId, double amount) async {
    final clientSecret = await createPaymentIntent(amount.toInt());
    if (clientSecret == null) {
      ErrorHandler.handle('Failed to create payment intent');
      return;
    }
    try {
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
