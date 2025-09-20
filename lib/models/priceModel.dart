import 'package:intl/intl.dart';

class GoldPrice {
  final double pricePerGram;
  final String currencySymbol;
  final String unit;
  final DateTime lastUpdated;

  GoldPrice({
    required this.pricePerGram,
    required this.currencySymbol,
    required this.unit,
    required this.lastUpdated,
  });

  String get formattedPrice =>
      '${currencySymbol}${pricePerGram.toStringAsFixed(2)} / $unit';

  String get formattedLastUpdated =>
      DateFormat('dd MMM yyyy, hh:mm:ss a').format(lastUpdated);
}
