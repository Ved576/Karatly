import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karatly/services/cloudFirestore_service.dart';

class AllTransaction extends StatelessWidget {
  const AllTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/bg_gold.png', height: 50, width: 50),
            Container(height: 30, width: 2, color: Colors.grey[600]),
            const SizedBox(width: 5),
            const Text(
              'Karatly',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: _firestoreService.getPurchaseStream(),
        builder: (context, snapshot) {
          if(snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'));
          }

        if(snapshot.connectionState == ConnectionState.waiting){
          return Center(child: CircularProgressIndicator());
        }

        final purchases = snapshot.data ?? [];
        if(purchases.isEmpty){
          return Center(
            child: Text("You've no transaction yet. \n BUY YOUR FIRST GOLD" , style: TextStyle(
              color: Colors.yellow[600],
              fontSize: 25,
              fontWeight: FontWeight.bold
            ),),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: purchases.length,
            itemBuilder: (context, index){
            final purchase = purchases[index];

            final totalCost = purchase.grams * purchase.buyPricePerGram;

            return Card(
              color: Color(0xFF2A2A2A),
              margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: ListTile(
                leading: Icon(Icons.shopping_bag_outlined, color: Colors.yellow,),
                title: Text(
                  'Bought ${purchase.grams.toStringAsFixed(2)}gm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(purchase.purchaseDate),
                ),
                trailing: Text(
                  '₹${totalCost.toStringAsFixed(2)}',style:TextStyle(
                  fontSize: 14,
                  color: Colors.white
                ),
                ),
              ),
            );
            }
        );

        },
      ),
    );
  }
}
