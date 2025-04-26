import 'package:flutter/material.dart';
import 'package:ministock/models/SaleItem.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/models/sale.dart';
import 'package:ministock/screens/sales/receipt_screen.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  late TextEditingController _referenceController;
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _vatController;
  late TextEditingController _totalController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _dateController;
  late TextEditingController _observationsController;
  late TextEditingController _cashierIdController;
  late TextEditingController _terminalIdController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _paymentMethodController;

  // State variables
  List<Article> _articles = [];
  Article? _selectedArticle;
  String _salesType = 'retail';
  double _availableStock = 0;
  bool _isLoading = false;
  DateTime _saleDate = DateTime.now();
  List<AppliedDiscount> _discounts = [];
  final List<String> _paymentMethods = ['Cash','Mobile Payment'];
  List<User> _cashiers = [];
  User? _selectedCashier;
  List<SaleItem> _cartItems = [];
  double _cartTotal = 0.0;
  double _cartTotalWithTax = 0.0;
  double _cartDiscounts = 0.0;
  double _cartFinalTotal = 0.0;
  
  // Colors
  final Color _primaryColor = Color(0xFF4CAF50); // Pink (matches supplier form)
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
        _loadCashiers(); 

  }

  Future<void> _initializeControllers() async {
    _referenceController = TextEditingController();
    _titleController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _vatController = TextEditingController(text: '18');
    _totalController = TextEditingController();
    _sellingPriceController = TextEditingController();
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_saleDate));
    _observationsController = TextEditingController();
    _cashierIdController = TextEditingController();
    _terminalIdController = TextEditingController();
  _invoiceNumberController = TextEditingController(text: await _generateInvoiceNumber());
    _paymentMethodController = TextEditingController();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final articles = await DatabaseHelper.instance.readAllArticles();
      setState(() => _articles = articles);
    } catch (e) {
      _showErrorSnackbar('Failed to load articles: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // Add this method to load cashiers
Future<void> _loadCashiers() async {
  setState(() => _isLoading = true);
  try {
    final allUsers = await DatabaseHelper.instance.readAllUsers();
    setState(() {
      _cashiers = allUsers.where((user) => 
        ['admin', 'manager', 'cashier'].contains(user.role.toLowerCase()))
        .toList(); // Convert the Iterable to List using toList()
    });
  } catch (e) {
    _showErrorSnackbar('Failed to load cashiers: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}
void _addToCart() {
  if (_selectedArticle == null) {
    _showErrorSnackbar('Please select a product');
    return;
  }

  try {
    final quantity = double.parse(_quantityController.text);
    if (quantity <= 0) {
      _showErrorSnackbar('Quantity must be positive');
      return;
    }

    if (quantity > _availableStock) {
      _showErrorSnackbar('Not enough stock available');
      return;
    }

    setState(() {
      _cartItems.add(SaleItem(
        article: _selectedArticle!,
        quantity: quantity,
        price: double.parse(_priceController.text),
        vat: double.parse(_vatController.text),
        discounts: List.from(_discounts),
      ));
      
      _updateCartTotals();
      _resetProductFields();
    });

  } catch (e) {
    _showErrorSnackbar('Invalid input: ${e.toString()}');
  }
}

void _updateCartTotals() {
  double subtotal = 0;
  double discounts = 0;
  
  for (var item in _cartItems) {
    subtotal += item.subtotal;
    for (var discount in item.discounts) {
      discounts += discount.amount;
    }
  }

  final tax = subtotal * (double.parse(_vatController.text) / 100);
  final total = subtotal + tax - discounts;

  setState(() {
    _cartTotal = subtotal;
    _cartTotalWithTax = subtotal + tax;
    _cartDiscounts = discounts;
    _cartFinalTotal = total;
  });
}

void _resetProductFields() {
  _selectedArticle = null;
  _referenceController.clear();
  _titleController.clear();
  _quantityController.text = '1';
  _priceController.clear();
  _discounts.clear();
}
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _saleDate) {
      setState(() {
        _saleDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateStockInfo(String reference) async {
    try {
      final stock = await DatabaseHelper.instance.getStockQuantity(reference);
      setState(() => _availableStock = stock);
    } catch (e) {
      _showErrorSnackbar('Failed to check stock: ${e.toString()}');
    }
  }

  void _calculateTotal() {
    try {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final vat = double.parse(_vatController.text);
      final total = quantity * price * (1 + vat / 100);
      setState(() {
        _totalController.text = total.toStringAsFixed(2);
        _sellingPriceController.text = total.toStringAsFixed(2);
      });
    } catch (e) {
      setState(() {
        _totalController.text = '';
        _sellingPriceController.text = '';
      });
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
// Generate invoice number format: SHOPYYMMDDXXXX
Future<String> _generateInvoiceNumber() async {
  final now = DateTime.now();
  final prefix = "INV"; // Customize with your shop initials
  final datePart = DateFormat('yyMMdd').format(now);
  
  // Get the last sequence number
  final lastNumber = await _getLastInvoiceSequence();
  final sequence = (lastNumber + 1).toString().padLeft(4, '0');
  
  return '$prefix$datePart$sequence'; // Example: INV2406150001
}
void _saveAsDraft() async {
  if (_cartItems.isEmpty) {
    _showErrorSnackbar('Cannot save an empty cart as draft');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final draft = {
      'items': _cartItems.map((item) => {
        'reference': item.article.reference,
        'title': item.article.title,
        'quantity': item.quantity,
        'price': item.price,
        'vat': item.vat,
        'discounts': item.discounts.map((d) => d.toMap()).toList(),
      }).toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'total': _cartFinalTotal,
      'cashierId': _selectedCashier?.id,
      'paymentMethod': _paymentMethodController.text,
      'notes': _observationsController.text,
    };

    await DatabaseHelper.instance.saveDraftSale(draft);
    
    _showSuccessSnackbar('Draft saved successfully');
    _clearCart(); // Clear cart after saving draft
  } catch (e) {
    _showErrorSnackbar('Failed to save draft: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

void _clearCart() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear Cart'),
      content: const Text('Are you sure you want to remove all items from the cart?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _cartItems.clear();
              _updateCartTotals();
              Navigator.pop(context);
            });
            _showSuccessSnackbar('Cart cleared');
          },
          child: const Text('Clear', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _removeFromCart(SaleItem item) {
  setState(() {
    _cartItems.remove(item);
    _updateCartTotals();
    _showSuccessSnackbar('${item.article.title} removed from cart');
  });
}

void _showSuccessSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
Future<int> _getLastInvoiceSequence() async {
  final db = await DatabaseHelper.instance.database;
  final result = await db.rawQuery(
    'SELECT invoiceNumber FROM Sales ORDER BY id DESC LIMIT 1'
  );
  
  if (result.isEmpty) return 0;
  
  final lastInvoice = result.first['invoiceNumber'] as String;
  // Extract the last 4 digits (sequence part)
  return int.tryParse(lastInvoice.substring(lastInvoice.length - 4)) ?? 0;
}
  void _showAddDiscountDialog() {
    TextEditingController typeController = TextEditingController();
    TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Discount Type'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: valueController,
              decoration: InputDecoration(labelText: 'Discount Value'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isNotEmpty && valueController.text.isNotEmpty) {
                setState(() {
                  _discounts.add(AppliedDiscount(
                    discountId: DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: double.parse(valueController.text),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
void _showRecentSales() async {
  setState(() => _isLoading = true);
  
  try {
    final recentSales = await DatabaseHelper.instance.getRecentSales();
    
    if (recentSales.isEmpty) {
      _showInfoSnackbar('No recent sales found');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Sales',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: recentSales.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sale = recentSales[index];
                  final date = DateTime.parse(sale['sale_date']);
                  final total = sale['priceTTC'] as double;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt, color: Colors.green),
                    ),
                    title: Text(sale['title']),
                    subtitle: Text(
                      '${DateFormat('MMM d, y • HH:mm').format(date)}\n'
                      'Invoice: ${sale['invoiceNumber']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: 'XAF ').format(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${sale['quantitySold']} × ${NumberFormat.currency(symbol: 'XAF ').format(sale['priceWT'])}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    onTap: () => _viewSaleDetails(sale),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    _showErrorSnackbar('Failed to load recent sales: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

void _viewSaleDetails(Map<String, dynamic> sale) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Sale Details - ${sale['invoiceNumber']}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Date:', DateFormat('MMM d, y • HH:mm').format(DateTime.parse(sale['sale_date']))),
            _buildDetailRow('Product:', sale['title']),
            _buildDetailRow('Reference:', sale['reference']),
            _buildDetailRow('Quantity:', sale['quantitySold'].toString()),
            _buildDetailRow('Unit Price:', NumberFormat.currency(symbol: 'XAF ').format(sale['priceWT'])),
            _buildDetailRow('VAT:', '${sale['vatCategory']}%'),
            _buildDetailRow('Total:', NumberFormat.currency(symbol: 'XAF ').format(sale['priceTTC'])),
            _buildDetailRow('Payment Method:', sale['paymentMethod']),
            if (sale['observations'] != null && sale['observations'].isNotEmpty)
              _buildDetailRow('Notes:', sale['observations']),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

void _showInfoSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
Future<void> _processSale() async {
  if (_cartItems.isEmpty) {
    _showErrorSnackbar('Please add items to cart');
    return;
  }

  if (_selectedCashier == null) {
    _showErrorSnackbar('Please select a cashier');
    return;
  }

  setState(() => _isLoading = true);
  final invoiceNumber = await _generateInvoiceNumber();

  try {
    // Process each item in the cart
    for (var item in _cartItems) {
      final sale = Sale(
        salesType: _salesType,
        reference: item.article.reference,
        title: item.article.title,
        quantitySold: item.quantity,
        priceWT: item.price,
        vatCategory: item.vat.toString(),
        priceTTC: item.total,
        sellingPrice: item.total.toString(),
        observations: _observationsController.text,
        saleDate: _saleDate,
        cashierId: _cashierIdController.text,
        terminalId: _terminalIdController.text,
        invoiceNumber: invoiceNumber,
        discounts: item.discounts,
        paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.toString().split('.').last == _paymentMethodController.text,
          orElse: () => PaymentMethod.cash,
        ),
      );

      await DatabaseHelper.instance.createSale(sale);
      
      // Update stock
      final currentStock = await DatabaseHelper.instance.getStockQuantity(item.article.reference);
      await DatabaseHelper.instance.updateStock(
        item.article.reference,
        currentStock - item.quantity,
      );
    }

    // Show receipt
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>ReceiptScreen(
  sales: _cartItems.map((item) => Sale(
    id: null, // Will be auto-generated by database
    salesType: _salesType,
    reference: item.article.reference,
    title: item.article.title,
    quantitySold: item.quantity,
    priceWT: item.price,
    vatCategory: item.vat.toString(),
    priceTTC: item.total,
    sellingPrice: item.total.toString(),
    observations: _observationsController.text,
    saleDate: _saleDate,
    cashierId: _selectedCashier!.id,
    terminalId: _terminalIdController.text,
    invoiceNumber: invoiceNumber,
    discounts: item.discounts,
    paymentMethod: PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == _paymentMethodController.text,
      orElse: () => PaymentMethod.cash,
    ),
  )).toList(),
  invoiceNumber: invoiceNumber,
  cashierName: _selectedCashier!.fullName,
  paymentMethod: _paymentMethodController.text,
  date: _saleDate,
  total: _cartFinalTotal,
)
      ),
    );

    // Reset form
    _resetForm();

  } catch (e) {
    _showErrorSnackbar('Failed to process sale: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _resetForm() {
    _quantityController.text = '1';
    _vatController.text = '18';
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _saleDate = DateTime.now();
    _observationsController.clear();
    _discounts.clear();
    _cashierIdController.clear();
    _terminalIdController.clear();
    _invoiceNumberController.clear();
    _paymentMethodController.clear();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('New Sale'),
      backgroundColor: _primaryColor,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: _showRecentSales,
          tooltip: 'Sales History',
        ),
      ],
    ),
    body: _isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          )
        : Column(
            children: [
              // Header with quick info
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cashier: ${_selectedCashier?.fullName ?? "Not selected"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, y • HH:mm').format(_saleDate),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: ${NumberFormat.currency(symbol: 'XAF ').format(_cartFinalTotal)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${_cartItems.length} items',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Product Selection
                        _buildProductSelectionCard(),
                        const SizedBox(height: 16),

                        // Current Cart
                        _buildCartCard(),
                        const SizedBox(height: 16),

                        // Payment Section
                        _buildPaymentSection(),
                        const SizedBox(height: 16),

                        // Notes
                        _buildNotesCard(),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer with action buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saveAsDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: _primaryColor),
                        ),
                        child: Text(
                          'SAVE DRAFT',
                          style: TextStyle(color: _primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _processSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('COMPLETE SALE'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

Widget _buildProductSelectionCard() {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Product',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Article>(
            decoration: InputDecoration(
              labelText: 'Search product',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            onChanged: (article) async {
              if (article != null) {
                setState(() {
                  _selectedArticle = article;
                  _referenceController.text = article.reference;
                  _titleController.text = article.title;
                  _priceController.text = article.priceWT.toStringAsFixed(2);
                  _vatController.text = article.vat.toString();
                });
                await _updateStockInfo(article.reference);
                _calculateTotal();
              }
            },
            validator: (value) => value == null ? 'Select a product' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _calculateTotal(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _calculateTotal(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(
                  'Stock: $_availableStock',
                  style: TextStyle(
                    color: _availableStock > 0 ? Colors.green : Colors.red,
                  ),
                ),
                backgroundColor: Colors.grey[100],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildCartCard() {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_cartItems.isNotEmpty)
                TextButton(
                  onPressed: _clearCart,
                  child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _cartItems.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No items added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ..._cartItems.map((item) => Dismissible(
                          key: Key(item.article.reference),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red[50],
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (direction) => _removeFromCart(item),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, color: Colors.grey),
                            ),
                            title: Text(item.article.title),
                            subtitle: Text(
                              '${item.quantity} × ${NumberFormat.currency(symbol: 'XAF ').format(item.price)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              NumberFormat.currency(symbol: 'XAF ').format(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        )),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          _buildTotalRow('Subtotal:', _cartTotal),
                          _buildTotalRow('Tax:', _cartTotalWithTax - _cartTotal),
                          if (_cartDiscounts > 0)
                            _buildTotalRow('Discounts:', -_cartDiscounts, isDiscount: true),
                          const Divider(height: 16),
                          _buildTotalRow('TOTAL:', _cartFinalTotal, isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    ),
  );
}

Widget _buildPaymentSection() {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<User>(
            value: _selectedCashier,
            decoration: const InputDecoration(
              labelText: 'Cashier',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: _cashiers.map((user) {
              return DropdownMenuItem<User>(
                value: user,
                child: Text('${user.fullName} (${user.role})'),
              );
            }).toList(),
            onChanged: (user) {
              setState(() {
                _selectedCashier = user;
                _cashierIdController.text = user?.id ?? '';
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _invoiceNumberController,
            decoration: const InputDecoration(
              labelText: 'Invoice Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt),
            ),
            readOnly: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment),
            ),
            items: _paymentMethods
                .map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    ))
                .toList(),
            onChanged: (value) => _paymentMethodController.text = value!,
          ),
          const SizedBox(height: 12),
          if (_discounts.isNotEmpty) ...[
            const Text(
              'Applied Discounts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._discounts.map((discount) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.discount, color: Colors.orange),
                  title: Text(discount.discountId),
                  trailing: Text(
                    '-${NumberFormat.currency(symbol: 'XAF ').format(discount.amount)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                )),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _showAddDiscountDialog,
            icon: const Icon(Icons.discount),
            label: const Text('Add Discount'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNotesCard() {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _observationsController,
            decoration: const InputDecoration(
              hintText: 'Add any special instructions...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),
        ],
      ),
    ),
  );
}

Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.red : null,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: 'XAF ').format(amount),
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.red : (isTotal ? Colors.green : null),
          ),
        ),
      ],
    ),
  );
}
}

