import 'package:http/http.dart' as http;
import 'dart:convert';

class RazorPayService {
  static const String _baseUrl = '192.168.1.84';

  Future<String?> createOrder(double totalCost) async {
    try{
      final response  = await http.post(
    Uri.parse('$_baseUrl/create-order'),
        headers: {'Content-type' : 'application/json'},
        body: jsonEncode({'totalCost': totalCost}),
    );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orderId'];
      }
      else{
       print('Error creating order: ${response.body}');
       return null;
      }
    }
    catch (e) {
      print('Exception creating order: $e');
      return null;
    }
  }

  Future<bool> verifyPayment(String orderId, String paaymentId, String signature) async {
    try {
      final resposnse = await http.post(
        Uri.parse('$_baseUrl/verify-signature'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'payment_id': paaymentId,
          'razopay_signature': signature,
        }),
      );
      return resposnse.statusCode == 200;
    }
    catch(e){
      print('Exception verifying payment: $e');
      return false;
    }
  }
}