import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_flutter/data/models/goal_model.dart';

void main() {
  test('Test parsing goal from backend response', () {
    final mockJsonResponse = {
      "id": 1,
      "nombre": "Eurotrip ✈️",
      "monto_objetivo": 5000.0,
      "saldo_acumulado": 0.0,
      "estado": "en_progreso",
      "porcentaje": 0.0,
      "faltante": 5000.0
    };

    final model = GoalModel.fromJson(mockJsonResponse);
    expect(model.nombre, equals("Eurotrip ✈️"));
    expect(model.userId, equals(0));
  });
}
