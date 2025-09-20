import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karatly/formula/portfolioCalculationFormula.dart';
import 'package:karatly/models/purchaseModel.dart';
import 'package:karatly/screens/allTransaction.dart';
import 'package:karatly/screens/sellScreen.dart';
import 'package:karatly/services/cloudFirestore_service.dart';

import '../models/priceModel.dart';
import '../models/sellModel.dart';


class PortfolioScreen extends StatelessWidget {
  final GoldPrice? priceData;
  final VoidCallback? onNavigatetoBuy;
  final FirestoreService _firestoreService = FirestoreService();

  PortfolioScreen({
    super.key,
    required this.priceData,
    required this.onNavigatetoBuy,
  });

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
      body: StreamBuilder<List<GoldPurchase>>(
        stream: _firestoreService.getPurchaseStream(),
        builder: (context, purchaseSnapshot) {
          if (purchaseSnapshot.hasError) {
            return Center(child: Text('Error: ${purchaseSnapshot.error}'));
          }
          if (purchaseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<GoldPurchase> purchases = purchaseSnapshot.data ?? [];

          // ✅ FIX: Add StreamBuilder for sells
          return StreamBuilder<List<GoldSell>>(
            stream: _firestoreService.getSellStream(),
            builder: (context, sellSnapshot) {
              if (sellSnapshot.hasError) {
                return Center(child: Text('Error: ${sellSnapshot.error}'));
              }

              // ✅ FIX: Get actual sells data from Firestore
              List<GoldSell> sells = sellSnapshot.data ?? [];

              if (purchases.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No gold purchased yet'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: onNavigatetoBuy,
                        child: const Text('Buy Your First Gold'),
                      ),
                    ],
                  ),
                );
              }

              // ✅ FIX: Now calculations include actual sells data
              final double currentPricePerGram = priceData?.pricePerGram ?? 0.0;
              double netGoldOwned = PortfolioCalculation.calculateNetGoldOwned(purchases, sells);
              double currentValue = PortfolioCalculation.calculateCurrentValue(purchases, sells, currentPricePerGram);
              double totalInvested = purchases.fold(0.0, (sum, purchase) => sum + purchase.totalCost);
              double profitLoss = currentValue - totalInvested;
              double profitLossPercentage = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

              return Column(
                children: [
                  // 1. The Portfolio Card
                  _buildPortfolioCard(
                    context,
                    currentValue,
                    netGoldOwned,
                    profitLoss,
                    profitLossPercentage,
                  ),

                  // 2. Header for transactions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => AllTransaction()));
                            },
                            child: const Text('View All Transactions'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ FIX: Show combined transactions (both buys and sells)
                  Expanded(
                    child: _buildCombinedTransactionsList(purchases, sells),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

// ✅ NEW: Combined transactions list showing both buys and sells
  Widget _buildCombinedTransactionsList(List<GoldPurchase> purchases, List<GoldSell> sells) {
    // Combine and sort transactions by date
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: min(5, allTransactions.length), // Show last 10 transactions
      itemBuilder: (context, index) {
        var transaction = allTransactions[index];
        bool isBuy = transaction['type'] == 'buy';

        if (isBuy) {
          GoldPurchase purchase = transaction['data'];
          return Card(
            elevation: 5,
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: Text(
                'Bought ${purchase.grams.toStringAsFixed(2)} gm',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                DateFormat('MMM d, yyyy').format(purchase.purchaseDate),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Text(
                '₹${purchase.totalCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              ),
            ),
          );
        } else {
          GoldSell sell = transaction['data'];
          return Card(
            elevation: 5,
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.sell, color: Colors.red),
              title: Text(
                'Sold ${sell.grmasSold.toStringAsFixed(2)} gm',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                DateFormat('MMM d, yyyy').format(sell.sellDate),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Text(
                '₹${sell.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
          );
        }
      },
    );
  }


  /// Helper widget for the main portfolio card for better readability.
  Widget _buildPortfolioCard(
      BuildContext context,
      double currentValue,
      double totalQuantity,
      double profitLoss,
      double profitLossPercentage) {
    return Container(
      height: 200,
      width: double.infinity, // Use double.infinity to fill width
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Portfolio',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 30, // Adjusted size
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${totalQuantity.toStringAsFixed(2)}g',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(height: 20, width: 2, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      '${profitLossPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: profitLoss >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Icon(
                      profitLoss >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: profitLoss >= 0 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(), // Use Spacer to push buttons to the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SellScreen(priceData: priceData)));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 55),
                        backgroundColor: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('SELL'),
                    ),
                    ElevatedButton(
                      onPressed: onNavigatetoBuy,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 55),
                        backgroundColor: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('BUY'),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Image.asset(
                'assets/bg_portfolio.png',
                height: 120,
                width: 120,
              ),
            ),
            // --- PROBLEM AREA REMOVED ---
            // The Expanded(child: ListView.builder(...)) has been moved out of this Stack.
          ],
        ),
      ),
    );
  }
}

