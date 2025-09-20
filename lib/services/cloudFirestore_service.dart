import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karatly/models/purchaseModel.dart';
import 'package:karatly/models/sellModel.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'gold_purchases';
  final String _sellCollection = 'gold_sell';

  // ✅ UPDATED: Enhanced addPurchase method with payment details
  Future<void> addPurchase(GoldPurchase purchase) async {
    try {
      print('Saving purchase to Firestore: ${purchase.toString()}');

      await _firestore.collection(_collection).add({
        'grams': purchase.grams,
        'buyPricePerGram': purchase.buyPricePerGram,
        'totalCost': purchase.totalCost,
        'purchaseDate': purchase.purchaseDate,

        // ✅ NEW: Added payment-related fields
        'paymentId': purchase.paymentId,
        'orderId': purchase.orderId,
        'paymentStatus': purchase.paymentStatus,

        // ✅ NEW: Additional metadata for better tracking
        'createdAt': FieldValue.serverTimestamp(),
        'version': 2, // Version for future migrations
      });

      print('Purchase saved successfully to Firestore');
    } catch(e) {
      print('Error saving purchase order: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  // ✅ UPDATED: Enhanced getPurchaseStream with payment details
  Stream<List<GoldPurchase>> getPurchaseStream() {
    return _firestore
        .collection(_collection)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          Map<String, dynamic> data = doc.data();

          // ✅ NEW: Using the fromMap factory method for better error handling
          return GoldPurchase.fromMap(data);

        } catch (e) {
          print('Error parsing purchase document ${doc.id}: $e');
          print('Document data: ${doc.data()}');

          // ✅ NEW: Fallback for old documents without payment fields
          Map<String, dynamic> data = doc.data();
          return GoldPurchase(
            grams: (data['grams'] ?? 0).toDouble(),
            buyPricePerGram: (data['buyPricePerGram'] ?? 0).toDouble(),
            totalCost: (data['totalCost'] ?? 0).toDouble(),
            purchaseDate: data['purchaseDate'] != null
                ? (data['purchaseDate'] as Timestamp).toDate()
                : DateTime.now(),
            paymentId: data['paymentId'], // Will be null for old records
            orderId: data['orderId'],     // Will be null for old records
            paymentStatus: data['paymentStatus'] ?? 'completed', // Default for old records
          );
        }
      }).toList();
    });
  }

  // ✅ EXISTING: Sell-related methods (keeping them as they were)
  Future<void> addSell(GoldSell sell) async {
    try{
      await _firestore.collection(_sellCollection).add({
        'gramsSold': sell.grmasSold,
        'sellPricePerGram': sell.sellPricePerGram,
        'totalAmount': sell.totalAmount,
        'sellDate': sell.sellDate,

        // ✅ NEW: Additional metadata
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Sold Successfully');
    }
    catch(e){
      print('Error selling $e');
      rethrow;
    }
  }

  // ✅ UPDATED: Enhanced getTotalGoldOwned with better error handling
  Future<double> getTotalGoldOwned() async {
    double totalPurchased = 0;
    double totalSold = 0;

    try {
      // Get total purchased (only from completed payments)
      QuerySnapshot purchaseSnapshot = await _firestore
          .collection(_collection)
          .where('paymentStatus', isEqualTo: 'completed') // ✅ NEW: Only count completed payments
          .get();

      for (var doc in purchaseSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalPurchased += (data['grams'] ?? 0).toDouble();
      }

      // Also include old records without paymentStatus (assume they're completed)
      QuerySnapshot oldPurchaseSnapshot = await _firestore
          .collection(_collection)
          .where('paymentStatus', isNull: true)
          .get();

      for (var doc in oldPurchaseSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalPurchased += (data['grams'] ?? 0).toDouble();
      }

      // Get total sold
      QuerySnapshot sellSnapShot = await _firestore.collection(_sellCollection).get();
      for (var doc in sellSnapShot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalSold += (data['gramsSold'] ?? 0).toDouble();
      }

      print('Total purchased: $totalPurchased, Total sold: $totalSold');
      return totalPurchased - totalSold;

    } catch (e) {
      print('Error in getTotalGoldOwned: $e');
      return 0.0;
    }
  }

  // ✅ UPDATED: Enhanced getSellStream (keeping existing functionality)
  Stream<List<GoldSell>> getSellStream() {
    return _firestore
        .collection(_sellCollection)
        .orderBy('sellDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return GoldSell(
          grmasSold: (data['gramsSold'] ?? 0).toDouble(),
          sellPricePerGram: (data['sellPricePerGram'] ?? 0).toDouble(),
          totalAmount: (data['totalAmount'] ?? 0).toDouble(),
          sellDate: data['sellDate'] != null
              ? (data['sellDate'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    });
  }

  // ✅ NEW: Method to update payment status (useful for webhook handling)
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('orderId', isEqualTo: orderId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'paymentStatus': paymentStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('Payment status updated for order $orderId: $paymentStatus');
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  // ✅ NEW: Method to get purchases by payment status
  Stream<List<GoldPurchase>> getPurchasesByStatus(String paymentStatus) {
    return _firestore
        .collection(_collection)
        .where('paymentStatus', isEqualTo: paymentStatus)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GoldPurchase.fromMap(doc.data());
      }).toList();
    });
  }

  // ✅ NEW: Method to get purchase statistics
  Future<Map<String, dynamic>> getPurchaseStats() async {
    try {
      QuerySnapshot allPurchases = await _firestore.collection(_collection).get();
      QuerySnapshot completedPurchases = await _firestore
          .collection(_collection)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();
      QuerySnapshot pendingPurchases = await _firestore
          .collection(_collection)
          .where('paymentStatus', isEqualTo: 'pending')
          .get();

      return {
        'totalPurchases': allPurchases.size,
        'completedPurchases': completedPurchases.size,
        'pendingPurchases': pendingPurchases.size,
        'successRate': allPurchases.size > 0
            ? (completedPurchases.size / allPurchases.size * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error getting purchase stats: $e');
      return {
        'totalPurchases': 0,
        'completedPurchases': 0,
        'pendingPurchases': 0,
        'successRate': '0.0',
      };
    }
  }
}
