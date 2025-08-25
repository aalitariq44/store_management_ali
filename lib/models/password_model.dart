class PasswordModel {
  final int id;
  final String password;
  final int createdAt;
  final int updatedAt;

  PasswordModel({
    required this.id,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  static bool verifyPassword(String inputPassword, String storedPassword) {
    return inputPassword == storedPassword;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'password': password,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PasswordModel.fromMap(Map<String, dynamic> map) {
    return PasswordModel(
      id: map['id'],
      password: map['password'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
