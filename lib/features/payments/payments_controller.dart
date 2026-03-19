import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentsController extends StateNotifier<PaymentState> {
  PaymentsController() : super(PaymentState.initial());

  String? error;
  Future<void> initiatePayment(double amount) async {
    try {
      // Example: Start payment
      // Replace with real payment logic
      state = PaymentState();
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
  Future<void> confirmPayment(String paymentId) async {
    try {
      // Example: Confirm payment
      state = PaymentState();
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
  void handleError(String errorMsg) {
    error = errorMsg;
  }
}

class PaymentState {
  // Add payment state fields
  PaymentState();
  factory PaymentState.initial() => PaymentState();
}
