import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stripe_web_payment_widget.dart';
import 'payments_controller.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/payment_api.dart';
import '../../config/payment_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return StripeWebPaymentWidget(
        publishableKey: PaymentConstants.stripePublishableKey,
        amount: 1000, // Example amount in cents
        currency: 'usd',
      );
    }
    final paymentState = ref.watch(paymentControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: paymentState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Start Payment'),
                  onPressed: paymentState.isLoading
                      ? null
                      : () async {
                          final controller = ref.read(paymentControllerProvider.notifier);
                          await controller.initiatePayment(1000);
                          if (!context.mounted) return;
                          if (paymentState.error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful')));
                          }
                        },
                ),
                const SizedBox(height: 16),
                Text('Pay securely with Stripe'),
                if (paymentState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(paymentState.error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          // ...existing code for payment history...
        ],
      ),
    );
  }
}
// ...existing code...
