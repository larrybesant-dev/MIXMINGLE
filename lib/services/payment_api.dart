// PaymentApi placeholder: cloud_functions removed, implement Stripe payment logic here
class PaymentApi {
    static Future<void> notifySuccess({
      required String recipientId,
      required double amount,
    }) async {
      // Example: Notify backend of successful payment
      await Future.delayed(Duration(milliseconds: 300));
      // Implement actual backend notification logic here
    }
  static Future<String> createIntent({
    required double amount,
    required String currency,
    required String recipientId,
  }) async {
    // Example: Call backend REST API to create Stripe payment intent
    // Replace with actual endpoint
    final response = await Future.delayed(Duration(milliseconds: 500), () => {'clientSecret': 'mock_client_secret'});
    return response['clientSecret'] ?? '';
  }
}
