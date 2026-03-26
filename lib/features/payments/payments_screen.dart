import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'stripe_web_payment_widget.dart';
import 'payments_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/services/analytics_service.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return const StripeWebPaymentWidget();
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
                  onPressed: paymentState.isLoading
                      ? null
                      : () async {
                          final controller = ref.read(paymentControllerProvider.notifier);
                          await controller.initiatePayment(1000);
                          if (!context.mounted) return;
                          if (paymentState.error == null) {
                            // Log purchase event
                            await AnalyticsService().logPurchase(value: 1000, currency: 'usd');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful')));
                          }
                        },
                  child: paymentState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Start Payment'),
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
