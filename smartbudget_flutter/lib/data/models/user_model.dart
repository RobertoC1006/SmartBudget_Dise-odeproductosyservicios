enum OcupacionUsuario {
  estudiante,
  trabajadorDependiente,
  trabajadorIndependiente,
  emprendedor,
  otro;

  String get value {
    switch (this) {
      case OcupacionUsuario.estudiante:
        return 'estudiante';
      case OcupacionUsuario.trabajadorDependiente:
        return 'trabajador_dependiente';
      case OcupacionUsuario.trabajadorIndependiente:
        return 'trabajador_independiente';
      case OcupacionUsuario.emprendedor:
        return 'emprendedor';
      case OcupacionUsuario.otro:
        return 'otro';
    }
  }

  String get label {
    switch (this) {
      case OcupacionUsuario.estudiante:
        return 'Estudiante';
      case OcupacionUsuario.trabajadorDependiente:
        return 'Trabajador';
      case OcupacionUsuario.trabajadorIndependiente:
        return 'Independiente';
      case OcupacionUsuario.emprendedor:
        return 'Emprendedor';
      case OcupacionUsuario.otro:
        return 'Otro';
    }
  }

  String get emoji {
    switch (this) {
      case OcupacionUsuario.estudiante:
        return '🎓';
      case OcupacionUsuario.trabajadorDependiente:
        return '💼';
      case OcupacionUsuario.trabajadorIndependiente:
        return '🔧';
      case OcupacionUsuario.emprendedor:
        return '🚀';
      case OcupacionUsuario.otro:
        return '👤';
    }
  }

  static OcupacionUsuario? fromValue(String? value) {
    if (value == null) return null;
    return OcupacionUsuario.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OcupacionUsuario.otro,
    );
  }
}

class UserModel {
  final int id;
  final String nombre;
  final String email;
  final OcupacionUsuario? ocupacion;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.ocupacion,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      ocupacion: OcupacionUsuario.fromValue(json['ocupacion'] as String?),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'ocupacion': ocupacion?.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({OcupacionUsuario? ocupacion}) {
    return UserModel(
      id: id,
      nombre: nombre,
      email: email,
      ocupacion: ocupacion ?? this.ocupacion,
      createdAt: createdAt,
    );
  }
}
