// User Info Page
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ministock/Service/AuthService.dart';
import 'package:ministock/models/User.dart';

class UserInfoPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final User user;
  final Function(User) onSave;
  final bool isLoginMode;

  const UserInfoPage({
    required this.formKey,
    required this.user,
    required this.onSave,
    this.isLoginMode = false,
  });

  @override
  UserInfoPageState createState() => UserInfoPageState();
}

class UserInfoPageState extends State<UserInfoPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _photoBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.fullName;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _photoBytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            // Profile Photo
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _photoBytes != null 
                    ? MemoryImage(_photoBytes!) 
                    : null,
                child: _photoBytes == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            SizedBox(height: 8),
            Text('Add Profile Photo', style: TextStyle(color: Colors.grey)),

            SizedBox(height: 24),
            Text(
              widget.isLoginMode ? 'Login' : 'Create Admin Account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                filled: true,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _passController,
              decoration: InputDecoration(
                labelText: 'Create Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                filled: true,
              ),
              obscureText: true,
              validator: (v) => v!.length < 8 ? 'Minimum 8 characters' : null,
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _confirmPassController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                filled: true,
              ),
              obscureText: true,
              validator: (v) => v != _passController.text ? 'Passwords must match' : null,
            ),
            
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text('Create Admin Account'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

Future<void> _handleSubmit() async {
  if (!widget.formKey.currentState!.validate()) return;
  
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final authService = AuthService();
  final user = widget.user.copyWith(
    fullName: _nameController.text,
    username: _emailController.text,
    passwordHash: _passController.text,
    role: 'owner',
    photo: _photoBytes,
    isActive: true,
  );

  try {
    final success = await authService.signUp(user);
    if (success) {
      widget.onSave(user);
      
      // Clear fields
      _nameController.clear();
      _emailController.clear();
      _passController.clear();
      _confirmPassController.clear();
      setState(() {
        _photoBytes = null;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin account created successfully!')),
      );
    } else {
      setState(() => _errorMessage = 'Email already in use');
    }
  } catch (e) {
    setState(() => _errorMessage = 'An error occurred: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
}