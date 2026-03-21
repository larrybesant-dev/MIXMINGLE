import 'package:flutter/material.dart';
import 'dart:js_util' as js_util;
import 'dart:convert';
import 'package:http/http.dart' as http;

class StripeWebPaymentWidget extends StatelessWidget {
  final String publishableKey;
  final int amount;
  final String currency;

  const StripeWebPaymentWidget({
    super.key,
    required this.publishableKey,
    required this.amount,
    required this.currency,
  });

  Future<void> _pay() async {
    final response = await http.post(
      Uri.parse('https://us-central1-mix-and-mingle-v2.cloudfunctions.net/createPaymentIntent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount / 100, // Convert cents to dollars for backend
        'currency': currency,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'];
      if (clientSecret != null) {
        js_util.callMethod(js_util.globalThis, 'stripePay', [publishableKey, clientSecret]);
      } else {
        _showError('No client secret returned.');
      }
    } else {
      _showError('Failed to create payment intent.');
    }
  }

  void _showError(String message) {
    js_util.callMethod(js_util.globalThis, 'alert', [message]);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _pay,
      child: const Text('Pay with Stripe'),
    );
  }
}
