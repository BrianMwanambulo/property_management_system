import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _baseUrl = 'your-payment-gateway-url';

  static Future<Map<String, dynamic>> initiateMobileMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String reference,
    required String provider, // 'airtel' or 'mtn'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mobile-money/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: json.encode({
          'phone_number': phoneNumber,
          'amount': amount,
          'reference': reference,
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw 'Payment initiation failed: ${response.body}';
      }
    } catch (e) {
      throw 'Payment error: $e';
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment/status/$transactionId'),
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw 'Status check failed: ${response.body}';
      }
    } catch (e) {
      throw 'Status check error: $e';
    }
  }
}