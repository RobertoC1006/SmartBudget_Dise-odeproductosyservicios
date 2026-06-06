class UserModel {
  final int id;
  final String nombre;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
