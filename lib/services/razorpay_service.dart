import 'package:http/http.dart' as http;
import 'dart:convert';

class RazorPayService {
  static const String _baseUrl = 'https://karatly-backhand-1.onrender.com';

  Future<Map<String, dynamic>?> createOrder(double totalCost) async {
    try {
      print('Creating order for amount: ₹$totalCost');
      print('⏰ This may take up to 45 seconds if server is sleeping...');

      final response = await http.post(
        Uri.parse('$_baseUrl/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'totalCost': totalCost}),
      ).timeout(Duration(seconds: 45)); // ✅ INCREASED TIMEOUT

      print('✅ Server responded! Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'orderId': data['orderId'],
            'amount': data['amount'],
            'currency': data['currency'],
            'key_id': data['key_id'],
          };
        } else {
          print('Backend error: ${data['message']}');
          return null;
        }
      } else {
        print('HTTP Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception creating order: $e');
      if (e.toString().contains('TimeoutException')) {
        print('🔄 Server is sleeping on Render free tier. Please try again.');
      }
      return null;
    }
  }

  Future<bool> verifyPayment(String orderId, String paymentId, String signature) async {
    try {
      print('Verifying payment: OrderID=$orderId, PaymentID=$paymentId');

      final response = await http.post(
        Uri.parse('$_baseUrl/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      ).timeout(Duration(seconds: 30)); // ✅ INCREASED TIMEOUT

      print('Verification response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print('Verification failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception verifying payment: $e');
      return false;
    }
  }
}
