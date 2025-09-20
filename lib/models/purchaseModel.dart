class GoldPurchase {
  final double grams;
  final double buyPricePerGram;
  final double totalCost;
  final DateTime purchaseDate;

  // ✅ NEW: Added payment-related fields for Razorpay integration
  final String? paymentId;    // Razorpay payment ID
  final String? orderId;      // Razorpay order ID
  final String paymentStatus; // pending, completed, failed

  GoldPurchase({
    required this.grams,
    required this.buyPricePerGram,
    required this.totalCost,
    required this.purchaseDate,

    // ✅ NEW: Optional payment parameters with default values
    this.paymentId,
    this.orderId,
    this.paymentStatus = 'pending', // Default status
  });

  // ✅ NEW: Helper method to check if payment is completed
  bool get isPaymentCompleted => paymentStatus == 'completed';

  // ✅ NEW: Helper method to get display-friendly payment status
  String get displayPaymentStatus {
    switch (paymentStatus) {
      case 'completed':
        return '✅ Paid';
      case 'pending':
        return '⏳ Pending';
      case 'failed':
        return '❌ Failed';
      default:
        return '❓ Unknown';
    }
  }

  // ✅ NEW: Method to create a copy with updated payment details
  GoldPurchase copyWith({
    double? grams,
    double? buyPricePerGram,
    double? totalCost,
    DateTime? purchaseDate,
    String? paymentId,
    String? orderId,
    String? paymentStatus,
  }) {
    return GoldPurchase(
      grams: grams ?? this.grams,
      buyPricePerGram: buyPricePerGram ?? this.buyPricePerGram,
      totalCost: totalCost ?? this.totalCost,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // ✅ NEW: Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'grams': grams,
      'buyPricePerGram': buyPricePerGram,
      'totalCost': totalCost,
      'purchaseDate': purchaseDate,
      'paymentId': paymentId,
      'orderId': orderId,
      'paymentStatus': paymentStatus,
    };
  }

  // ✅ NEW: Create from Firestore Map
  factory GoldPurchase.fromMap(Map<String, dynamic> map) {
    return GoldPurchase(
      grams: (map['grams'] ?? 0).toDouble(),
      buyPricePerGram: (map['buyPricePerGram'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      purchaseDate: map['purchaseDate']?.toDate() ?? DateTime.now(),
      paymentId: map['paymentId'],
      orderId: map['orderId'],
      paymentStatus: map['paymentStatus'] ?? 'pending',
    );
  }

  @override
  String toString() {
    return 'GoldPurchase(grams: $grams, totalCost: $totalCost, paymentStatus: $paymentStatus, paymentId: $paymentId)';
  }
}
