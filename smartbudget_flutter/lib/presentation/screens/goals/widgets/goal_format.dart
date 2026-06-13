import 'package:intl/intl.dart';

/// Utilidades de formato compartidas por el flujo de metas (1A–1D).
class GoalFormat {
  GoalFormat._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'es');

  /// "S/ 1,250.00"
  static String money(double value) => 'S/ ${_money.format(value)}';

  /// Meses que faltan hasta [fechaLimite], redondeando hacia arriba.
  /// Devuelve null si no hay fecha objetivo.
  static int? monthsRemaining(DateTime? fechaLimite) {
    if (fechaLimite == null) return null;
    final now = DateTime.now();
    var months =
        (fechaLimite.year - now.year) * 12 + (fechaLimite.month - now.month);
    // Si el día objetivo ya pasó dentro del mismo mes, no sumamos mes extra;
    // si aún no llega, el mes en curso todavía cuenta.
    if (fechaLimite.day >= now.day) months += 1;
    return months;
  }

  /// Texto del tiempo restante: "6 meses restantes", "1 mes restante",
  /// "Menos de 1 mes" o "Sin fecha objetivo".
  static String remainingLabel(DateTime? fechaLimite) {
    final m = monthsRemaining(fechaLimite);
    if (m == null) return 'Sin fecha objetivo';
    if (m <= 0) return 'Menos de 1 mes';
    if (m == 1) return '1 mes restante';
    return '$m meses restantes';
  }
}
