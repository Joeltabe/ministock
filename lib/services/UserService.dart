import 'dart:typed_data';

import 'package:bcrypt/bcrypt.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/services/DatabaseHelper.dart';

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a new employee user account
  Future<int> createEmployeeUser({
    required String username,
    required String plainPassword,
    required String fullName,
    required String role,
    String? permissions, Uint8List? photo,
  }) async {
    // Validate role
    final validRoles = ['admin', 'manager', 'cashier', 'stock-keeper'];
    if (!validRoles.contains(role)) {
      throw Exception('Invalid user role');
    }

    // Hash password before storing
    final salt = BCrypt.gensalt();
    final passwordHash = BCrypt.hashpw(plainPassword, salt);

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      passwordHash: passwordHash,
      fullName: fullName,
      role: role,
      permissions: permissions,
    );

    return await _dbHelper.createUser(user);
  }

  // Get user by ID
  Future<User?> getUser(String id) async {
    return await _dbHelper.readUser(id);
  }

  // Get user by username (for login)
  Future<User?> getUserByUsername(String username) async {
    return await _dbHelper.readUserByUsername(username);
  }

  // Get all active employees
  Future<List<User>> getAllActiveEmployees() async {
    final users = await _dbHelper.readAllUsers();
    return users.where((user) => user.isActive).toList();
  }

  // Update user account
  Future<int> updateUserAccount(User user) async {
    // Prevent changing critical fields directly
    final existing = await _dbHelper.readUser(user.id);
    if (existing == null) throw Exception('User not found');
    
    final updatedUser = existing.copyWith(
      fullName: user.fullName,
      role: user.role,
      isActive: user.isActive,
      permissions: user.permissions,
    );
    
    return await _dbHelper.updateUser(updatedUser);
  }

  // Change password
  Future<int> changePassword(String userId, String newPlainPassword) async {
    final salt = BCrypt.gensalt();
    final newHash = BCrypt.hashpw(newPlainPassword, salt);
    
    return await _dbHelper.updateUserPassword(userId, newHash);
  }

  // Deactivate account (soft delete)
  Future<int> deactivateUser(String userId) async {
    final user = await _dbHelper.readUser(userId);
    if (user == null) throw Exception('User not found');
    
    final updatedUser = user.copyWith(isActive: false);
    return await _dbHelper.updateUser(updatedUser);
  }

  // Authenticate user (for login)
  Future<User?> authenticate(String username, String plainPassword) async {
    final user = await _dbHelper.readUserByUsername(username);
    if (user == null || !user.isActive) return null;
    
    final isValid = BCrypt.checkpw(plainPassword, user.passwordHash);
    return isValid ? user : null;
  }
}