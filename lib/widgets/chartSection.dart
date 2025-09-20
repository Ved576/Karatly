import 'package:flutter/material.dart';
import 'package:karatly/widgets/priceChart.dart';

import '../models/chartModel.dart';

enum Timespan { oneMonth, sixMonths, oneYear, threeYears }

class ChartSection extends StatelessWidget {
  final bool isLoadingChart;
  final String chartErrorMesssage;
  final List<PricePoint> historicalData;
  final Timespan selectedTimespan;
  final Function(Timespan) onTimespanSelected;
  final double? percentageChange;

  const ChartSection({
    super.key,
    required this.isLoadingChart,
    required this.chartErrorMesssage,
    required this.historicalData,
    required this.onTimespanSelected,
    required this.selectedTimespan,
    required this.percentageChange
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          height: 32,
          width: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: _buildPercentageChage(),
        ),
        SizedBox(
          height: 200,
          child: isLoadingChart
            ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow)))
              : chartErrorMesssage.isNotEmpty
            ?Center(
             child: Text(chartErrorMesssage,
    style: const TextStyle(color: Colors.redAccent)))
    : PriceChart(pricePoints: historicalData),
        ),

        SizedBox(height: 15),

        _buildTimeSpanSelector(),

      ],
    );
  }

  Widget _buildTimeSpanSelector(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimespanButton(Timespan.oneMonth, '1M'),
        _buildTimespanButton(Timespan.sixMonths, '6M'),
        _buildTimespanButton(Timespan.oneYear, '1Y'),
        _buildTimespanButton(Timespan.threeYears, '3Y'),
      ],
    );
  }



  Widget _buildTimespanButton(Timespan timespan, String label) {
    final isSelected = selectedTimespan == timespan;
    return TextButton(
      onPressed: () => onTimespanSelected(timespan),
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.black : Colors.yellow.shade700,
        backgroundColor:
        isSelected ? Colors.yellow.shade700 : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.yellow.shade700),
        ),
      ),
      child: Text(label),
    );
  }


  Widget _buildPercentageChage(){
    if (percentageChange == null){
      return SizedBox( height: 25);
    }

    final isPositive = percentageChange! >=0;
    final Color color = isPositive? Colors.green! : Colors.red;
    final IconData icon = isPositive? Icons.arrow_upward : Icons.arrow_downward;
    // final String sign = isPositive? '+' : '-';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20,),
        SizedBox(width: 4,),
        Text('${percentageChange!.toStringAsFixed(2)}%',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

      ],
    );
  }
}
