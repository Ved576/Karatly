import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karatly/models/priceModel.dart';
import 'package:karatly/models/purchaseModel.dart';
import 'package:karatly/services/cloudFirestore_service.dart';

class BuyScreen extends StatefulWidget {
  final GoldPrice? priceData;
  BuyScreen({super.key, required this.priceData});


  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
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
    super.dispose();
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
            SizedBox(width: 5),
            Text('Karatly', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  SizedBox(height: 60),

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

                  SizedBox(height: 20),

                  Row(
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
                          });
                        },
                      ),
                      Text('Rupees'),

                      Radio<String>(
                        value: 'gram',
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value!;
                            _rupeeContoller.clear();
                            _gramController.clear();
                            rupeeText = '';
                          });
                        },
                      ),
                      Text('Grams'),
                    ],
                  ),

                  SizedBox(height: 10),
                  if (_selectedOption == 'rupee') ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26),
                      child: TextField(
                        controller: _rupeeContoller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount in Rupees',
                          border: OutlineInputBorder(),

                          suffix: gramText.isNotEmpty
                              ? Text(
                                  '= $gramText g',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _rupeeContoller.text = '500';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text('500'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _rupeeContoller.text = '1000';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text('1000'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _rupeeContoller.text = '2000';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text('2000'),
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
                          border: OutlineInputBorder(),

                          suffix: rupeeText.isNotEmpty
                              ? Text(
                                  '= $rupeeText ₹',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _gramController.text = '5';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text('5g'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _gramController.text = '10';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text('10g'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            _gramController.text = '20';
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text('20g'),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      if (widget.priceData == null) return;

                      double grams = 0;
                      if (_selectedOption == 'rupee') {
                        // In rupee mode: use calculated gramText
                        grams = double.tryParse(gramText) ?? 0;
                      } else {
                        // In gram mode: use direct input from gram controller
                        grams = double.tryParse(_gramController.text) ?? 0;
                      }

                      double priceBeforeTax = grams * widget.priceData!.pricePerGram;

                      if (priceBeforeTax <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }
                      double tax = priceBeforeTax * 0.03;
                      double totalPrice = priceBeforeTax + tax;

                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        builder: (context) {
                          return Container(
                            height: 450,
                            width: 350,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),

                                  SizedBox(height: 15),
                                  Container(
                                    height: 60,
                                    width: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.yellow[100],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/bg_gold.png'),
                                        SizedBox(width: 10),
                                        Text(
                                          '${grams.toStringAsFixed(4)} g',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 40),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween, // This pushes them apart
                                        children: [
                                          // Widget 1: The label on the left
                                          Text(
                                            'Price before TAX:',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // Widget 2: The price on the right
                                          Text(
                                            '₹${priceBeforeTax.toStringAsFixed(0)}', // Added Rupee symbol
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween, // This pushes them apart
                                        children: [
                                          // Widget 1: The label on the left
                                          Text(
                                            'TAX (3%):',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // Widget 2: The price on the right
                                          Text(
                                            '₹${tax.toStringAsFixed(0)}', // Added Rupee symbol
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        height: 2,
                                        width: 350,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween, // This pushes them apart
                                        children: [
                                          // Widget 1: The label on the left
                                          Text(
                                            'Amount Payable:',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // Widget 2: The price on the right
                                          Text(
                                            '₹${totalPrice.toStringAsFixed(1)}', // Added Rupee symbol
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 30),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Create purchase object
                                          GoldPurchase newPurchase = GoldPurchase(
                                            grams: grams,
                                            buyPricePerGram: widget.priceData!.pricePerGram,
                                            totalCost: totalPrice, // calculated total including tax
                                            purchaseDate: DateTime.now(),
                                          );

                                          // Save to Firestore
                                          await _firestoreService.addPurchase(newPurchase);

                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gold purchased successfully!')),
                                          );
                                          _rupeeContoller.clear();
                                          _gramController.clear();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 50,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          backgroundColor: Colors.yellow[300],
                                        ),
                                        child: Text(
                                          'Proceed',
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 1,
                      ), // Remove the default padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Set the border radius
                      ),
                      backgroundColor:
                          Colors.transparent, // Make the button transparent
                      shadowColor:
                          Colors.transparent, // Make the shadow transparent
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
                            SizedBox(width: 15),
                            Text(
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
                  borderRadius: BorderRadius.only(
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
