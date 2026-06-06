enum EstadoMeta {
  pendiente,
  enProgreso,
  completada,
  cancelada,
}

class GoalModel {
  final int id;
  final int userId;
  final String nombre;
  final String? descripcion;
  final double montoObjetivo;
  final double saldoAcumulado;
  final DateTime? fechaLimite;
  final EstadoMeta estado;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.nombre,
    this.descripcion,
    required this.montoObjetivo,
    required this.saldoAcumulado,
    this.fechaLimite,
    required this.estado,
    required this.createdAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      userId: json['user_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      montoObjetivo: (json['monto_objetivo'] as num).toDouble(),
      saldoAcumulado: (json['saldo_acumulado'] as num).toDouble(),
      fechaLimite: json['fecha_limite'] != null ? DateTime.parse(json['fecha_limite']) : null,
      estado: _parseEstado(json['estado']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'descripcion': descripcion,
      'monto_objetivo': montoObjetivo,
      'saldo_acumulado': saldoAcumulado,
      'fecha_limite': fechaLimite?.toIso8601String().split('T')[0], // yyyy-MM-dd
      'estado': estado == EstadoMeta.enProgreso ? 'en_progreso' : estado.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static EstadoMeta _parseEstado(String val) {
    final lowerVal = val.toLowerCase();
    if (lowerVal == 'en_progreso') return EstadoMeta.enProgreso;
    return EstadoMeta.values.firstWhere(
      (e) => e.name == lowerVal,
      orElse: () => EstadoMeta.pendiente,
    );
  }
}
