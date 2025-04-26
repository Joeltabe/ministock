import 'package:flutter/material.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/models/purchase.dart';
import 'package:intl/intl.dart';

import '../../models/supplier.dart';

class PurchaseScreen extends StatefulWidget {
  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _referenceController;
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _amountController;
  late TextEditingController _observationsController;
  late TextEditingController _dateController;
  late TextEditingController _supplierIdController;
  late TextEditingController _poNumberController;
  late TextEditingController _deliveryNoteController;
  late TextEditingController _qualityCheckController;
  
  List<Article> _articles = [];
  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;

  // Color scheme matching supplier form
  final Color _primaryColor = Color.fromARGB(255, 255, 179, 66); // Deep Indigo
  final Color _successColor = Color(0xFF4CAF50); // Green
  final Color _errorColor = Color(0xFFF44336); // Red
  final Color _cardBackground = Colors.white;
  final Color _textDark = Color(0xFF212121);
  final Color _textLight = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadArticles();
      _loadSuppliers(); // Add this line

  }

  void _initializeControllers() {
    _referenceController = TextEditingController();
    _titleController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _amountController = TextEditingController();
    _observationsController = TextEditingController();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _supplierIdController = TextEditingController();
  _poNumberController = TextEditingController(text: _generatePurchaseOrderNumber());
  _deliveryNoteController = TextEditingController(text: _generateDeliveryNoteNumber());
    _qualityCheckController = TextEditingController();
  }
// First add this to your state class to track suppliers
List<Supplier> _suppliers = [];
Supplier? _selectedSupplier;

// Add this method to load suppliers
Future<void> _loadSuppliers() async {
  setState(() => _isLoading = true);
  try {
    final suppliers = await DatabaseHelper.instance.readAllSuppliers();
    setState(() {
      _suppliers = suppliers;
      _isLoading = false;
    });
  } catch (e) {
    _showErrorMessage('Failed to load suppliers: ${e.toString()}');
    setState(() => _isLoading = false);
  }
}
  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final articles = await DatabaseHelper.instance.readAllArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorMessage('Failed to load articles: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
// Add these methods to your _PurchaseScreenState class
String _generatePurchaseOrderNumber() {
  final now = DateTime.now();
  return 'PO-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
}

String _generateDeliveryNoteNumber() {
  final now = DateTime.now();
  return 'DN-${now.millisecondsSinceEpoch}';
}
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _calculateAmount() {
    try {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final amount = quantity * price;
      _amountController.text = amount.toStringAsFixed(2);
    } catch (e) {
      _amountController.text = '';
    }
  }

  void _validateSupplier(String? value) {
    if (value == null || value.isEmpty) {
      throw Exception('Supplier ID is required');
    }
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      _validateSupplier(_supplierIdController.text);

      final purchase = Purchase(
        reference: _referenceController.text,
        title: _titleController.text,
        quantity: double.parse(_quantityController.text),
        Bprice: double.parse(_priceController.text),
        amount: double.parse(_amountController.text),
        purchaseDate: _purchaseDate,
        observations: _observationsController.text,
        supplierId: _supplierIdController.text,
        purchaseOrderNumber: _poNumberController.text,
        deliveryNoteNumber: _deliveryNoteController.text,
        qualityCheckBy: _qualityCheckController.text,
      );

      await DatabaseHelper.instance.createPurchase(purchase);
      
      // Update stock
      final currentStock = await DatabaseHelper.instance.getStockQuantity(purchase.reference);
      await DatabaseHelper.instance.updateStock(
        purchase.reference,
        currentStock + purchase.quantity,
      );

      _showSuccessMessage('Purchase recorded successfully');
      _resetForm();
    } catch (e) {
      _showErrorMessage('Error saving purchase: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _quantityController.text = '1';
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _purchaseDate = DateTime.now();
    _supplierIdController.clear();
    _poNumberController.clear();
    _deliveryNoteController.clear();
    _qualityCheckController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Purchase'),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart, size: 40, color: _primaryColor),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Purchase',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              Text(
                                'Record incoming inventory',
                                style: TextStyle(
                                  color: _textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Article selection card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<Article>(
                              decoration: InputDecoration(
                                labelText: 'Article',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.inventory_rounded),
                              ),
                              items: _articles.map((article) {
                                return DropdownMenuItem<Article>(
                                  value: article,
                                  child: Text(
                                    '${article.title} (${article.reference})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (article) {
                                setState(() {
                                  _referenceController.text = article?.reference ?? '';
                                  _titleController.text = article?.title ?? '';
                                  _priceController.text = article?.priceWT.toStringAsFixed(2) ?? '';
                                  _calculateAmount();
                                });
                              },
                              validator: (value) => value == null ? 'Select an article' : null,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _referenceController,
                              decoration: InputDecoration(
                                labelText: 'Reference',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.qr_code_rounded),
                              ),
                              readOnly: true,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.title_rounded),
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Purchase details card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'Purchase Date',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _selectDate(context),
                                ),
                              ),
                              readOnly: true,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (value) => _calculateAmount(),
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: InputDecoration(
                                      labelText: 'Unit Price',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      prefixIcon: Icon(Icons.attach_money_rounded),
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (value) => _calculateAmount(),
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Total Amount',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.calculate_rounded),
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Supplier and additional info card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
// Replace the TextFormField for supplier with this Dropdown
DropdownButtonFormField<Supplier>(
  decoration: InputDecoration(
    labelText: 'Supplier',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.grey[50],
    prefixIcon: Icon(Icons.business_rounded),
  ),
  value: _selectedSupplier,
  items: _suppliers.map((supplier) {
    return DropdownMenuItem<Supplier>(
      value: supplier,
      child: Text(supplier.name),
    );
  }).toList(),
  onChanged: (supplier) {
    setState(() {
      _selectedSupplier = supplier;
      _supplierIdController.text = supplier?.id ?? '';
    });
  },
  validator: (value) => value == null ? 'Please select a supplier' : null,
),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _poNumberController,
                              decoration: InputDecoration(
                                labelText: 'Purchase Order Number',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.confirmation_number_rounded),
                              ),
                              validator: (value) => value!.isEmpty ? 'Required' : null,
                              readOnly: true, // Add this
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _deliveryNoteController,
                              decoration: InputDecoration(
                                labelText: 'Delivery Note Number',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.note_rounded),
                              ),
                              readOnly: true, // Add this
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _qualityCheckController,
                              decoration: InputDecoration(
                                labelText: 'Quality Check By',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.verified_user_rounded),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _observationsController,
                              decoration: InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePurchase,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: _primaryColor,
                        ),
                        child: Text(
                          'SAVE PURCHASE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}