import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordModel {
  final int id;
  final String hashedPassword;
  final int createdAt;
  final int updatedAt;

  PasswordModel({
    required this.id,
    required this.hashedPassword,
    required this.createdAt,
    required this.updatedAt,
  });

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hashed_password': hashedPassword,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PasswordModel.fromMap(Map<String, dynamic> map) {
    return PasswordModel(
      id: map['id'],
      hashedPassword: map['hashed_password'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
