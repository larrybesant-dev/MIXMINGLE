import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentApi {
  final String baseUrl;

  PaymentApi(this.baseUrl);

  Future<String?> createPaymentIntent(int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      final data = jsonDecode(response.body);

      return data['clientSecret'];
    } catch (e) {
      return null;
    }
  }
}
