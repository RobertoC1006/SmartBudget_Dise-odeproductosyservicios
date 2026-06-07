class BudgetModel {
  final int id;
  final int userId;
  final int mes;
  final int anio;
  final double montoBase;
  final double ingresosAdicionales;
  final double totalGastado;
  final double saldoDisponible;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.mes,
    required this.anio,
    required this.montoBase,
    required this.ingresosAdicionales,
    required this.totalGastado,
    required this.saldoDisponible,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      mes: json['mes'],
      anio: json['anio'],
      montoBase: (json['monto_base'] as num).toDouble(),
      ingresosAdicionales: (json['ingresos_adicionales'] as num).toDouble(),
      totalGastado: (json['total_gastado'] as num).toDouble(),
      saldoDisponible: (json['saldo_disponible'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mes': mes,
      'anio': anio,
      'monto_base': montoBase,
      'ingresos_adicionales': ingresosAdicionales,
      'total_gastado': totalGastado,
      'saldo_disponible': saldoDisponible,
    };
  }
}
