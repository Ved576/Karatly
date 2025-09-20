import 'package:flutter/material.dart';
import 'package:karatly/models/priceModel.dart';
import 'package:karatly/models/sellModel.dart';
import 'package:karatly/services/cloudFirestore_service.dart';

class SellScreen extends StatefulWidget {
  final GoldPrice? priceData;

  const SellScreen({super.key, required this.priceData});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final TextEditingController _gramController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  double availableGold = 0;
  String rupeeText = '';

  @override
  void initState() {
    super.initState();
    // ✅ Fixed: Added parentheses to call the function
    _loadAvailableGold();

    _gramController.addListener(() {
      double? grams = double.tryParse(_gramController.text);
      if(grams != null && widget.priceData != null) {
        double rupees = grams * widget.priceData!.pricePerGram;
        setState(() {
          rupeeText = rupees.toStringAsFixed(2);
        });
      } else {
        setState(() {
          rupeeText = '';
        });
      }
    });
  }

  Future<void> _loadAvailableGold() async {
    try {
      double total = await _firestoreService.getTotalGoldOwned();
      print('Available gold loaded: $total'); // Debug print
      setState(() {
        availableGold = total;
      });
    } catch (e) {
      print('Error loading available gold: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading available gold')),
      );
    }
  }

  // ✅ Helper method for validation error
  String? _getValidationError() {
    double? grams = double.tryParse(_gramController.text);
    if (grams != null && grams > availableGold) {
      return 'Exceeds available gold (${availableGold.toStringAsFixed(4)}g)';
    }
    return null;
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
            Text('Karatly - Sell Gold', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),

      body: Center(
        child: Container(
          height: 500,
          width: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[900],
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Current Price: ${widget.priceData?.formattedPrice ?? "N/A"}',
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              Text('Available Gold: ${availableGold.toStringAsFixed(4)}g',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),

              SizedBox(height: 30),

              // ✅ Conditionally show content based on available gold
              if (availableGold > 0) ...[
                // Enhanced TextField with validation
                TextField(
                  controller: _gramController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Grams to Sell',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow),
                    ),
                    // ✅ Show max available in helper text
                    helperText: 'Max: ${availableGold.toStringAsFixed(4)}g',
                    helperStyle: TextStyle(color: Colors.grey[400]),
                    suffix: rupeeText.isNotEmpty
                        ? Text('= ₹$rupeeText', style: TextStyle(color: Colors.green[300]))
                        : null,
                    // ✅ Show error if exceeds available
                    errorText: _getValidationError(),
                    errorStyle: TextStyle(color: Colors.red[300]),
                  ),
                ),

                SizedBox(height: 20),

                // ✅ Quick Sell Options
                Text('Quick Sell Options:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _gramController.text = (availableGold * 0.25).toStringAsFixed(4);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)
                        ),
                        backgroundColor: Colors.orange[300],
                        padding: EdgeInsets.symmetric(horizontal: 30),
                      ),
                      child: Text('25%', style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _gramController.text = (availableGold * 0.5).toStringAsFixed(4);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)
                        ),
                        backgroundColor: Colors.orange[300],
                        padding: EdgeInsets.symmetric(horizontal: 30),
                      ),
                      child: Text('50%', style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _gramController.text = availableGold.toStringAsFixed(4);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)
                        ),
                        backgroundColor: Colors.red[500],
                        padding: EdgeInsets.symmetric(horizontal: 30),
                      ),
                      child: Text('ALL', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                ElevatedButton(
                    onPressed: () => _showSellConfirmation(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
                      backgroundColor: Colors.yellow[100],
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text('SELL NOW',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[400], fontSize: 20))
                ),
              ],

              // ✅ Show message when no gold is available
              if (availableGold <= 0) ...[
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 50, color: Colors.orange[800]),
                      SizedBox(height: 10),
                      Text(
                        'No Gold Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'You need to buy gold first before you can sell it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to portfolio
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[600],
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        ),
                        child: Text(
                          'Go Back to Portfolio',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSellConfirmation() {
    if(widget.priceData == null) return;

    double gramsToSell = double.tryParse(_gramController.text) ?? 0;

    // ✅ Enhanced validation
    if(gramsToSell <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount (min 0.001g)')),
      );
      return;
    }

    // ✅ FIX: Prevent selling more than available
    if(gramsToSell > availableGold) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Insufficient Gold'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You cannot sell more gold than you own.'),
              SizedBox(height: 10),
              Text('Available: ${availableGold.toStringAsFixed(4)}g',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Requested: ${gramsToSell.toStringAsFixed(4)}g',
                  style: TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // ✅ Auto-correct to maximum available
                _gramController.text = availableGold.toStringAsFixed(4);
              },
              child: Text('Sell All Available'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    double totalAmount = gramsToSell * widget.priceData!.pricePerGram;
    double tax = totalAmount * 0.02;
    double finalAmount = totalAmount - tax;

    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sell Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 15),

                // ✅ Show remaining gold after sale
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current Gold:'),
                          Text('${availableGold.toStringAsFixed(4)}g', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Selling:'),
                          Text('${gramsToSell.toStringAsFixed(4)}g', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${(availableGold - gramsToSell).toStringAsFixed(4)}g',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Payment details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rate:'),
                    Text('₹${widget.priceData!.pricePerGram.toStringAsFixed(2)}/g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gross Amount:'),
                    Text('₹${totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tax (2%):'),
                    Text('-₹${tax.toStringAsFixed(2)}', style: TextStyle(color: Colors.red)),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Final Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹${finalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  ],
                ),

                SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          GoldSell sell = GoldSell(
                            // ✅ Fixed: gramsSold instead of grmasSold
                              grmasSold: gramsToSell,
                              sellPricePerGram: widget.priceData!.pricePerGram,
                              totalAmount: finalAmount,
                              sellDate: DateTime.now()
                          );

                          await _firestoreService.addSell(sell);

                          // ✅ Reload available gold after selling
                          await _loadAvailableGold();

                          Navigator.pop(context);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gold sold successfully! ₹${finalAmount.toStringAsFixed(2)} received.')),
                          );

                          // Clear the input field
                          _gramController.clear();
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error selling gold: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: Text('Confirm Sell', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
    );
  }

  @override
  void dispose() {
    _gramController.dispose();
    super.dispose();
  }
}
