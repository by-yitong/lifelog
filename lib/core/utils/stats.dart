/// 纯函数统计工具：输入某计数器的全部记录（时间, 增量），输出各项统计。
/// 便于单测，也与 UI、数据库解耦。
library;

import '../utils/date_utils.dart';

int sumDeltas(Iterable<(DateTime, int)> entries) =>
    entries.fold(0, (acc, e) => acc + e.$2);

/// 今日计数（今天 0 点以来的增量之和）。
int countToday(List<(DateTime, int)> entries, DateTime now) {
  final from = startOfDay(now);
  return sumDeltas(entries.where((e) => !e.$1.isBefore(from)));
}

int countThisWeek(List<(DateTime, int)> entries, DateTime now) {
  final from = startOfWeek(now);
  return sumDeltas(entries.where((e) => !e.$1.isBefore(from)));
}

int countThisMonth(List<(DateTime, int)> entries, DateTime now) {
  final from = startOfMonth(now);
  return sumDeltas(entries.where((e) => !e.$1.isBefore(from)));
}

/// 连续天数（streak）：从今天往回数有记录的连续自然日数。
/// 今天还没有记录时，从昨天往回数（streak 未断，但今日待完成）。
int streakDays(List<(DateTime, int)> entries, DateTime now) {
  final daysWithRecords = entries
      .where((e) => e.$2 > 0)
      .map((e) => startOfDay(e.$1))
      .toSet();
  if (daysWithRecords.isEmpty) return 0;

  var cursor = startOfDay(now);
  if (!daysWithRecords.contains(cursor)) cursor = addDays(cursor, -1);

  var streak = 0;
  while (daysWithRecords.contains(cursor)) {
    streak++;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

/// 近 [days] 天每日净增量（含今天），旧→新排列，缺的日子补 0，负数按 0 计。
List<(DateTime, int)> dailyCounts(
  List<(DateTime, int)> entries,
  DateTime now,
  int days,
) {
  final today = startOfDay(now);
  final buckets = <DateTime, int>{};
  for (var i = days - 1; i >= 0; i--) {
    buckets[addDays(today, -i)] = 0;
  }
  for (final (at, delta) in entries) {
    final day = startOfDay(at);
    if (buckets.containsKey(day)) {
      buckets[day] = buckets[day]! + delta;
    }
  }
  return [
    for (final e in buckets.entries)
      (e.key, e.value < 0 ? 0 : e.value),
  ];
}
