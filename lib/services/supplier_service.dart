// services/supplier_service.dart
import 'package:ministock/models/supplier.dart';
import 'package:ministock/services/DatabaseHelper.dart';

class SupplierService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createSupplier(Supplier supplier) => _dbHelper.createSupplier(supplier);
  Future<Supplier?> readSupplier(String id) => _dbHelper.readSupplier(id);
  Future<List<Supplier>> readAllSuppliers() => _dbHelper.readAllSuppliers();
  Future<int> updateSupplier(Supplier supplier) => _dbHelper.updateSupplier(supplier);
  Future<int> deleteSupplier(String id) => _dbHelper.deleteSupplier(id);
}