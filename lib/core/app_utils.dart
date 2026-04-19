import 'package:intl/intl.dart';

class AppUtils {
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24) {
      if (diff.inHours == 0) {
        final mins = diff.inMinutes;
        return mins <= 1 ? "JUST NOW" : "$mins MINUTES AGO";
      }
      return "${diff.inHours} HOURS AGO";
    } else if (diff.inDays <= 14) {
      final days = diff.inDays;
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      return "$days DAYS AGO ($dateStr)";
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}