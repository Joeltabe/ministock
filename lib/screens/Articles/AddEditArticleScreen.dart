import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/article.dart';
class AddEditArticleScreen extends StatefulWidget {
  final Article? article;

  AddEditArticleScreen({this.article});

  @override
  _AddEditArticleScreenState createState() => _AddEditArticleScreenState();
}

class _AddEditArticleScreenState extends State<AddEditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _referenceController;
  late TextEditingController _titleController;
  late TextEditingController _typeController;
  late TextEditingController _categoryController;
  late TextEditingController _priceWTController;
  late TextEditingController _vatController;
  late TextEditingController _observationsController;
  Uint8List? _imageBytes;
  late TextEditingController _barcodeController;
late TextEditingController _manufacturerController;
late TextEditingController _batchNumberController;
late TextEditingController _alternativeCodesController;
late TextEditingController _expiryDateController;
DateTime? _expiryDate;
  String _priceTTC = '0.00'; // Track TTC price as state

  @override
  void initState() {
    super.initState();
    _referenceController = TextEditingController(text: widget.article?.reference ?? '');
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _typeController = TextEditingController(text: widget.article?.type ?? '');
    _categoryController = TextEditingController(text: widget.article?.category ?? '');
    _priceWTController = TextEditingController(text: widget.article?.priceWT.toString() ?? '');
    _vatController = TextEditingController(text: widget.article?.vat.toString() ?? '20');
    _observationsController = TextEditingController(text: widget.article?.observations ?? '');
    _imageBytes = widget.article?.image;

  // New controllers
  _barcodeController = TextEditingController(text: widget.article?.barcode ?? '');
  _manufacturerController = TextEditingController(text: widget.article?.manufacturer ?? '');
  _batchNumberController = TextEditingController(text: widget.article?.batchNumber ?? '');
  _alternativeCodesController = TextEditingController(
    text: widget.article?.alternativeCodes?.join(', ') ?? '',
  );
  _expiryDateController = TextEditingController();
  if (widget.article?.expiryDate != null) {
    _expiryDate = widget.article?.expiryDate;
    _expiryDateController.text = DateFormat('yyyy-MM-dd').format(widget.article!.expiryDate!);
  }
      // Add listeners to update price in real-time
    _priceWTController.addListener(_updatePriceTTC);
    _vatController.addListener(_updatePriceTTC);
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
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

Future<void> _saveArticle() async {
  if (_formKey.currentState!.validate()) {
    try {
      final article = Article(
        reference: _referenceController.text,
        title: _titleController.text,
        barcode: _barcodeController.text,
        type: _typeController.text,
        category: _categoryController.text,
        priceWT: double.parse(_priceWTController.text),
        vat: double.parse(_vatController.text),
        priceTTC: double.parse(_priceWTController.text) * (1 + double.parse(_vatController.text)/100),
        image: _imageBytes,
        observations: _observationsController.text,
        manufacturer: _manufacturerController.text.isNotEmpty ? _manufacturerController.text : null,
        expiryDate: _expiryDate,
        batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
        alternativeCodes: _alternativeCodesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      if (widget.article == null) {
        await DatabaseHelper.instance.createArticle(article);
      } else {
        await DatabaseHelper.instance.updateArticle(article);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving article: ${e.toString()}'),
        ),
      );
    }
  }
}
  String _calculatePriceTTC() {
    try {
      final priceWT = double.parse(_priceWTController.text);
      final vat = double.parse(_vatController.text);
      return (priceWT * (1 + vat/100)).toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? 'Add Product' : 'Edit Product'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveArticle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
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
                            SizedBox(height: 8),
                            Text(
                              'Tap to add image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'Product Code',
                  prefixIcon: Icon(Icons.qr_code_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
    TextFormField(
      controller: _barcodeController,
      decoration: InputDecoration(
        labelText: 'Barcode',
        prefixIcon: Icon(Icons.qr_code_2_rounded),
        border: OutlineInputBorder(),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    ),
    SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.title_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceWTController,
                      decoration: InputDecoration(
                        labelText: 'Price (excl. tax)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                                            onChanged: (_) => _updatePriceTTC(), // Update on change

                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _vatController,
                      decoration: InputDecoration(
                        labelText: 'VAT %',
                        prefixIcon: Icon(Icons.percent_rounded),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                                            onChanged: (_) => _updatePriceTTC(), // Update on change

                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price (incl. tax)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      _priceTTC,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _observationsController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_rounded),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
  SizedBox(height: 16),
    TextFormField(
      controller: _manufacturerController,
      decoration: InputDecoration(
        labelText: 'Manufacturer',
        prefixIcon: Icon(Icons.business_rounded),
        border: OutlineInputBorder(),
      ),
    ),
    SizedBox(height: 16),
    GestureDetector(
      onTap: _pickExpiryDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _expiryDateController,
          decoration: InputDecoration(
            labelText: 'Expiry Date',
            prefixIcon: Icon(Icons.calendar_today_rounded),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _expiryDate = null;
                  _expiryDateController.clear();
                });
              },
            ),
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ),
    SizedBox(height: 16),
    TextFormField(
      controller: _batchNumberController,
      decoration: InputDecoration(
        labelText: 'Batch Number',
        prefixIcon: Icon(Icons.confirmation_number_rounded),
        border: OutlineInputBorder(),
      ),
    ),
    SizedBox(height: 16),
    TextFormField(
      controller: _alternativeCodesController,
      decoration: InputDecoration(
        labelText: 'Alternative Codes (comma-separated)',
        prefixIcon: Icon(Icons.code_rounded),
        border: OutlineInputBorder(),
      ),
    ),

            ],
          ),
        ),
      ),
    );
  }

  // ... (rest of the methods remain the same)
}