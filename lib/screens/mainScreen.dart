import 'dart:async';
import 'package:flutter/material.dart';
import 'package:karatly/models/chartModel.dart';
import 'package:karatly/widgets/chartSection.dart';
import 'package:karatly/widgets/infoCard.dart';
import 'package:karatly/widgets/priceChart.dart';
import 'package:karatly/widgets/priceCard.dart';
import '../models/priceModel.dart';
import '../services/apiService.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback? onNavigatetoBuy;
  const MainScreen({Key? key, required this.onNavigatetoBuy}) : super(key: key);

  @override
  State<MainScreen> createState() => _PriceTrackerScreenState();
}

class _PriceTrackerScreenState extends State<MainScreen> {

  GoldPrice? goldPrice;
  bool isLoading = true;
  String errorMessage = '';
  Timer? timer;
  List<PricePoint> _historicalData = [];
  bool _isLoadingChart = true;
  String chartErrorMessage = '';
  Timespan selectedTimespan = Timespan.oneMonth;
  double? _percentageChange;

  final GoldApiService _apiService = GoldApiService();

  @override
  void initState() {
    super.initState();
    fetchAllData();
    timer = Timer.periodic(const Duration(hours: 1), (Timer t) {
      fetchGoldPrice();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchAllData() async {
    await fetchGoldPrice();
    await fetchChartData();
  }

  Future<void> fetchGoldPrice() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final newPriceData = await _apiService.fetchGoldPrice();
      setState(() {
        goldPrice = newPriceData;
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        goldPrice = null;
      });
    }
  }

  Future<void> fetchChartData() async {
    setState(() {
      _isLoadingChart = true;
      chartErrorMessage = '';
      _percentageChange = null;
    });

    try {
      final data = await _apiService.fetchHistoricalData(
        _getDurationForTimeSpan(),
      );
      if (mounted) {
        double? calculatedPercentage;
        if(data.length > 1){
          final firstPrice = data.first.price;
          final lastPrice = data.last.price;
          if(firstPrice !=0){
            calculatedPercentage = ((lastPrice - firstPrice) / firstPrice) * 100;
          }
        }
        setState(() {
          _historicalData = data;
          _percentageChange = calculatedPercentage;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          chartErrorMessage = e.toString().replaceFirst('Exception:', '');
          _isLoadingChart = false;
        });
      }
    }
  }

  Duration _getDurationForTimeSpan() {
    switch (selectedTimespan) {
      case Timespan.oneMonth:
        return const Duration(days: 30);
      case Timespan.sixMonths:
        return const Duration(days: 180);
      case Timespan.oneYear:
        return const Duration(days: 365);
      case Timespan.threeYears:
        return const Duration(days: 365 * 3);
    }
  }

  void _TimeSpanSelected(Timespan timespan) {
    setState(() {
      selectedTimespan = timespan;
    });
    fetchChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/bg_gold.png', height: 50,width: 50,),
            Container(height: 30,width: 2,color: Colors.grey[600]),
            SizedBox(width: 5),
            Text('Karatly', style: TextStyle(
              fontWeight: FontWeight.bold
            ),),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Container(height: 1,width: double.infinity,color: Colors.grey,),
            SizedBox(height: 20),
            PriceInfoCard(
              goldPrice: goldPrice,
              isLoading: isLoading,
              errorMessage: errorMessage,
            ),
        
            SizedBox(height: 20),
        
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: ChartSection(
                isLoadingChart: _isLoadingChart,
                chartErrorMesssage: chartErrorMessage,
                historicalData: _historicalData,
                selectedTimespan: selectedTimespan,
                onTimespanSelected: _TimeSpanSelected,
                percentageChange: _percentageChange,
              ),
            ),
            
            SizedBox(height: 20),
        
            ElevatedButton(
              onPressed: () {
                if(widget.onNavigatetoBuy!=null){
                  widget.onNavigatetoBuy!();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 1), // Remove the default padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Set the border radius
                ),
                backgroundColor: Colors.transparent, // Make the button transparent
                shadowColor: Colors.transparent, // Make the shadow transparent
                overlayColor: Colors.yellow[500]
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.yellow, Colors.black12, Colors.yellow], // Your gradient colors
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12), // Match the button's border radius
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/bg_gold.png', height: 40,width: 50),
                       SizedBox(width: 15),
                       Text(
                        'BUY GOLD',
                        style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
