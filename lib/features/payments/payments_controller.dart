import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentState {
  final bool isLoading;
  final String? error;
  final double? amount;
  final String? paymentId;
  final bool isConfirmed;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.amount,
    this.paymentId,
    this.isConfirmed = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    double? amount,
    String? paymentId,
    bool? isConfirmed,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      amount: amount ?? this.amount,
      paymentId: paymentId ?? this.paymentId,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

final paymentsControllerProvider = NotifierProvider<PaymentController, PaymentState>(
  () => PaymentController(),
);

class PaymentController extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();

  Future<void> initiatePayment(double amount) async {
    state = state.copyWith(isLoading: true, error: null, amount: amount);
    try {
      // Replace with real payment logic
      state = state.copyWith(
        isLoading: false,
        paymentId: 'mockId',
        isConfirmed: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmPayment(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null, paymentId: paymentId);
    try {
      // Replace with real payment logic
      state = state.copyWith(isLoading: false, isConfirmed: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final paymentControllerProvider = NotifierProvider<PaymentController, PaymentState>(
  () => PaymentController(),
);
