import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/sale.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Sale> _sales = [];
  double _totalRevenue = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    _sales = await DatabaseHelper.instance.readAllSales();
    _totalRevenue = _sales.fold(0, (sum, sale) => sum + sale.priceTTC);
    setState(() => _isLoading = false);
  }

List<PieChartSectionData> _prepareCategoryData() {
  final categoryMap = <String, double>{};

  for (final sale in _sales) {
    categoryMap.update(
      sale.title,
      (value) => value + sale.priceTTC,
      ifAbsent: () => sale.priceTTC,
    );
  }

  final total = categoryMap.values.fold(0.0, (a, b) => a + b);
  final List<PieChartSectionData> sections = [];
  int index = 0;

  categoryMap.forEach((title, amount) {
    final color = Colors.primaries[index % Colors.primaries.length];
    sections.add(
      PieChartSectionData(
        color: color,
        value: amount,
        title: '${(amount / total * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
    index++;
  });

  return sections;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reports')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Total Revenue', style: TextStyle(fontSize: 18)),
                          Text('${_totalRevenue.toStringAsFixed(2)} cfa',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Sales by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Container(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: _prepareCategoryData(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    )

                  ),
                  SizedBox(height: 20),
                  Text('Recent Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _sales.take(5).length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return ListTile(
                        title: Text(sale.title),
                        subtitle: Text('Qty: ${sale.quantitySold}'),
                        trailing: Text('${sale.priceTTC.toStringAsFixed(2)} cfa'),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class SalesByCategory {
  final String category;
  final double amount;

  SalesByCategory(this.category, this.amount);
}