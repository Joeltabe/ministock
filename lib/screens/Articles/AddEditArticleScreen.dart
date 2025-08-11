import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/article.dart';

class AddEditArticleScreen extends StatefulWidget {
  final Article? article;

  const AddEditArticleScreen({Key? key, this.article}) : super(key: key);

  @override
  _AddEditArticleScreenState createState() => _AddEditArticleScreenState();
}

class _AddEditArticleScreenState extends State<AddEditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = [];
  
  // Controllers
  late TextEditingController _referenceController;
  late TextEditingController _titleController;
  late TextEditingController _typeController;
  late TextEditingController _categoryController;
  late TextEditingController _priceWTController;
  late TextEditingController _vatController;
  late TextEditingController _observationsController;
  late TextEditingController _barcodeController;
  late TextEditingController _manufacturerController;
  late TextEditingController _batchNumberController;
  late TextEditingController _alternativeCodesController;
  late TextEditingController _expiryDateController;
  
  // State variables
  Uint8List? _imageBytes;
  String _priceTTC = '0.00';
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _calculateInitialPriceTTC();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _referenceController = _createController(widget.article?.reference ?? '');
    _titleController = _createController(widget.article?.title ?? '');
    _typeController = _createController(widget.article?.type ?? '');
    _categoryController = _createController(widget.article?.category ?? '');
    _priceWTController = _createController(widget.article?.priceWT.toString() ?? '');
    _vatController = _createController(widget.article?.vat.toString() ?? '20');
    _observationsController = _createController(widget.article?.observations ?? '');
    _barcodeController = _createController(widget.article?.barcode ?? '');
    _manufacturerController = _createController(widget.article?.manufacturer ?? '');
    _batchNumberController = _createController(widget.article?.batchNumber ?? '');
    _alternativeCodesController = _createController(widget.article?.alternativeCodes?.join(', ') ?? '');
    _expiryDateController = _createController('');
    
    _imageBytes = widget.article?.image;
    
    if (widget.article?.expiryDate != null) {
      _expiryDate = widget.article?.expiryDate;
      _expiryDateController.text = DateFormat('yyyy-MM-dd').format(widget.article!.expiryDate!);
    }

    // Add listeners for real-time price calculation
    _priceWTController.addListener(_updatePriceTTC);
    _vatController.addListener(_updatePriceTTC);
  }

  TextEditingController _createController(String text) {
    final controller = TextEditingController(text: text);
    _controllers.add(controller);
    return controller;
  }

  void _calculateInitialPriceTTC() {
    if (widget.article != null) {
      _priceTTC = (widget.article!.priceWT * (1 + widget.article!.vat/100)).toStringAsFixed(2);
    }
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
      return (priceWT * (1 + vat/100)).toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  Future<void> _pickExpiryDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (selectedDate != null) {
      setState(() {
        _expiryDate = selectedDate;
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final article = Article(
        reference: _referenceController.text.trim(),
        title: _titleController.text.trim(),
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
        expiryDate: _expiryDate,
        batchNumber: _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        alternativeCodes: _alternativeCodesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      if (widget.article == null) {
        await DatabaseHelper.instance.createArticle(article);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product created successfully')));
      } else {
        await DatabaseHelper.instance.updateArticle(article);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')));
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? 'Add Product' : 'Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saveArticle,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),
              
              // Product Identification Section
              _buildSectionHeader('Product Identification'),
              _buildTextField(
                controller: _referenceController,
                label: 'Product Code',
                icon: Icons.qr_code_rounded,
                isRequired: true,
              ),
              _buildTextField(
                controller: _barcodeController,
                label: 'Barcode',
                icon: Icons.qr_code_2_rounded,
                isRequired: true,
              ),
              _buildTextField(
                controller: _titleController,
                label: 'Product Name',
                icon: Icons.title_rounded,
                isRequired: true,
              ),
              
              // Pricing Section
              _buildSectionHeader('Pricing'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceWTController,
                      label: 'Price (excl. tax)',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _vatController,
                      label: 'VAT %',
                      icon: Icons.percent_rounded,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              _buildPriceTTCDisplay(),
              
              // Product Details Section
              _buildSectionHeader('Product Details'),
              _buildTextField(
                controller: _categoryController,
                label: 'Category',
                icon: Icons.category_rounded,
              ),
              _buildTextField(
                controller: _typeController,
                label: 'Type',
                icon: Icons.type_specimen_rounded,
              ),
              _buildTextField(
                controller: _manufacturerController,
                label: 'Manufacturer',
                icon: Icons.business_rounded,
              ),
              _buildTextField(
                controller: _observationsController,
                label: 'Description',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              
              // Inventory Details Section
              _buildSectionHeader('Inventory Details'),
              _buildExpiryDatePicker(),
              _buildTextField(
                controller: _batchNumberController,
                label: 'Batch Number',
                icon: Icons.confirmation_number_rounded,
              ),
              _buildTextField(
                controller: _alternativeCodesController,
                label: 'Alternative Codes (comma-separated)',
                icon: Icons.code_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add product image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) => value!.trim().isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildPriceTTCDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Price (incl. tax)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo[700],
            ),
          ),
          Text(
            '$_priceTTC ${_getCurrencySymbol()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.indigo[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: _pickExpiryDate,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _expiryDateController,
            decoration: InputDecoration(
              labelText: 'Expiry Date',
              prefixIcon: const Icon(Icons.calendar_today_rounded),
              suffixIcon: _expiryDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _expiryDate = null;
                          _expiryDateController.clear();
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrencySymbol() {
    final format = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString());
    return format.currencySymbol;
  }
}