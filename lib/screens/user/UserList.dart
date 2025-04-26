import 'package:flutter/material.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/screens/user/UserFormScreen.dart';
import 'package:ministock/services/UserService.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _userService = UserService();
  late Future<List<User>> _usersFuture;
  final Color primaryColor = Color.fromARGB(255, 228, 210, 53);

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _userService.getAllActiveEmployees();
    });
  }

  void _editUser(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(user: user, isEditing: true),
      ),
    );
    if (result == true) _refreshUsers();
  }

  void _addUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserFormScreen()),
    );
    if (result == true) _refreshUsers();
  }

  Future<void> _deactivateUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deactivate Account?'),
        content: Text('This will prevent the user from logging in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _userService.deactivateUser(userId);
      _refreshUsers();
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Accounts'),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshUsers,
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _addUser,
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading users'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No employee accounts found'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    backgroundImage: user.photo != null 
                        ? MemoryImage(user.photo!) 
                        : null,
                    child: user.photo == null
                        ? Icon(Icons.person, color: primaryColor)
                        : null,
                  ),
                  title: Text(
                    user.fullName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '@${user.username} • ${user.role.toUpperCase()}',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor),
                        onPressed: () => _editUser(user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deactivateUser(user.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}