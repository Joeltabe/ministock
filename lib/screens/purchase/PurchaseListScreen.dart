import 'package:flutter/material.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/purchase.dart';
import 'package:intl/intl.dart';
import 'package:ministock/screens/purchase/purchase_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  @override
  _PurchaseListScreenState createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  List<Purchase> _purchases = [];
  bool _isLoading = false;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
  
  // Color scheme
  final Color _primaryColor = Color.fromARGB(255, 255, 179, 66); // Deep Indigo
  final Color _accentColor = Color.fromARGB(255, 255, 206, 132); // Indigo Accent
  final Color _cardBackground = Colors.white;
  final Color _textDark = Color(0xFF212121);
  final Color _textLight = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final purchases = await DatabaseHelper.instance.readAllPurchases();
      setState(() {
        _purchases = purchases;
        _purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load purchases: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase History'),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPurchases,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : _purchases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: _textLight,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No purchases found',
                        style: TextStyle(
                          fontSize: 18,
                          color: _textLight,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadPurchases,
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPurchases,
                  color: _primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) {
                      final purchase = _purchases[index];
                      return _buildPurchaseCard(purchase);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PurchaseScreen()),
        ).then((_) => _loadPurchases()),
        backgroundColor: _primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    final currencyFormat = NumberFormat.currency(symbol: 'CFA ', decimalDigits: 2);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Add purchase detail view if needed
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    purchase.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      purchase.reference,
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                _dateFormat.format(purchase.purchaseDate),
                style: TextStyle(
                  color: _textLight,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          purchase.quantity.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit Price',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(purchase.Bprice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(purchase.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (purchase.observations != null && purchase.observations!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      'Notes:',
                      style: TextStyle(
                        color: _textLight,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      purchase.observations!,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}