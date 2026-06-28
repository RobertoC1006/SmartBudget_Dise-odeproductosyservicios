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
  /// Categoría visual cruda del backend (ej. "viaje", "playa", "otros").
  /// La resolución a ilustración vive en la capa de presentación.
  final String categoria;
  final bool recordatorio;
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
    this.categoria = 'otros',
    this.recordatorio = false,
    required this.createdAt,
  });

  /// Progreso 0.0–1.0 calculado contra el monto objetivo.
  double get progreso =>
      montoObjetivo > 0 ? (saldoAcumulado / montoObjetivo).clamp(0.0, 1.0) : 0.0;

  /// Monto que falta para alcanzar la meta (nunca negativo).
  double get faltante =>
      (montoObjetivo - saldoAcumulado).clamp(0.0, double.infinity);

  bool get completada =>
      estado == EstadoMeta.completada || saldoAcumulado >= montoObjetivo;

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      montoObjetivo: json['monto_objetivo'] != null ? (json['monto_objetivo'] as num).toDouble() : 0.0,
      saldoAcumulado: json['saldo_acumulado'] != null ? (json['saldo_acumulado'] as num).toDouble() : 0.0,
      fechaLimite: json['fecha_limite'] != null ? DateTime.parse(json['fecha_limite']) : null,
      estado: _parseEstado(json['estado'] ?? 'pendiente'),
      categoria: json['categoria'] ?? 'otros',
      recordatorio: json['recordatorio'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  /// Payload para crear una meta (coincide con el schema `GoalCreate` del backend).
  Map<String, dynamic> toCreateJson() {
    return {
      'nombre': nombre,
      'monto_objetivo': montoObjetivo,
      'fecha_limite': fechaLimite?.toIso8601String().split('T')[0], // yyyy-MM-dd
      'categoria': categoria,
      'recordatorio': recordatorio,
    };
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
      'recordatorio': recordatorio,
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

/// Un aporte del historial de una meta (alimenta el gráfico de progreso real).
class GoalContributionModel {
  final int id;
  final double monto;

  /// Fecha del aporte elegida por el usuario. El gráfico agrupa por esta fecha.
  final DateTime fecha;

  /// Nota opcional del aporte.
  final String? descripcion;

  /// Timestamp real de inserción (created_at del backend).
  final DateTime createdAt;

  GoalContributionModel({
    required this.id,
    required this.monto,
    required this.fecha,
    this.descripcion,
    required this.createdAt,
  });

  factory GoalContributionModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now();
    return GoalContributionModel(
      id: json['id'] ?? 0,
      monto: json['monto'] != null ? (json['monto'] as num).toDouble() : 0.0,
      // Aportes viejos sin `fecha` caen a created_at (la migración igual los backfillea).
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : createdAt,
      descripcion: json['descripcion'] as String?,
      createdAt: createdAt,
    );
  }
}

/// Resultado de un aporte: meta actualizada + impacto real en el SmartScore.
class ContributeResult {
  final double saldoAcumulado;
  final double montoObjetivo;
  final EstadoMeta estado;
  final int scoreAnterior;
  final int scoreNuevo;
  final int scoreDelta;

  ContributeResult({
    required this.saldoAcumulado,
    required this.montoObjetivo,
    required this.estado,
    required this.scoreAnterior,
    required this.scoreNuevo,
    required this.scoreDelta,
  });

  bool get completada =>
      estado == EstadoMeta.completada || saldoAcumulado >= montoObjetivo;

  factory ContributeResult.fromJson(Map<String, dynamic> json) {
    return ContributeResult(
      saldoAcumulado: (json['saldo_acumulado'] as num?)?.toDouble() ?? 0.0,
      montoObjetivo: (json['monto_objetivo'] as num?)?.toDouble() ?? 0.0,
      estado: GoalModel._parseEstado(json['estado'] ?? 'en_progreso'),
      scoreAnterior: json['score_anterior'] ?? 0,
      scoreNuevo: json['score_nuevo'] ?? 0,
      scoreDelta: json['score_delta'] ?? 0,
    );
  }
}

/// Impacto simulado de un aporte (sin persistir) para la pantalla de Confirmar.
class ContributePreview {
  final int scoreAnterior;
  final int scoreNuevo;
  final int scoreDelta;
  final bool completaria;

  ContributePreview({
    required this.scoreAnterior,
    required this.scoreNuevo,
    required this.scoreDelta,
    required this.completaria,
  });

  factory ContributePreview.fromJson(Map<String, dynamic> json) {
    return ContributePreview(
      scoreAnterior: json['score_anterior'] ?? 0,
      scoreNuevo: json['score_nuevo'] ?? 0,
      scoreDelta: json['score_delta'] ?? 0,
      completaria: json['completaria'] ?? false,
    );
  }
}
