import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) {
    try {
      return DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(date);
    } catch (_) {
      return DateFormat("dd/MM/yyyy").format(date);
    }
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    String timeStr;
    try {
      timeStr = DateFormat('h:mm a', 'es').format(date);
    } catch (_) {
      timeStr = DateFormat('h:mm a').format(date);
    }

    if (checkDate == today) {
      return 'Hoy, $timeStr';
    } else if (checkDate == yesterday) {
      return 'Ayer, $timeStr';
    } else {
      try {
        return '${DateFormat("dd 'de' MMM", 'es').format(date)}, $timeStr';
      } catch (_) {
        return '${DateFormat("dd/MM").format(date)}, $timeStr';
      }
    }
  }
}
