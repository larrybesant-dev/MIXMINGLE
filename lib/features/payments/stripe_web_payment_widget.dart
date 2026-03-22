// lib/features/payments/stripe_web_payment_widget.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StripeWebPaymentWidget extends StatefulWidget {
  const StripeWebPaymentWidget({super.key});

  @override
  State<StripeWebPaymentWidget> createState() =>
      _StripeWebPaymentWidgetState();
}

class _StripeWebPaymentWidgetState
    extends State<StripeWebPaymentWidget> {
  bool isLoading = false;
  String? error;

  Future<void> startCheckout() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // 🔥 CALL YOUR BACKEND / FIREBASE FUNCTION HERE
      // This should return a Stripe Checkout URL
      final checkoutUrl = await createCheckoutSession(user.uid);

      if (checkoutUrl == null) {
        throw Exception("Failed to create checkout session");
      }

      // 🚀 REDIRECT TO STRIPE
      // TODO: Implement redirect to Stripe checkoutUrl for web (use universal_html or url_launcher)
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<String?> createCheckoutSession(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("https://us-central1-mix-and-mingle-v2.cloudfunctions.net/createCheckoutSession"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["url"];
      } else {
        throw Exception("Failed to create session: ${response.body}");
      }
    } catch (e) {
      // TODO: Integrate Crashlytics or similar for error reporting (manual follow-up required)
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Upgrade to Premium",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: startCheckout,
                  child: const Text("Pay with Stripe"),
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ]
              ],
            ),
    );
  }
}
