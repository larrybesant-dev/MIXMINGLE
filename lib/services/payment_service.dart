class PaymentService {
	Future<void> processPayment(double amount) async {
		throw UnimplementedError(
			'processPayment is not implemented. '
			'Wire PaymentService → Firebase Function → Stripe before enabling payments.',
		);
	}
}
