import 'package:flutter/material.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/sale.dart';
import 'package:intl/intl.dart';
import 'package:ministock/screens/sales/sales_screen.dart';

class SalesListScreen extends StatefulWidget {
  @override
  _SalesListScreenState createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  List<Sale> _sales = [];
  bool _isLoading = false;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
  
  
  // Updated color scheme to match supplier form
  final Color _primaryColor = Color(0xFF4CAF50); // Pink (matches supplier form)
  final Color _salesColor = Color(0xFF4CAF50); // Green
  final Color _cardBackground = Colors.white;
  final Color _textDark = Color(0xFF212121);
  final Color _textLight = Color(0xFF757575);
  final Color _successColor = Color(0xFF4CAF50); // Green
  final Color _errorColor = Color(0xFFF44336); // Red

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await DatabaseHelper.instance.readAllSales();
      setState(() {
        _sales = sales;
        _sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load sales: ${e.toString()}');
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
        title: Text('Sales History'),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : _sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 64,
                        color: _textLight,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No sales recorded',
                        style: TextStyle(
                          fontSize: 18,
                          color: _textLight,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadSales,
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSales,
                  color: _primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return _buildSaleCard(sale);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalesScreen()),
        ).then((_) => _loadSales()),
        backgroundColor: _primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }

 Widget _buildSaleCard(Sale sale) {
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
          // Add sale detail view if needed
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with receipt icon
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: _primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Sale #${sale.invoiceNumber ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    Spacer(),
                    Chip(
                      label: Text(
                        sale.salesType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: _salesColor,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Product info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          sale.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          sale.reference,
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _dateFormat.format(sale.saleDate),
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currencyFormat.format(sale.priceTTC),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Details row
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qty',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          sale.quantitySold.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit Price',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currencyFormat.format(sale.priceWT),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAT (${sale.vatCategory}%)',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currencyFormat.format(sale.priceTTC - sale.priceWT),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              
              // Payment method
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: _textLight),
                  SizedBox(width: 8),
                  Text(
                    'Paid with ${sale.paymentMethod.toString().split('.').last}',
                    style: TextStyle(
                      color: _textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Notes if available
              if (sale.observations != null && sale.observations!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      'Notes:',
                      style: TextStyle(
                        color: _textLight,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      sale.observations!,
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