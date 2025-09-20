import 'package:http/http.dart' as http;
import 'dart:convert';

class RazorPayService {
  static const String _baseUrl = 'https://karatly-backhand.onrender.com';

  // ✅ FIXED: Complete createOrder method with proper response handling
  Future<Map<String, dynamic>?> createOrder(double totalCost) async {
    try {
      print('Creating order for amount: ₹$totalCost');

      final response = await http.post(
        Uri.parse('$_baseUrl/create-order'),
        headers: {'Content-Type': 'application/json'}, // ✅ Fixed typo
        body: jsonEncode({'totalCost': totalCost}),
      ).timeout(Duration(seconds: 15)); // ✅ Added timeout

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Fixed: Return complete response, not just orderId
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
      print('Exception creating order: $e');
      return null;
    }
  }

  // ✅ FIXED: Corrected method with proper endpoint and parameters
  Future<bool> verifyPayment(String orderId, String paymentId, String signature) async {
    try {
      print('Verifying payment: OrderID=$orderId, PaymentID=$paymentId');

      final response = await http.post(
        Uri.parse('$_baseUrl/verify-payment'), // ✅ Fixed endpoint name
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'payment_id': paymentId, // ✅ Fixed typo
          'razorpay_signature': signature, // ✅ Fixed typo
        }),
      ).timeout(Duration(seconds: 10));

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
