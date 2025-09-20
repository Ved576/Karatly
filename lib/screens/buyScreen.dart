import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karatly/models/priceModel.dart';
import 'package:karatly/models/purchaseModel.dart';
import 'package:karatly/services/cloudFirestore_service.dart';
import 'package:karatly/services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BuyScreen extends StatefulWidget {
  final GoldPrice? priceData;
  const BuyScreen({super.key, required this.priceData});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final RazorPayService _razorPayService = RazorPayService();
  late Razorpay _razorpay;

  // This will hold the purchase details while the payment is being processed.
  GoldPurchase? _pendingPurchase;

  String _selectedOption = 'rupee';
  String gramText = '';
  String rupeeText = '';
  late final TextEditingController _rupeeContoller;
  late final TextEditingController _gramController;

  bool _isTypingRupee = false;
  bool _isTypingGram = false;

  @override
  void initState() {
    super.initState();
    _rupeeContoller = TextEditingController();
    _gramController = TextEditingController();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    // Your listener logic is good. No changes needed here.
    _rupeeContoller.addListener(() {
      if (_selectedOption == 'rupee' && !_isTypingGram) {
        _isTypingRupee = true;
        double? rupees = double.tryParse(_rupeeContoller.text);
        if (rupees != null && widget.priceData != null) {
          double grams = rupees / widget.priceData!.pricePerGram;
          setState(() {
            gramText = grams.toStringAsFixed(4);
          });
        } else {
          setState(() {
            gramText = '';
          });
        }
        _isTypingRupee = false;
      }
    });

    _gramController.addListener(() {
      if (_selectedOption == 'gram' && !_isTypingRupee) {
        _isTypingGram = true;
        double? grams = double.tryParse(_gramController.text);
        if (grams != null && widget.priceData != null) {
          double rupees = grams * widget.priceData!.pricePerGram;
          setState(() {
            rupeeText = rupees.toStringAsFixed(2);
          });
        } else {
          setState(() {
            rupeeText = '';
          });
        }
        _isTypingGram = false;
      }
    });
  }

  @override
  void dispose() {
    _rupeeContoller.dispose();
    _gramController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // --- PAYMENT HANDLERS ---
  /// This function runs ONLY when Razorpay confirms a payment was successful.
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Successful on client, Verifying with backend...');

    // 1. VERIFY with your backend.
    bool isVerified = await _razorPayService.verifyPayment(
      response.orderId!,
      response.paymentId!,
      response.signature!,
    );

    // 2. SAVE to database ONLY IF verification is successful.
    if (isVerified && _pendingPurchase != null) {
      print('Payment signature verified. Saving purchase to Firestore...');

      try {
        await _firestoreService.addPurchase(_pendingPurchase!);

        if (mounted) {
          // Clear controllers and show success message.
          _rupeeContoller.clear();
          _gramController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gold Purchased Successfully.'), backgroundColor: Colors.green),
          );

          // Close the bottom sheet.
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error saving to Firestore: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment verified, but failed to save. Please contact support.'), backgroundColor: Colors.orange),
          );
        }
      }

    } else {
      print('Payment verification failed.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed. Please contact support.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
      );
    }
  }

  /// This function creates the order on your backend and opens the Razorpay UI.
  void _startRazorpayPayment(double totalCost, GoldPurchase purchase) async {
    // Store the purchase details temporarily.
    _pendingPurchase = purchase;

    // Create the payment order on your server.
    final orderId = await _razorPayService.createOrder(totalCost);

    if (orderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create payment order. Please try again.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Configure and open the Razorpay payment screen.
    final options = {
      'key': 'rzp_test_ryW0AG51bDcWZc', // Use your public key ID
      'amount': (totalCost * 100).toInt(), // Amount must be in paise
      'name': 'Karatly Digital Gold',
      'order_id': orderId,
      'description': '${purchase.grams.toStringAsFixed(4)}g of Digital Gold',
      'prefill': {'contact': '9099001051', 'email': 'customer@karatly.com'}
    };

    _razorpay.open(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/bg_gold.png', height: 50, width: 50),
            Container(height: 30, width: 2, color: Colors.grey[600]),
            const SizedBox(width: 5),
            const Text('Karatly', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      // --- LAYOUT FIX: Using SingleChildScrollView and Column for a flexible, scrollable layout ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Your card UI can be a separate widget for cleanliness
            _buildBuyCard(),
          ],
        ),
      ),
    );
  }

  /// Helper widget for the main buy card.
  Widget _buildBuyCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black54.withOpacity(0.6),
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allows the "LIVE" banner to show
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
              // --- MINOR BUG FIX: Using the correct property name ---
              Text(
                widget.priceData != null
                    ? 'Live Price: ${widget.priceData!.formattedPrice}'
                    : 'Price not available',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow[600],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'rupee',
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                        _rupeeContoller.clear();
                        _gramController.clear();
                        gramText = '';
                        rupeeText = '';
                      });
                    },
                  ),
                  const Text('Rupees'),
                  Radio<String>(
                    value: 'gram',
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                        _rupeeContoller.clear();
                        _gramController.clear();
                        rupeeText = '';
                        gramText = '';
                      });
                    },
                  ),
                  const Text('Grams'),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedOption == 'rupee') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: TextField(
                    controller: _rupeeContoller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount in Rupees',
                      border: const OutlineInputBorder(),
                      suffix: gramText.isNotEmpty
                          ? Text(
                        '= $gramText gm',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: () => _rupeeContoller.text = '500', child: const Text('500')),
                    ElevatedButton(onPressed: () => _rupeeContoller.text = '1000', child: const Text('1000')),
                    ElevatedButton(onPressed: () => _rupeeContoller.text = '2000', child: const Text('2000')),
                  ],
                ),
              ],
              if (_selectedOption == 'gram') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  child: TextField(
                    controller: _gramController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount in Grams',
                      border: const OutlineInputBorder(),
                      suffix: rupeeText.isNotEmpty
                          ? Text(
                        '= ₹$rupeeText',
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: () => _gramController.text = '5', child: const Text('5g')),
                    ElevatedButton(onPressed: () => _gramController.text = '10', child: const Text('10g')),
                    ElevatedButton(onPressed: () => _gramController.text = '20', child: const Text('20g')),
                  ],
                ),
              ],
              const SizedBox(height: 30),
              _buildBuyNowButton(), // Use a helper for the main button
            ],
          ),
          // Your "LIVE" banner
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                color: Colors.red[200],
              ),
              child: Text(
                '● LIVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for the "BUY NOW" button that triggers the bottom sheet.
  Widget _buildBuyNowButton() {
    return ElevatedButton(
      onPressed: () {
        if (widget.priceData == null) return;

        // Logic to calculate grams and price before showing the summary
        double grams = 0;
        if (_selectedOption == 'rupee') {
          grams = double.tryParse(gramText) ?? 0;
        } else {
          grams = double.tryParse(_gramController.text) ?? 0;
        }

        double priceBeforeTax = grams * widget.priceData!.pricePerGram;

        if (priceBeforeTax <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount')),
          );
          return;
        }

        // Show the order summary in a modal bottom sheet.
        _showOrderSummary(grams, priceBeforeTax);
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero, // Remove padding to allow Ink to fill
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.yellow, Colors.black12, Colors.yellow],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/bg_gold.png', height: 40, width: 50),
              const SizedBox(width: 15),
              const Text('BUY NOW',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the order summary modal bottom sheet.
  void _showOrderSummary(double grams, double priceBeforeTax) {
    double tax = priceBeforeTax * 0.03;
    double totalPrice = priceBeforeTax + tax;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make the sheet only as tall as its content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildSummaryRow('Price before TAX:', '₹${priceBeforeTax.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildSummaryRow('TAX (3%):', '₹${tax.toStringAsFixed(2)}'),
              const Divider(height: 32),
              _buildSummaryRow(
                'Amount Payable:',
                '₹${totalPrice.toStringAsFixed(2)}',
                isTotal: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                // --- CRITICAL FIX: The payment logic is now separated ---
                onPressed: () {
                  GoldPurchase newPurchase = GoldPurchase(
                    grams: grams,
                    buyPricePerGram: widget.priceData!.pricePerGram,
                    totalCost: totalPrice,
                    purchaseDate: DateTime.now(),
                  );
                  // Start the payment process. The save will happen in the success handler.
                  _startRazorpayPayment(totalPrice, newPurchase);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.yellow[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Proceed to Pay',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? Colors.yellow.shade600 : Colors.white,
            fontSize: isTotal ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

}
