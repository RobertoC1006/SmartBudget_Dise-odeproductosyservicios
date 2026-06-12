enum TipoAlerta {
  critica,
  advertencia,
  informativa,
  motivacional,
}

class AlertModel {
  final int id;
  final int userId;
  final String titulo;
  final String mensaje;
  final TipoAlerta tipo;
  final bool leida;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'],
      userId: json['user_id'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      tipo: _parseTipo(json['tipo']),
      leida: json['leida'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.name,
      'leida': leida,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static TipoAlerta _parseTipo(String val) {
    return TipoAlerta.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => TipoAlerta.informativa,
    );
  }
}
