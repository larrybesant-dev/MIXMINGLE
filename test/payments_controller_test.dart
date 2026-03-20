import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/payments/payments_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('PaymentsController', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
    });

    test('initiatePayment sets state', () async {
      final controller = container.read(paymentControllerProvider.notifier);
      await controller.initiatePayment(100);
      final state = container.read(paymentControllerProvider);
      expect(state.amount, 100);
      expect(state.error, isNull);
    });

    test('confirmPayment sets state', () async {
      final controller = container.read(paymentControllerProvider.notifier);
      await controller.confirmPayment('payment123');
      final state = container.read(paymentControllerProvider);
      expect(state.paymentId, 'payment123');
      expect(state.isConfirmed, true);
      expect(state.error, isNull);
    });
  });
}
