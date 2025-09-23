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

  // ✅ FIX 1: Corrected controller name from _rupeeContoller to _rupeeController
  late final TextEditingController _rupeeController;
  late final TextEditingController _gramController;

  bool _isTypingRupee = false;
  bool _isTypingGram = false;

  @override
  void initState() {
    super.initState();

    // ✅ FIX 2: Initialize Razorpay with corrected handlers
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // ✅ FIX 3: Fixed controller initialization
    _rupeeController = TextEditingController();
    _gramController = TextEditingController();

    // ✅ FIX 4: Updated all controller references
    _rupeeController.addListener(() {
      if (_selectedOption == 'rupee' && !_isTypingGram) {
        _isTypingRupee = true;
        double? rupees = double.tryParse(_rupeeController.text);
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
    // ✅ FIX 5: Added Razorpay disposal
    _razorpay.clear();
    // ✅ FIX 6: Fixed controller disposal
    _rupeeController.dispose();
    _gramController.dispose();
    super.dispose();
  }

  // ✅ FIX 7: Complete payment success handler with backend verification
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Successful!');

    try {
      // Save the purchase
      if (_pendingPurchase != null && response.paymentId != null) {
        await _firestoreService.addPurchase(GoldPurchase(
          grams: _pendingPurchase!.grams,
          buyPricePerGram: _pendingPurchase!.buyPricePerGram,
          totalCost: _pendingPurchase!.totalCost,
          purchaseDate: _pendingPurchase!.purchaseDate,
          paymentId: response.paymentId,
          orderId: response.orderId,
          paymentStatus: 'completed',
        ));

        if (mounted) {
          // ✅ SIMPLE: Clear inputs and show success message
          _rupeeController.clear();
          _gramController.clear();
          setState(() {
            gramText = '';
            rupeeText = '';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Payment Successful! Gold purchased: ${_pendingPurchase!.grams.toStringAsFixed(4)}g'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // ✅ STAY ON BUYSCREEN - No navigation!
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful but saving failed. Contact support.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      _pendingPurchase = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Failed: ${response.message}');
    _pendingPurchase = null;

    if (mounted) {
      // ✅ SIMPLE: Just show error message and stay on BuyScreen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Payment Failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      // ✅ STAY ON BUYSCREEN - No navigation!
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName}'),
          duration: Duration(seconds: 2),
        ),
      );
      // ✅ STAY ON BUYSCREEN
    }
  }


  // ✅ FIX 12: Complete Razorpay payment initiation method
  void _startRazorpayPayment(double totalCost, GoldPurchase purchase) async {
    print('Starting Razorpay payment for amount: ₹$totalCost');
    _pendingPurchase = purchase;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creating payment order...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final orderData = await _razorPayService.createOrder(totalCost);

      if (orderData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to create payment order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _pendingPurchase = null;
        return;
      }

      print('Order created successfully. Order ID: ${orderData['orderId']}');

      // ✅ FIXED: Clean options without closure
      final options = {
        'key': orderData['key_id'],
        'amount': orderData['amount'],
        'name': 'Karatly Digital Gold',
        'order_id': orderData['orderId'],
        'description': '${purchase.grams.toStringAsFixed(4)}g of Digital Gold',
        'prefill': {
          'contact': '9999999999',
          'email': 'customer@karatly.com'
        },
        'theme': {'color': '#F7CA18'}
      };

      print('✅ Opening Razorpay payment gateway...');
      _razorpay.open(options);

    } catch (e) {
      print('Error starting Razorpay payment: $e');
      _pendingPurchase = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error starting payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

      body: Center(
        child: Stack(
          children: [
            Container(
              height: 440,
              width: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black54.withOpacity(0.6),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  Text(
                    widget.priceData != null
                        ? '${widget.priceData?.formattedPrice}'
                        : 'Price not available',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[600],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'rupee',
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value!;
                            // ✅ FIX 15: Clear controllers with correct names
                            _rupeeController.clear();
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
                            // ✅ FIX 16: Clear controllers with correct names
                            _rupeeController.clear();
                            _gramController.clear();
                            gramText = '';
                            rupeeText = '';
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
                        // ✅ FIX 17: Use correct controller name
                        controller: _rupeeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount in Rupees',
                          border: const OutlineInputBorder(),
                          suffix: gramText.isNotEmpty
                              ? Text(
                            '= $gramText g',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // ✅ FIX 18: Use correct controller name
                            _rupeeController.text = '500';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('500'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _rupeeController.text = '1000';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('1000'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _rupeeController.text = '2000';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('2000'),
                        ),
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
                            '= $rupeeText ₹',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _gramController.text = '5';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('5g'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _gramController.text = '10';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('10g'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _gramController.text = '20';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('20g'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      if (widget.priceData == null) return;

                      // ✅ FIX 19: Fixed grams calculation logic
                      double grams = 0;
                      double priceBeforeTax = 0;

                      if (_selectedOption == 'rupee') {
                        // Use original rupee amount directly for priceBeforeTax to avoid floating point errors
                        priceBeforeTax = double.tryParse(_rupeeController.text) ?? 0;
                        grams = priceBeforeTax / widget.priceData!.pricePerGram;
                      } else {
                        grams = double.tryParse(_gramController.text) ?? 0;
                        priceBeforeTax = grams * widget.priceData!.pricePerGram;
                      }

                      if (priceBeforeTax <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      double tax = priceBeforeTax * 0.03;
                      double totalPrice = priceBeforeTax + tax;

                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        builder: (context) {
                          return Container(
                            height: 450,
                            width: 350,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),

                                  const SizedBox(height: 15),
                                  Container(
                                    height: 60,
                                    width: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.yellow[100],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/bg_gold.png'),
                                        const SizedBox(width: 10),
                                        Text(
                                          // ✅ FIX 20: Use calculated grams variable for display
                                          '${grams.toStringAsFixed(4)} g',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Price before TAX:',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${priceBeforeTax.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'TAX (3%):',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${tax.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        height: 2,
                                        width: 350,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Amount Payable:',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${totalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ✅ FIX 21: Updated button to start Razorpay payment
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context); // Close modal first

                                          // ✅ FIX 22: Create purchase object and start payment
                                          GoldPurchase purchaseToMake = GoldPurchase(
                                            grams: grams,
                                            buyPricePerGram: widget.priceData!.pricePerGram,
                                            totalCost: totalPrice,
                                            purchaseDate: DateTime.now(),
                                          );

                                          // Start Razorpay payment
                                          _startRazorpayPayment(totalPrice, purchaseToMake);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 50,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          backgroundColor: Colors.yellow[300],
                                        ),
                                        child: const Text(
                                          'Pay Now', // ✅ Changed from 'Proceed' to 'Pay Now'
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      overlayColor: Colors.yellow[500],
                    ),

                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.yellow,
                            Colors.black12,
                            Colors.yellow,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/bg_gold.png',
                              height: 40,
                              width: 50,
                            ),
                            const SizedBox(width: 15),
                            const Text(
                              'BUY NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              child: Container(
                height: 30,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: Colors.red[200],
                ),
                child: Center(
                  child: Text(
                    '●  LIVE ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
