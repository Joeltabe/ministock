import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/services/UserService.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;
  final bool isEditing;

  UserFormScreen({this.user, this.isEditing = false});

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _passwordController;
  String _selectedRole = 'cashier';
  bool _isActive = true;
  Uint8List? _photoBytes; // For storing photo
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role ?? 'cashier';
    _isActive = widget.user?.isActive ?? true;
   _photoBytes = widget.user?.photo;

  }
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _photoBytes = bytes;
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.isEditing && widget.user != null) {
          await _userService.updateUserAccount(
            widget.user!.copyWith(
              fullName: _fullNameController.text,
              role: _selectedRole,
              isActive: _isActive,
              photo: _photoBytes,
            ),
          );
        } else {
          await _userService.createEmployeeUser(
            username: _usernameController.text,
            plainPassword: _passwordController.text,
            fullName: _fullNameController.text,
            role: _selectedRole,
            photo: _photoBytes,
          );
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color.fromARGB(255, 228, 210, 53); // Match your theme
    final Color cardBackground = Colors.grey[50]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Employee' : 'New Employee'),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 40, color: primaryColor),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing ? 'Edit Employee' : 'New Employee',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'Manage employee account details',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Photo Upload Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: cardBackground,
                          backgroundImage: _photoBytes != null 
                              ? MemoryImage(_photoBytes!) 
                              : null,
                          child: _photoBytes == null
                              ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                              : null,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Account Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: cardBackground,
                          prefixIcon: Icon(Icons.person),
                        ),
                        enabled: !widget.isEditing,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      if (!widget.isEditing) ...[
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: cardBackground,
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (!widget.isEditing && value!.isEmpty) {
                              return 'Required';
                            }
                            if (value!.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: cardBackground,
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        items: ['admin', 'manager', 'cashier', 'stock-keeper']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedRole = value!),
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: cardBackground,
                          prefixIcon: Icon(Icons.verified_user),
                        ),
                      ),
                      if (widget.isEditing) ...[
                        SizedBox(height: 16),
                        SwitchListTile(
                          title: Text('Account Active'),
                          value: _isActive,
                          onChanged: (value) => setState(() => _isActive = value),
                          tileColor: cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: primaryColor,
                  ),
                  child: Text(
                    'SAVE EMPLOYEE',
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
  }}