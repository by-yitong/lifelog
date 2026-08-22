import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/core/utils/date_utils.dart';
import 'package:lifelog/core/utils/stats.dart';

void main() {
  final now = DateTime(2026, 8, 22, 15, 0); // 周六下午

  List<(DateTime, int)> entriesOf(List<(DateTime, int)> raw) => raw;

  group('countToday / week / month', () {
    test('只累计对应时间窗内的增量', () {
      final entries = entriesOf([
        (DateTime(2026, 8, 22, 9, 0), 3), // 今天
        (DateTime(2026, 8, 21, 20, 0), 2), // 昨天
        (DateTime(2026, 8, 17, 8, 0), 4), // 本周一
        (DateTime(2026, 8, 10, 8, 0), 5), // 上周
        (DateTime(2026, 7, 31, 8, 0), 6), // 上月
      ]);

      expect(countToday(entries, now), 3);
      expect(countThisWeek(entries, now), 9); // 周一(17日) 起：3+2+4
      expect(countThisMonth(entries, now), 14);
    });

    test('负增量会抵消', () {
      final entries = entriesOf([
        (DateTime(2026, 8, 22, 9, 0), 3),
        (DateTime(2026, 8, 22, 12, 0), -1),
      ]);
      expect(countToday(entries, now), 2);
    });

    test('空记录为 0', () {
      expect(countToday([], now), 0);
      expect(countThisWeek([], now), 0);
      expect(countThisMonth([], now), 0);
    });
  });

  group('streakDays', () {
    test('连续多天', () {
      final entries = entriesOf([
        (DateTime(2026, 8, 22, 8, 0), 1),
        (DateTime(2026, 8, 21, 8, 0), 1),
        (DateTime(2026, 8, 20, 8, 0), 2),
        (DateTime(2026, 8, 18, 8, 0), 1), // 断档
      ]);
      expect(streakDays(entries, now), 3);
    });

    test('今天没记但从昨天连续，streak 未断', () {
      final entries = entriesOf([
        (DateTime(2026, 8, 21, 8, 0), 1),
        (DateTime(2026, 8, 20, 8, 0), 1),
      ]);
      expect(streakDays(entries, now), 2);
    });

    test('纯负增量不算打卡', () {
      final entries = entriesOf([
        (DateTime(2026, 8, 22, 8, 0), -1),
      ]);
      expect(streakDays(entries, now), 0);
    });

    test('空记录为 0', () {
      expect(streakDays([], now), 0);
    });
  });

  group('dailyCounts', () {
    test('补零且旧→新排列，忽略负增量', () {
      final entries = entriesOf([
        (DateTime(2026, 8, 22, 8, 0), 2),
        (DateTime(2026, 8, 21, 8, 0), 1),
        (DateTime(2026, 8, 21, 9, 0), -1),
        (DateTime(2026, 8, 10, 8, 0), 99), // 窗口外
      ]);
      final counts = dailyCounts(entries, now, 3);
      expect(counts.length, 3);
      expect(counts[0].$1, startOfDay(DateTime(2026, 8, 20)));
      expect(counts[0].$2, 0);
      expect(counts[1].$2, 0);
      expect(counts[2].$2, 2);
    });
  });

  group('date utils', () {
    test('startOfWeek 以周一为界', () {
      // 2026-08-19 是周三
      expect(
        startOfWeek(DateTime(2026, 8, 19)),
        DateTime(2026, 8, 17),
      );
    });
    test('isSameDay 忽略时分秒', () {
      expect(isSameDay(DateTime(2026, 1, 1, 23, 59), DateTime(2026, 1, 1)), isTrue);
      expect(isSameDay(DateTime(2026, 1, 1), DateTime(2026, 1, 2)), isFalse);
    });
  });
}
