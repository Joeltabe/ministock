import 'package:bcrypt/bcrypt.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> isFirstUser() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM User')
    );
    return count == 0;
  }
  
  Future<User?> login(String email, String password) async {
    try {
      final db = await _dbHelper.database;
      final users = await db.query(
        'User',
        where: 'username = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (users.isEmpty) return null;

      final user = User.fromMap(users.first);
      final isValid = BCrypt.checkpw(password, user.passwordHash);
      
      if (isValid) {
        await _saveLoginState(user.id);
        return user;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> signUp(User user) async {
    try {
      final isFirst = await isFirstUser();
      final hashedPassword = BCrypt.hashpw(user.passwordHash, BCrypt.gensalt());
      
      final newUser = user.copyWith(
        passwordHash: hashedPassword,
        role: isFirst ? 'owner' : user.role,
      );
      
      await _dbHelper.createUser(newUser);
      await _saveLoginState(newUser.id);
      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<void> _saveLoginState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUserId', userId);
  }

  Future<String?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loggedInUserId');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserId');
  }
}