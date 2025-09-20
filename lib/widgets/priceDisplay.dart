import 'package:flutter/material.dart';
import '../models/priceModel.dart';

class PriceDisplay extends StatelessWidget {
  final GoldPrice? priceData;

  const PriceDisplay({Key? key, required this.priceData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (priceData == null) {
      return const Text("No price data available.",
          style: TextStyle(color: Colors.redAccent, fontSize: 18));
    }
    return Column(
      children: [
        Text(
          priceData!.formattedPrice,
          style: const TextStyle(
              color: Colors.yellow, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
