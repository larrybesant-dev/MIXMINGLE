import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> createPaymentIntent(int amount) async {
  try {
    final response = await http.post(
      Uri.parse('https://us-central1-mix-and-mingle-v2.cloudfunctions.net/createPaymentIntent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount}),
    );
    log('PaymentIntent response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['clientSecret'] as String?;
    } else {
      log('PaymentIntent error: ${response.statusCode} ${response.body}');
      return null;
    }
  } catch (e) {
    log('PaymentIntent exception: $e');
    return null;
  }
}