/// Represents a single data point for the price chart.
class PricePoint {
  /// The date and time for this data point.
  final DateTime date;
  /// The price at this point in time.
  final double price;

  PricePoint({required this.date, required this.price});
}

