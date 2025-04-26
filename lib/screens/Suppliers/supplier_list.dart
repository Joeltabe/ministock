// screens/suppliers/supplier_list.dart
import 'package:flutter/material.dart';
import 'package:ministock/screens/Suppliers/supplier_form.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/supplier.dart';


class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  late Future<List<Supplier>> _suppliersFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _refreshSuppliers();
  }

  void _refreshSuppliers() {
    setState(() {
      _suppliersFuture = _dbHelper.readAllSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 93, 147),
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Supplier>>(
        future: _suppliersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No suppliers found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final supplier = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(supplier.name),
                    subtitle: Text(supplier.contact),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navigateToForm(context, supplier),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSupplier(context, supplier.id),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToForm(context, supplier),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _navigateToForm(BuildContext context, [Supplier? supplier]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormPage(supplier: supplier),
      ),
    );

    if (result == true) {
      _refreshSuppliers();
    }
  }

  Future<void> _deleteSupplier(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: const Text('Are you sure you want to delete this supplier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteSupplier(id);
      _refreshSuppliers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier deleted')),
        );
      }
    }
  }
}