enum CategoriaGasto {
  comida,
  transporte,
  ocio,
  salud,
  educacion,
  ropa,
  hogar,
  tecnologia,
  viajes,
  otros,
}

enum FuenteGasto {
  manual,
  ocrImagen,
  ocrPdf,
}

class ExpenseModel {
  final int id;
  final int userId;
  final CategoriaGasto categoria;
  final double monto;
  final String? descripcion;
  final String? comercio;
  final DateTime fecha;
  final FuenteGasto fuente;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.categoria,
    required this.monto,
    this.descripcion,
    this.comercio,
    required this.fecha,
    required this.fuente,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? 0,
      // El backend no incluye user_id en ExpenseResponse.
      userId: json['user_id'] ?? 0,
      categoria: _parseCategoria(json['categoria']),
      monto: (json['monto'] as num).toDouble(),
      descripcion: json['descripcion'],
      comercio: json['comercio'],
      fecha: DateTime.parse(json['fecha']),
      fuente: _parseFuente(json['fuente']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'categoria': categoria.name,
      'monto': monto,
      'descripcion': descripcion,
      'comercio': comercio,
      'fecha': fecha.toIso8601String().split('T')[0], // yyyy-MM-dd
      'fuente': fuente == FuenteGasto.ocrImagen
          ? 'ocr_imagen'
          : fuente == FuenteGasto.ocrPdf
              ? 'ocr_pdf'
              : 'manual',
      'created_at': createdAt.toIso8601String(),
    };
  }

  static CategoriaGasto _parseCategoria(String val) {
    return CategoriaGasto.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => CategoriaGasto.otros,
    );
  }

  static FuenteGasto _parseFuente(String val) {
    final lowerVal = val.toLowerCase();
    if (lowerVal == 'ocr_imagen') return FuenteGasto.ocrImagen;
    if (lowerVal == 'ocr_pdf') return FuenteGasto.ocrPdf;
    return FuenteGasto.manual;
  }
}
