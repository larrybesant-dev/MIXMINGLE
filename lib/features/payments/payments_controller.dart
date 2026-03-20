import 'package:state_notifier/state_notifier.dart';
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

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController() : super(const PaymentState());

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

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
      return PaymentController();
    });
