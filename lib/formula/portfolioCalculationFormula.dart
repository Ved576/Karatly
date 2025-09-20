import 'package:flutter/material.dart';
import 'package:karatly/models/purchaseModel.dart';
import 'package:karatly/models/sellModel.dart';

class PortfolioCalculation{
  static double calculateNetGoldOwned(List<GoldPurchase> purchases, List<GoldSell> sells) {
    double totalPurchased = purchases.fold(0, (sum, purchase) => sum + purchase.grams);
    double totalSold  = sells.fold(0, (sum, sell) => sum + sell.grmasSold);
    return totalPurchased - totalSold;
  }

  static double calculateAverageBuyPrice(List<GoldPurchase> purchases, List<GoldSell> sells) {
    double totalCost = purchases.fold(0, (sum, purchase) => sum + purchase.totalCost);
    double  totalSellAmount = sells.fold(0, (sum, sell) => sum + sell.totalAmount);
    double netCost = totalCost - totalSellAmount;
    double netGold = calculateNetGoldOwned(purchases, sells);
    return netGold > 0 ? netCost / netGold : 0;
  }

  static double calculateCurrentValue(List<GoldPurchase> purchases, List<GoldSell> sells, double currentPricePerGram) {
    double netGold = calculateNetGoldOwned(purchases, sells);
    return netGold * currentPricePerGram;
  }

  static double calculateRealizedProfit(List<GoldPurchase> purchases, List<GoldSell> sells) {
    double totalSellAmount = sells.fold(0, (sum, sell) => sum + sell.totalAmount);
    double avgPrice = calculateAverageBuyPrice(purchases, []);
    double totalSoldGrams = sells.fold(0, (sum, sell) => sum + sell.grmasSold);
    double costOfSoldGrams = totalSoldGrams * avgPrice;
    return totalSellAmount - costOfSoldGrams;
  }
}