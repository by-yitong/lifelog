/// 本地时区的"自然日"工具。所有统计以本地日界为准。
library;

DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime addDays(DateTime t, int days) =>
    DateTime(t.year, t.month, t.day + days);

/// 周一为一周开始。
DateTime startOfWeek(DateTime t) {
  final d = startOfDay(t);
  return d.subtract(Duration(days: d.weekday - 1));
}

DateTime startOfMonth(DateTime t) => DateTime(t.year, t.month);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
