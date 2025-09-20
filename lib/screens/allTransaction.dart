import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karatly/services/cloudFirestore_service.dart';

import '../models/purchaseModel.dart';
import '../models/sellModel.dart';

class AllTransaction extends StatelessWidget {
  const AllTransaction({super.key});

  @override
  Widget build(BuildContext context) {  // ✅ FIX: Correct build method signature
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/bg_gold.png', height: 50, width: 50),
            Container(height: 30, width: 2, color: Colors.grey[600]),
            const SizedBox(width: 5),
            const Text(
              'Karatly',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<List<GoldPurchase>>(
        stream: _firestoreService.getPurchaseStream(),
        builder: (context, purchaseSnapshot) {
          if (purchaseSnapshot.hasError) {
            return Center(child: Text('Error loading purchases: ${purchaseSnapshot.error}'));
          }

          return StreamBuilder<List<GoldSell>>(
            stream: _firestoreService.getSellStream(),
            builder: (context, sellSnapshot) {
              if (sellSnapshot.hasError) {
                return Center(child: Text('Error loading sells: ${sellSnapshot.error}'));
              }

              if (purchaseSnapshot.connectionState == ConnectionState.waiting ||
                  sellSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final purchases = purchaseSnapshot.data ?? [];
              final sells = sellSnapshot.data ?? [];

              // ✅ FIX: Combine both purchase and sell data
              List<dynamic> allTransactions = [];

              // Add purchases
              for (var purchase in purchases) {
                allTransactions.add({
                  'type': 'buy',
                  'data': purchase,
                  'date': purchase.purchaseDate,
                });
              }

              // Add sells
              for (var sell in sells) {
                allTransactions.add({
                  'type': 'sell',
                  'data': sell,
                  'date': sell.sellDate,
                });
              }

              // Sort by date (newest first)
              allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

              if (allTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        "No transactions yet",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "BUY YOUR FIRST GOLD",
                        style: TextStyle(
                          color: Colors.yellow[600],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  SizedBox(height: 20),

                  // ✅ FIX: Transaction list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allTransactions.length,
                      itemBuilder: (context, index) {
                        var transaction = allTransactions[index];
                        bool isBuy = transaction['type'] == 'buy';

                        if (isBuy) {
                          GoldPurchase purchase = transaction['data'];
                          return Card(
                            elevation: 3,
                            color: const Color(0xFF2A2A2A),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.shopping_cart, color: Colors.green),
                              ),
                              title: Text(
                                'Bought ${purchase.grams.toStringAsFixed(4)} g',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM d, yyyy • HH:mm').format(purchase.purchaseDate),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  // ✅ FIX: Show payment status if available
                                  if (purchase.paymentStatus != null)
                                    Text(
                                      'Status: ${purchase.paymentStatus}',
                                      style: TextStyle(
                                        color: purchase.paymentStatus == 'completed' ? Colors.green : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${purchase.totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${purchase.buyPricePerGram.toStringAsFixed(0)}/g',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          GoldSell sell = transaction['data'];
                          return Card(
                            elevation: 3,
                            color: const Color(0xFF2A2A2A),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.sell, color: Colors.red),
                              ),
                              title: Text(
                                'Sold ${sell.grmasSold.toStringAsFixed(4)} g', // ✅ FIX: Fixed typo gramsSold
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                DateFormat('MMM d, yyyy • HH:mm').format(sell.sellDate),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${sell.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${sell.sellPricePerGram.toStringAsFixed(0)}/g',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
