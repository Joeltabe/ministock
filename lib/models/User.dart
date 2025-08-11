import 'dart:typed_data';

class User {
  final String id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final String? permissions;
  final Uint8List? photo;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    this.isActive = true,
    this.lastLogin,
    this.permissions,
    this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'lastLogin': lastLogin?.toIso8601String(),
      'permissions': permissions,
      'photo': photo,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['passwordHash'],
      fullName: map['fullName'],
      role: map['role'],
      isActive: map['isActive'] == 1,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      permissions: map['permissions'],
      photo: map['photo'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? lastLogin,
    String? permissions,
    Uint8List? photo,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      permissions: permissions ?? this.permissions,
      photo: photo ?? this.photo,
    );
  }
}