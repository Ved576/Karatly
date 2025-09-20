import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karatly/models/purchaseModel.dart';
import 'package:karatly/models/sellModel.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'gold_purchases';
  final String _sellCollection = 'gold_sell';

  Future<void> addPurchase(GoldPurchase purchase) async {
    try {
      await _firestore.collection(_collection).add({
        'grams': purchase.grams,
        'buyPricePerGram': purchase.buyPricePerGram,
        'totalCost': purchase.totalCost,
        'purchaseDate': purchase.purchaseDate
      });
      print('Purchased Successfully');
    }
    catch(e){
      print('Error saving purchase order: $e');
    }
  }

  Future<void> addSell(GoldSell sell) async {
    try{
      await _firestore.collection(_sellCollection).add({
        // ✅ FIX 1: Fixed typo - gramsSold instead of grmasSold
        'gramsSold': sell.grmasSold,
        'sellPricePerGram': sell.sellPricePerGram,
        'totalAmount': sell.totalAmount,
        'sellDate': sell.sellDate,
      });
      print('Sold Successfully');
    }
    catch(e){
      print('Error selling $e');
    }
  }

  Future<double> getTotalGoldOwned() async {
    double totalPurchased = 0;
    double totalSold = 0;

    try {
      QuerySnapshot purchaseSnapshot = await _firestore.collection(_collection).get();
      for (var doc in purchaseSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalPurchased += (data['grams'] ?? 0).toDouble();
      }

      QuerySnapshot sellSnapShot = await _firestore.collection(_sellCollection).get();
      for (var doc in sellSnapShot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // ✅ FIX 2: Added null safety check
        totalSold += (data['gramsSold'] ?? 0).toDouble();
      }

      print('Total purchased: $totalPurchased, Total sold: $totalSold'); // Debug
      return totalPurchased - totalSold;
    } catch (e) {
      print('Error in getTotalGoldOwned: $e');
      return 0.0;
    }
  }

  Stream<List<GoldPurchase>> getPurchaseStream() {
    return _firestore
        .collection(_collection)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return GoldPurchase(
            grams: data['grams'],
            buyPricePerGram: data['buyPricePerGram'],
            purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
            totalCost: data['totalCost']
        );
      }).toList();
    });
  }

  Stream<List<GoldSell>> getSellStream() {
    return _firestore
        .collection(_sellCollection)
        .orderBy('sellDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return GoldSell(
          // ✅ FIX 3: Fixed typo - gramsSold instead of grmasSold
            grmasSold: data['gramsSold'],
            sellPricePerGram: data['sellPricePerGram'],
            totalAmount: data['totalAmount'],
            sellDate: (data['sellDate'] as Timestamp).toDate()
        );
      }).toList();
    });
  }
}
