import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount) {
    final isWhole = amount % 1 == 0;
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'S/ ',
      decimalDigits: isWhole ? 0 : 2,
    ).format(amount);
  }

  static String formatCompact(double amount) {
    return NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: 'S/ ',
      decimalDigits: 1,
    ).format(amount);
  }
}
