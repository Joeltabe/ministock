// Suppliers Page
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/models/supplier.dart';
import 'package:uuid/uuid.dart';

// Enhanced Suppliers Page
class SuppliersPage extends StatefulWidget {
  final List<Supplier> suppliers;
  final Function(Supplier) onSupplierAdded;

  const SuppliersPage({
    required this.suppliers,
    required this.onSupplierAdded,
  });

  @override
  SuppliersPageState createState() => SuppliersPageState();
}

class SuppliersPageState extends State<SuppliersPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _paymentTermsController = TextEditingController();
    Uint8List? _imageBytes;
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.local_shipping,
            title: 'Add Suppliers',
            subtitle: 'Add your main suppliers and vendors'
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputField(
                  controller: _nameController,
                  label: 'Supplier Name',
                  icon: Icons.business,
                  isRequired: true,
                ),
                _buildInputField(
                  controller: _contactController,
                  label: 'Contact Information',
                  icon: Icons.phone,
                  isRequired: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _taxIdController,
                        label: 'Tax ID',
                        icon: Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _creditLimitController,
                        label: 'Credit Limit',
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        suffixText: 'CFA',
                      ),
                    ),
                  ],
                ),
                _buildInputField(
                  controller: _paymentTermsController,
                  label: 'Payment Terms',
                  icon: Icons.payment,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Supplier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  onPressed: _addSupplier,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: widget.suppliers.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (ctx, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    )
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.business_center, color: Colors.pink),
                  title: Text(
                    widget.suppliers[index].name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.suppliers[index].contact),
                      if (widget.suppliers[index].paymentTerms != null)
                        Text('Terms: ${widget.suppliers[index].paymentTerms!}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.pink),
                    onPressed: () => _editSupplier(index),
                  ),
                ),
              ),
            ),
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
            borderSide: BorderSide(color: Colors.grey[300]!),
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

  void _addSupplier() {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id: Uuid().v4(),
        name: _nameController.text,
        contact: _contactController.text,
        taxId: _taxIdController.text.isEmpty ? null : _taxIdController.text,
        creditLimit: _creditLimitController.text.isEmpty
            ? null
            : double.parse(_creditLimitController.text),
        paymentTerms: _paymentTermsController.text.isEmpty
            ? null
            : _paymentTermsController.text,
      );
      widget.onSupplierAdded(supplier);
      _formKey.currentState!.reset();
    }
  }

  void _editSupplier(int index) {
    // Implementation for editing existing supplier
  }
}
