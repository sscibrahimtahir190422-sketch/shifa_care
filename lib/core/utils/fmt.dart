import 'package:intl/intl.dart';


class Fmt {
  Fmt._();

  static final _dayKey = DateFormat('yyyy-MM-dd');


  static String dayKey(DateTime d) => _dayKey.format(d);

  static String longDate(DateTime d) => DateFormat('EEEE, d MMMM').format(d);
  static String shortDay(DateTime d) => DateFormat('EEE').format(d);
  static String dayNumber(DateTime d) => DateFormat('d').format(d);
  static String month(DateTime d) => DateFormat('MMM').format(d);

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String wait(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }
}
