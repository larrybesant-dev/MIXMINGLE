import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_provider.dart';

class PaymentWidget extends ConsumerWidget {
  final String senderId;
  final String receiverId;

  const PaymentWidget({required this.senderId, required this.receiverId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentService = ref.read(paymentServiceProvider);
    return Column(
      children: [
        Semantics(
          label: 'Send Payment button',
          button: true,
          child: ElevatedButton(
            onPressed: () => paymentService.processPayment(100),
            child: Text('Send Payment', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 18 : 16)),
          ),
        ),
      ],
    );
  }
}
