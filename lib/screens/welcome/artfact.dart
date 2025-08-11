// Suppliers Page
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/models/supplier.dart';
import 'package:uuid/uuid.dart';

class InventoryPage extends StatefulWidget {
  final List<Article> inventory;
  final Function(Article) onInventoryAdded;

  const InventoryPage({
    required this.inventory,
    required this.onInventoryAdded,
  });

  @override
  InventoryPageState createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _priceWTController;
  late TextEditingController _vatController;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  Uint8List? _imageBytes;
  String _priceTTC = '0.00';

  @override
  void initState() {
    super.initState();
    _priceWTController = TextEditingController();
    _vatController = TextEditingController(text: '20');
    _priceWTController.addListener(_updatePriceTTC);
    _vatController.addListener(_updatePriceTTC);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _referenceController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _typeController.dispose();
    _manufacturerController.dispose();
    _observationsController.dispose();
    _priceWTController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  void _updatePriceTTC() {
    setState(() {
      _priceTTC = _calculatePriceTTC();
    });
  }

  String _calculatePriceTTC() {
    try {
      final priceWT = double.tryParse(_priceWTController.text) ?? 0;
      final vat = double.tryParse(_vatController.text) ?? 0;
      return (priceWT * (1 + vat / 100)).toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  void _addProduct() {
    if (_formKey.currentState!.validate()) {
      final article = Article(
        reference: _referenceController.text.trim(),
        title: _productNameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        type: _typeController.text.trim(),
        category: _categoryController.text.trim(),
        priceWT: double.parse(_priceWTController.text),
        vat: double.parse(_vatController.text),
        priceTTC: double.parse(_priceTTC),
        image: _imageBytes,
        observations: _observationsController.text.trim(),
        manufacturer: _manufacturerController.text.trim().isNotEmpty
            ? _manufacturerController.text.trim()
            : null,
        expiryDate: null,
        batchNumber: null,
        alternativeCodes: [],
      );

      widget.onInventoryAdded(article);

      _formKey.currentState!.reset();
      setState(() {
        _imageBytes = null;
        _priceTTC = '0.00';
      });
    }
  }

  Widget _buildSectionHeader({required IconData icon, required String title, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.pink),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? suffixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          suffixText: suffixText,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) => value!.trim().isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildProductNameField() {
    return _buildInputField(
      controller: _productNameController,
      label: 'Product Name',
      icon: Icons.shopping_bag,
      isRequired: true,
    );
  }

  Widget _buildPriceDisplay() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.price_change, color: Colors.pink),
          const SizedBox(width: 12),
          Text(
            'Price incl. VAT: $_priceTTC €',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: _imageBytes == null
              ? const Icon(Icons.add_a_photo, size: 50, color: Colors.pink)
              : Image.memory(_imageBytes!),
        ),
      ),
    );
  }

Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

  if (pickedImage != null) {
    final bytes = await pickedImage.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.inventory,
            title: 'Add Products',
            subtitle: 'Add your initial inventory items',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildImageUploader(),
                          const SizedBox(height: 24),
                          _buildProductNameField(),
                          _buildInputField(
                            controller: _referenceController,
                            label: 'Product Code',
                            icon: Icons.code,
                            isRequired: true,
                          ),
                          _buildInputField(
                            controller: _barcodeController,
                            label: 'Barcode',
                            icon: Icons.qr_code,
                            isRequired: true,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  controller: _priceWTController,
                                  label: 'Price (excl. tax)',
                                  icon: Icons.attach_money,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  controller: _vatController,
                                  label: 'VAT %',
                                  icon: Icons.percent,
                                  keyboardType: TextInputType.number,
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
                          _buildPriceDisplay(),
                          _buildInputField(
                            controller: _categoryController,
                            label: 'Category',
                            icon: Icons.category,
                          ),
                          _buildInputField(
                            controller: _typeController,
                            label: 'Type',
                            icon: Icons.type_specimen,
                          ),
                          _buildInputField(
                            controller: _manufacturerController,
                            label: 'Manufacturer',
                            icon: Icons.business,
                          ),
                          _buildInputField(
                            controller: _observationsController,
                            label: 'Description',
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _addProduct,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: widget.inventory.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (ctx, index) {
                        final article = widget.inventory[index];
                        return ListTile(
                          leading: article.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(article.image!, width: 50, height: 50, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.inventory),
                          title: Text(article.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Code: ${article.reference}'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Enhanced Completion Page
class CompletionPage extends StatefulWidget {
  final VoidCallback onComplete;

  const CompletionPage({required this.onComplete});

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                size: 120, color: Colors.green),
          ),
          const SizedBox(height: 40),
          Text(
            'Setup Complete!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your inventory management system is ready to use',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.dashboard),
            label: const Text('Go to Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: widget.onComplete,
          ),
        ],
      ),
    );
  }
}