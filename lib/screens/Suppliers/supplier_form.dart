import 'package:flutter/material.dart';
import 'package:ministock/models/supplier.dart';
import 'package:intl/intl.dart';
import 'package:ministock/services/DatabaseHelper.dart';

class SupplierFormPage extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;

  late String _id;
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _taxIdController;
  late TextEditingController _creditLimitController;
  late TextEditingController _paymentTermsController;

  @override
  void initState() {
    super.initState();
    _id = widget.supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _contactController = TextEditingController(text: widget.supplier?.contact ?? '');
    _taxIdController = TextEditingController(text: widget.supplier?.taxId ?? '');
    _creditLimitController = TextEditingController(
      text: widget.supplier?.creditLimit?.toString() ?? '',
    );
    _paymentTermsController = TextEditingController(
      text: widget.supplier?.paymentTerms ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _taxIdController.dispose();
    _creditLimitController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 93, 147),
        title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSupplier,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header with business icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, size: 40, color: Colors.pink),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supplier Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Enter supplier details below',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Supplier Name',
                  prefixIcon: const Icon(Icons.business_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Contact Field
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Information',
                  prefixIcon: const Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact information';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Tax ID Field
              TextFormField(
                controller: _taxIdController,
                decoration: InputDecoration(
                  labelText: 'Tax ID',
                  prefixIcon: const Icon(Icons.receipt_long_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              
              // Credit Limit Field
              TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: 'Credit Limit',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixText: 'CFA',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Payment Terms Field
              TextFormField(
                controller: _paymentTermsController,
                decoration: InputDecoration(
                  labelText: 'Payment Terms',
                  prefixIcon: const Icon(Icons.payment_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'e.g., Net 30, COD',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSupplier,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.pink,
                  ),
                  child: const Text(
                    'SAVE SUPPLIER',
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

  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id: _id,
        name: _nameController.text,
        contact: _contactController.text,
        taxId: _taxIdController.text.isEmpty ? null : _taxIdController.text,
        creditLimit: _creditLimitController.text.isEmpty
            ? null
            : double.tryParse(_creditLimitController.text),
        paymentTerms: _paymentTermsController.text.isEmpty
            ? null
            : _paymentTermsController.text,
      );

      try {
        if (widget.supplier == null) {
          await _dbHelper.createSupplier(supplier);
        } else {
          await _dbHelper.updateSupplier(supplier);
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.supplier == null 
                  ? 'Supplier added successfully' 
                  : 'Supplier updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving supplier: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}