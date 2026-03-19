import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/payments/payments_controller.dart';

void main() {
  group('PaymentsController', () {
    late PaymentsController controller;

    setUp(() {
      controller = PaymentsController();
    });

    test('initiatePayment sets state', () async {
      await controller.initiatePayment(100);
      expect(controller.state, isNotNull);
      expect(controller.error, isNull);
    });

    test('confirmPayment sets state', () async {
      await controller.confirmPayment('payment123');
      expect(controller.state, isNotNull);
      expect(controller.error, isNull);
    });

    test('handleError sets error', () {
      controller.handleError('Test error');
      expect(controller.error, 'Test error');
    });
  });
}
