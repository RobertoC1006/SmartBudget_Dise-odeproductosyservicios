class SmartScoreModel {
  final int score;

  SmartScoreModel({required this.score});

  factory SmartScoreModel.fromJson(Map<String, dynamic> json) {
    return SmartScoreModel(
      score: json['score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
    };
  }
}

class SmartScoreSnapshotModel {
  final int id;
  final int score;
  final int mes;
  final int anio;
  final DateTime? fechaCalculo;

  SmartScoreSnapshotModel({
    required this.id,
    required this.score,
    required this.mes,
    required this.anio,
    this.fechaCalculo,
  });

  factory SmartScoreSnapshotModel.fromJson(Map<String, dynamic> json) {
    return SmartScoreSnapshotModel(
      id: json['id'],
      score: json['score'],
      mes: json['mes'],
      anio: json['anio'],
      fechaCalculo: json['fecha_calculo'] != null ? DateTime.parse(json['fecha_calculo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'mes': mes,
      'anio': anio,
      'fecha_calculo': fechaCalculo?.toIso8601String(),
    };
  }
}
