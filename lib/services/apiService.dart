import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/chartModel.dart';
import '../models/priceModel.dart';

class GoldApiService {
  static const String apiKey = 'fpQXe3f3GDBpxKTB_Pktciejd0EYvX63';
  static const double gramsInTroyOunce = 31.1034768;

  Future<GoldPrice> fetchGoldPrice() async {


    final goldApiUrl =
        'https://api.polygon.io/v2/aggs/ticker/C:XAUUSD/prev?adjusted=true&apiKey=$apiKey';
    final currencyApiUrl =
        'https://api.frankfurter.app/latest?from=USD&to=INR';

    // --- Fetch Gold Price in USD per Ounce ---
    final goldResponse = await http.get(Uri.parse(goldApiUrl));
    if (goldResponse.statusCode != 200) {
      throw Exception('Failed to load gold price. Status code: ${goldResponse.statusCode}');
    }
    final goldData = json.decode(goldResponse.body);

    // --- Fetch USD to INR Exchange Rate ---
    final currencyResponse = await http.get(Uri.parse(currencyApiUrl));
    if (currencyResponse.statusCode != 200) {
      throw Exception('Failed to load currency rate. Status code: ${currencyResponse.statusCode}');
    }
    final currencyData = json.decode(currencyResponse.body);

    if (goldData['results'] != null && goldData['results'].isNotEmpty) {
      final pricePerOunceInUsd = goldData['results'][0]['c'];
      final usdToInrRate = currencyData['rates']['INR'];
      final pricePerGramInInr = (pricePerOunceInUsd / gramsInTroyOunce) * usdToInrRate;

      return GoldPrice(
        pricePerGram: pricePerGramInInr,
        currencySymbol: '₹',
        unit: 'gram',
        lastUpdated: DateTime.now(),
      );


    } else {
      throw Exception('Price data not found in API response.');
    }
  }

  // Inside the ApiService class

  Future<List<PricePoint>> fetchHistoricalData(Duration duration) async {
    // --- Step 1: Calculate Date Range ---
    final to = DateTime.now();
    final from = to.subtract(duration);

    // Format dates into YYYY-MM-DD strings, which the API requires.
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String toDate = formatter.format(to);
    final String fromDate = formatter.format(from);

    // --- Step 2: Construct API URLs ---
    // This endpoint gets daily aggregate bars for a ticker over a date range.
    final historicalApiUrl =
        'https://api.polygon.io/v2/aggs/ticker/C:XAUUSD/range/1/day/$fromDate/$toDate?adjusted=true&sort=asc&apiKey=$apiKey';
    final currencyApiUrl =
        'https://api.frankfurter.app/latest?from=USD&to=INR';

    // --- Step 3: Fetch Data ---
    // Fetch both historical gold data and the latest currency conversion rate.
    final historicalResponse = await http.get(Uri.parse(historicalApiUrl));
    if (historicalResponse.statusCode != 200) {
      throw Exception(
          'Failed to load historical data. Status code: ${historicalResponse.statusCode}');
    }
    final currencyResponse = await http.get(Uri.parse(currencyApiUrl));
    if (currencyResponse.statusCode != 200) {
      throw Exception(
          'Failed to load currency rate. Status code: ${currencyResponse.statusCode}');
    }
    final historicalData = json.decode(historicalResponse.body);
    final currencyData = json.decode(currencyResponse.body);
    final usdToInrRate = currencyData['rates']['INR'];

    // --- Step 4: Process and Return Data ---
    if (historicalData['results'] != null &&
        historicalData['results'].isNotEmpty) {
      // The 'results' key contains a list of daily price bars.
      final List results = historicalData['results'];

      // Map over the list, converting each entry into a PricePoint object.
      return results.map((bar) {
        final pricePerOunceInUsd = bar['c']; // 'c' is the closing price for the day
        final pricePerGramInInr =
            (pricePerOunceInUsd / gramsInTroyOunce) * usdToInrRate;

        // 't' is the timestamp for the day
        final date = DateTime.fromMillisecondsSinceEpoch(bar['t']);

        return PricePoint(date: date, price: pricePerGramInInr);
      }).toList();
    } else {
      // Handle the case where the API returns no data for the requested range.
      return [];
    }
  }
}