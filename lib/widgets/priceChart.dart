import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chartModel.dart';

class PriceChart extends StatelessWidget {
  final List<PricePoint> pricePoints;

  const PriceChart({super.key, required this.pricePoints});

  @override
  Widget build(BuildContext context) {
    if (pricePoints.isEmpty) {
      return const Center(
        child: Text(
          'No data available.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.all(Radius.circular(25)),
            tooltipPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                final price = spot.y;
                return LineTooltipItem(
                  '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(price)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('MMM d, yyyy').format(date),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                        fontSize: 10
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),

        gridData: FlGridData(show: false),

        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(show: false),

        lineBarsData: [
          LineChartBarData(
            spots: pricePoints
                .map(
                  (point) => FlSpot(
                    point.date.millisecondsSinceEpoch.toDouble(),
                    point.price,
                  ),
                )
                .toList(),
            isCurved: true,
            color: Colors.yellow[600],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomRight,
                colors: [
                  Colors.yellow.shade600.withOpacity(0.3),
                  Colors.yellow.shade600.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: Duration(milliseconds: 250),
    );
  }
}
