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
