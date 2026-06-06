import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount) {
    final formatter = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatCompact(double amount) {
    final formatter = NumberFormat.compactCurrency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 1);
    return formatter.format(amount);
  }
}
