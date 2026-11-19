import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/stats.dart';
import '../../app_state.dart';
import '../../counter_detail/presentation/detail_screen.dart';

/// 全局统计：总览、月历、某天时间线、近半年热力图、计数器排行。
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  /// 月历当前展示的月份（1 号）。
  late DateTime _month = startOfMonth(DateTime.now());

  /// 时间线选中的日子，默认今天。
  DateTime? _selectedDay = startOfDay(DateTime.now());

  void _shiftMonth(int delta) {
    final target = DateTime(_month.year, _month.month + delta);
    setState(() {
      _month = target;
      // 选中的日子不在新月份里就取消选中
      final sel = _selectedDay;
      if (sel != null &&
          (sel.year != target.year || sel.month != target.month)) {
        _selectedDay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entriesAsync = ref.watch(allEntriesProvider);
    final summaries =
        ref.watch(countersSummaryProvider).value ?? const <CounterSummary>[];

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child:
              Text('出错了：$e', style: AppTypography.body(color: colors.danger)),
        ),
        data: (entries) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Space.xl, Space.md, Space.xl, Space.xxl),
            children: [
              _OverviewCards(entries: entries),
              const SizedBox(height: Space.lg),
              _MonthCalendar(
                month: _month,
                selectedDay: _selectedDay,
                entries: entries,
                onShift: _shiftMonth,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),
              const SizedBox(height: Space.lg),
              _DayTimeline(selectedDay: _selectedDay, entries: entries),
              const SizedBox(height: Space.lg),
              _HalfYearHeatmap(entries: entries),
              const SizedBox(height: Space.lg),
              _RankingSection(summaries: summaries),
            ],
          );
        },
      ),
    );
  }
}

/// ---------- 总览 ----------

class _OverviewCards extends StatelessWidget {
  final List<Entry> entries;

  const _OverviewCards({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final records = [for (final e in entries) (e.occurredAt, e.delta)];
    // 初始值记录计入累计，不计入今日/连续/活跃天数。
    final countable = [
      for (final e in entries)
        if (!e.isInitial) (e.occurredAt, e.delta),
    ];
    final total = sumDeltas(records);
    final today = countToday(countable, now);
    final streak = streakDays(countable, now);
    final activeDays = entries
        .where((e) => e.delta > 0 && !e.isInitial)
        .map((e) => startOfDay(e.occurredAt))
        .toSet()
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '$total', label: '累计记录', emphasize: true)),
            const SizedBox(width: Space.md),
            Expanded(child: _StatCard(value: '$today', label: '今日')),
          ],
        ),
        const SizedBox(width: Space.md, height: Space.md),
        Row(
          children: [
            Expanded(child: _StatCard(value: '$streak', label: '连续天数')),
            const SizedBox(width: Space.md),
            Expanded(child: _StatCard(value: '$activeDays', label: '活跃天数')),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool emphasize;

  const _StatCard({
    required this.value,
    required this.label,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: emphasize ? colors.accentSoft : colors.surface,
        borderRadius: BorderRadius.circular(RadiusToken.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.headline(
                  color: emphasize ? colors.accentDeep : colors.ink)),
          const SizedBox(height: Space.xs),
          Text(label, style: AppTypography.caption(color: colors.inkSub)),
        ],
      ),
    );
  }
}

/// ---------- 月历 + 某天时间线 ----------

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDay;
  final List<Entry> entries;
  final ValueChanged<int> onShift;
  final ValueChanged<DateTime> onSelect;

  const _MonthCalendar({
    required this.month,
    required this.selectedDay,
    required this.entries,
    required this.onShift,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final today = startOfDay(now);
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    // 当月每日计数（只算正向增量）
    final counts = <int, int>{};
    for (final e in entries) {
      if (e.delta <= 0) continue;
      final t = e.occurredAt;
      if (t.year == month.year && t.month == month.month) {
        final d = t.day;
        counts[d] = (counts[d] ?? 0) + e.delta;
      }
    }
    final maxCount =
        counts.values.fold<int>(0, (acc, v) => v > acc ? v : acc);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks =
        DateTime(month.year, month.month, 1).weekday - 1; // 周一=0 个空位

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onShift(-1),
                icon: Icon(Icons.chevron_left, color: colors.inkSub),
              ),
              Expanded(
                child: Text(
                  '${month.year}年${month.month}月',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(color: colors.ink),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: isCurrentMonth ? null : () => onShift(1),
                icon: Icon(Icons.chevron_right,
                    color:
                        isCurrentMonth ? colors.inkFaint : colors.inkSub),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              for (final w in const ['一', '二', '三', '四', '五', '六', '日'])
                Expanded(
                  child: Center(
                    child: Text(w,
                        style:
                            AppTypography.caption(color: colors.inkFaint)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          _buildGrid(colors, daysInMonth, leadingBlanks, counts, maxCount,
              today),
        ],
      ),
    );
  }

  Widget _buildGrid(AppColors colors, int daysInMonth, int leadingBlanks,
      Map<int, int> counts, int maxCount, DateTime today) {
    final rows = <Widget>[];
    var week = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      week.add(const Expanded(child: SizedBox.shrink()));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      week.add(Expanded(
        child: _DayCell(
          date: DateTime(month.year, month.month, day),
          count: counts[day] ?? 0,
          maxCount: maxCount,
          isToday: isSameDay(DateTime(month.year, month.month, day), today),
          isSelected: selectedDay != null &&
              isSameDay(DateTime(month.year, month.month, day), selectedDay!),
          onTap: () => onSelect(DateTime(month.year, month.month, day)),
        ),
      ));
      if ((leadingBlanks + day) % 7 == 0 || day == daysInMonth) {
        rows.add(Row(children: week));
        week = <Widget>[];
        if (day != daysInMonth) {
          rows.add(const SizedBox(height: Space.xs));
        }
      }
    }

    return Column(children: rows);
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final int count;
  final int maxCount;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.count,
    required this.maxCount,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  Color _fill(AppColors colors) {
    if (isSelected) return colors.accent;
    if (count <= 0 || maxCount <= 0) return Colors.transparent;
    final t = (count / maxCount).clamp(0.0, 1.0);
    return colors.accent.withValues(alpha: .14 + .58 * t);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filled = isSelected || (count > 0 && maxCount > 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 44,
        decoration: BoxDecoration(
          color: _fill(colors),
          borderRadius: BorderRadius.circular(RadiusToken.chip),
          border: isToday && !isSelected
              ? Border.all(color: colors.accent, width: 1.4)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTypography.body(
                color: isSelected
                    ? colors.onAccent
                    : isToday
                        ? colors.accentDeep
                        : colors.inkSub,
              ),
            ),
            const SizedBox(height: 2),
            if (filled)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.onAccent : colors.accentDeep,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _DayTimeline extends ConsumerWidget {
  final DateTime? selectedDay;
  final List<Entry> entries; // 已按时间倒序

  const _DayTimeline({required this.selectedDay, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sel = selectedDay;

    final header = Text('当天时间线',
        style: AppTypography.caption(color: colors.inkSub));

    if (sel == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: Space.sm),
            Text('在上方日历里点选日期，查看那一天的记录。',
                style: AppTypography.body(color: colors.inkFaint)),
          ],
        ),
      );
    }

    final dayEntries =
        entries.where((e) => isSameDay(e.occurredAt, sel)).toList();
    final counters = ref.watch(countersSummaryProvider).value ??
        const <CounterSummary>[];
    Counter? counterOf(String id) {
      for (final s in counters) {
        if (s.counter.id == id) return s.counter;
      }
      return null;
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat('M月d日 EEEE', 'zh_CN').format(sel)} · 共 ${dayEntries.length} 笔',
                  style: AppTypography.title(color: colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          if (dayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text('这一天还没有记录。',
                  style: AppTypography.body(color: colors.inkFaint)),
            )
          else
            ...[
              for (var i = 0; i < dayEntries.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.outline),
                _TimelineTile(entry: dayEntries[i], counter: counterOf(dayEntries[i].counterId)),
              ],
            ],
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final Entry entry;
  final Counter? counter;

  const _TimelineTile({required this.entry, required this.counter});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = counter?.name ?? '已删除的计数器';
    final emoji = counter?.emoji ?? '📦';

    return InkWell(
      onTap: counter == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailScreen(counterId: counter!.id),
                ),
              ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                DateFormat('HH:mm').format(entry.occurredAt),
                style: AppTypography.caption(color: colors.inkFaint),
              ),
            ),
            const SizedBox(width: Space.sm),
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(color: colors.ink)),
            ),
            const SizedBox(width: Space.sm),
            Text(
              entry.delta > 0
                  ? '+${entry.delta}'
                  : '${entry.delta}',
              style: AppTypography.title(
                  color: entry.delta > 0 ? colors.success : colors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- 近半年热力图 ----------

class _HalfYearHeatmap extends StatelessWidget {
  final List<Entry> entries;

  const _HalfYearHeatmap({required this.entries});

  static const _heatmapWeeks = 26;

  static const double _cell = 13;
  static const double _gap = 3;

  Color _cellColor(AppColors colors, int count, int maxCount) {
    if (count <= 0 || maxCount <= 0) return colors.surfaceAlt;
    final t = (count / maxCount).clamp(0.0, 1.0);
    return colors.accent.withValues(alpha: .15 + .75 * t);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // 每日计数（只算正向增量）
    final byDay = <DateTime, int>{};
    var maxCount = 0;
    for (final e in entries) {
      if (e.delta <= 0) continue;
      final d = startOfDay(e.occurredAt);
      final v = (byDay[d] ?? 0) + e.delta;
      byDay[d] = v;
      if (v > maxCount) maxCount = v;
    }

    final today = startOfDay(DateTime.now());
    final endWeek = startOfWeek(today); // 本周一
    final start = addDays(endWeek, -(_heatmapWeeks - 1) * 7);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('近半年热力图',
              style: AppTypography.title(color: colors.ink)),
          const SizedBox(height: Space.xs),
          Text('颜色越深，这一天记的次数越多。长按格子看具体数字。',
              style: AppTypography.caption(color: colors.inkFaint)),
          const SizedBox(height: Space.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // 默认停在最近几周
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var w = 0; w < _heatmapWeeks; w++)
                  Column(
                    children: [
                      for (var dow = 0; dow < 7; dow++)
                        _heatCell(colors,
                            addDays(addDays(start, w * 7), dow), byDay,
                            maxCount),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('少', style: AppTypography.caption(color: colors.inkFaint)),
              const SizedBox(width: Space.xs),
              for (final c in const [0, 1, 2, 3]) ...[
                const SizedBox(width: 3),
                Container(
                  width: _cell,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c == 0
                        ? colors.surfaceAlt
                        : colors.accent.withValues(alpha: .25 + .25 * c),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
              const SizedBox(width: Space.xs),
              Text('多', style: AppTypography.caption(color: colors.inkFaint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heatCell(AppColors colors, DateTime day, Map<DateTime, int> byDay,
      int maxCount) {
    final future = day.isAfter(startOfDay(DateTime.now()));
    final count = byDay[day] ?? 0;

    Widget cell = Container(
      width: _cell,
      height: _cell,
      margin: const EdgeInsets.all(_gap / 2),
      decoration: BoxDecoration(
        color: future ? Colors.transparent : _cellColor(colors, count, maxCount),
        borderRadius: BorderRadius.circular(3),
      ),
    );

    if (!future) {
      cell = Tooltip(
        triggerMode: TooltipTriggerMode.longPress,
        message: '${day.month}月${day.day}日 · $count 次',
        child: cell,
      );
    } else {
      cell = Opacity(opacity: 0, child: cell);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _gap / 2),
      child: cell,
    );
  }
}

/// ---------- 计数器排行 ----------

class _RankingSection extends StatelessWidget {
  final List<CounterSummary> summaries;

  const _RankingSection({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ranked = [...summaries]
      ..sort((a, b) => b.total.compareTo(a.total));
    final withData = ranked.where((s) => s.total > 0).toList();
    final maxTotal =
        withData.isEmpty ? 1 : withData.first.total.clamp(1, 1 << 30);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('计数器排行', style: AppTypography.title(color: colors.ink)),
          const SizedBox(height: Space.sm),
          if (withData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text('还没有任何记录。',
                  style: AppTypography.body(color: colors.inkFaint)),
            )
          else
            for (var i = 0; i < withData.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.outline),
              _RankTile(
                rank: i + 1,
                summary: withData[i],
                fraction: withData[i].total / maxTotal,
              ),
            ],
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final CounterSummary summary;
  final double fraction;

  const _RankTile({
    required this.rank,
    required this.summary,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = summary.counter;
    final podium = rank <= 3;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(counterId: c.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: AppTypography.title(
                    color: podium ? colors.accent : colors.inkFaint),
              ),
            ),
            const SizedBox(width: Space.sm),
            Text(c.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(color: colors.ink)),
                  const SizedBox(height: Space.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: fraction.clamp(0.02, 1.0),
                      minHeight: 5,
                      backgroundColor: colors.surfaceAlt,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            Text('${summary.total} ${c.unit}',
                style: AppTypography.title(color: colors.inkSub)),
          ],
        ),
      ),
    );
  }
}

/// ---------- 通用卡片 ----------

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RadiusToken.card),
      ),
      child: child,
    );
  }
}
