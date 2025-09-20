import 'package:flutter/material.dart';
import 'package:karatly/widgets/priceDisplay.dart';
import '../models/priceModel.dart';

/// A self-contained card widget that displays the price, loading state,
/// and error messages for the gold price feature.
class PriceInfoCard extends StatelessWidget {
  /// The GoldPrice model object containing price data.
  final GoldPrice? goldPrice;

  /// A boolean to determine if the loading indicator should be shown.
  final bool isLoading;

  /// The error message string, if any, to display.
  final String errorMessage;

  const PriceInfoCard({
    super.key,
    required this.goldPrice,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      // The Container is now the root of the card's visual appearance.
      child: Container(
        height: 170,
        width: 345,
        // The padding is now inside the container to push the content away from the edges.
        padding: const EdgeInsets.all(24.0),
        // The decoration property is used for styling.
        decoration: BoxDecoration(
          // 1. Give it a background color.
          color: const Color(0xFF1E1E1E), // A dark charcoal color
          // 2. Give it rounded corners.
          borderRadius: BorderRadius.circular(16.0),
          // 3. (Optional) Give it a subtle border.
          border: Border.all(
            color: Colors.white12, // A very light grey for the border
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Price (INR/Gram)',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
            )
                : PriceDisplay(priceData: goldPrice),
            const SizedBox(height: 0),
            errorMessage.isNotEmpty
                ? Text(
              errorMessage,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            )
                : Text(
              goldPrice != null
                  ? 'Last Updated: ${goldPrice!.formattedLastUpdated}'
                  : 'Last Updated: N/A',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white60
              ),
            ),
          ],
        ),
      ),
    );
  }
}

