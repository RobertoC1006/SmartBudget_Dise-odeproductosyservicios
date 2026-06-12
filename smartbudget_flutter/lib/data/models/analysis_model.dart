class GoalImpact {
  final String nombre;
  final double montoObjetivo;
  final double saldoAcumulado;
  final double faltanteActual;
  final double porcentajeComprometido;

  GoalImpact({
    required this.nombre,
    required this.montoObjetivo,
    required this.saldoAcumulado,
    required this.faltanteActual,
    required this.porcentajeComprometido,
  });

  factory GoalImpact.fromJson(Map<String, dynamic> json) {
    return GoalImpact(
      nombre: json['nombre'] ?? '',
      montoObjetivo: (json['monto_objetivo'] as num?)?.toDouble() ?? 0.0,
      saldoAcumulado: (json['saldo_acumulado'] as num?)?.toDouble() ?? 0.0,
      faltanteActual: (json['faltante_actual'] as num?)?.toDouble() ?? 0.0,
      porcentajeComprometido: (json['porcentaje_comprometido'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Sim Fase 1: Micro-ahorro Progresivo ─────────────────────────────────────

class MetaImpactoProjection {
  final String nombre;
  final double montoObjetivo;
  final double saldoAcumulado;
  final double faltante;
  final double? mesesParaCompletar;
  final double porcentajeCubierto12m;

  MetaImpactoProjection({
    required this.nombre,
    required this.montoObjetivo,
    required this.saldoAcumulado,
    required this.faltante,
    required this.mesesParaCompletar,
    required this.porcentajeCubierto12m,
  });

  factory MetaImpactoProjection.fromJson(Map<String, dynamic> json) {
    return MetaImpactoProjection(
      nombre: json['nombre'] ?? '',
      montoObjetivo: (json['monto_objetivo'] as num?)?.toDouble() ?? 0.0,
      saldoAcumulado: (json['saldo_acumulado'] as num?)?.toDouble() ?? 0.0,
      faltante: (json['faltante'] as num?)?.toDouble() ?? 0.0,
      mesesParaCompletar: (json['meses_para_completar'] as num?)?.toDouble(),
      porcentajeCubierto12m: (json['porcentaje_cubierto_12m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SavingsProjectionResult {
  final String categoria;
  final double ahorroMensual;
  final double ahorroSemanal;
  final double proyeccion3m;
  final double proyeccion6m;
  final double proyeccion12m;
  final List<MetaImpactoProjection> metaImpacto;
  final String mensaje;

  SavingsProjectionResult({
    required this.categoria,
    required this.ahorroMensual,
    required this.ahorroSemanal,
    required this.proyeccion3m,
    required this.proyeccion6m,
    required this.proyeccion12m,
    required this.metaImpacto,
    required this.mensaje,
  });

  factory SavingsProjectionResult.fromJson(Map<String, dynamic> json) {
    final list = json['meta_impacto'] as List? ?? [];
    return SavingsProjectionResult(
      categoria: json['categoria'] ?? '',
      ahorroMensual: (json['ahorro_mensual'] as num?)?.toDouble() ?? 0.0,
      ahorroSemanal: (json['ahorro_semanal'] as num?)?.toDouble() ?? 0.0,
      proyeccion3m: (json['proyeccion_3m'] as num?)?.toDouble() ?? 0.0,
      proyeccion6m: (json['proyeccion_6m'] as num?)?.toDouble() ?? 0.0,
      proyeccion12m: (json['proyeccion_12m'] as num?)?.toDouble() ?? 0.0,
      metaImpacto: list.map((i) => MetaImpactoProjection.fromJson(i)).toList(),
      mensaje: json['mensaje'] ?? '',
    );
  }
}

// ─── Simulador de Compras (existente) ────────────────────────────────────────

class SimulationResult {
  final bool compraViable;
  final double saldoProyectado;
  final double porcentajeSaldoConsumido;
  final List<GoalImpact> impactoMetas;
  final String mensajeAnalisis;
  final String nivelRiesgo;

  SimulationResult({
    required this.compraViable,
    required this.saldoProyectado,
    required this.porcentajeSaldoConsumido,
    required this.impactoMetas,
    required this.mensajeAnalisis,
    required this.nivelRiesgo,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    var list = json['impacto_metas'] as List? ?? [];
    List<GoalImpact> impacts = list.map((i) => GoalImpact.fromJson(i)).toList();

    return SimulationResult(
      compraViable: json['compra_viable'] ?? false,
      saldoProyectado: (json['saldo_proyectado'] as num?)?.toDouble() ?? 0.0,
      porcentajeSaldoConsumido: (json['porcentaje_saldo_consumido'] as num?)?.toDouble() ?? 0.0,
      impactoMetas: impacts,
      mensajeAnalisis: json['mensaje_analisis'] ?? '',
      nivelRiesgo: json['nivel_riesgo'] ?? 'bajo',
    );
  }
}
