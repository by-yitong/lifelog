import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/stats.dart';
import '../../../shared/widgets/motion.dart';
import '../../app_state.dart';
import '../../counter_edit/presentation/edit_sheet.dart';

/// 计数器详情：大数字 + 步进、统计、趋势图、历史记录。
class DetailScreen extends ConsumerWidget {
  final String counterId;

  const DetailScreen({super.key, required this.counterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        ref.watch(countersSummaryProvider).value ?? const <CounterSummary>[];
    CounterSummary? summary;
    for (final s in summaries) {
      if (s.counter.id == counterId) summary = s;
    }

    if (summary == null) {
      // 已被删除/归档：返回上一页。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final counter = summary.counter;
    return Scaffold(
      appBar: AppBar(
        title: Text('${counter.emoji} ${counter.name}'),
        actions: [
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showEditSheet(context, existing: counter),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, ref, v, summary!),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'archive', child: Text('归档')),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(Space.xl, Space.xs, Space.xl, Space.xxxl),
          children: [
            _Header(summary: summary),
            const SizedBox(height: Space.xxl),
            _StatsStrip(summary: summary),
            const SizedBox(height: Space.xxl),
            const Divider(),
            const SizedBox(height: Space.lg),
            _TrendSection(counterId: counterId),
            const SizedBox(height: Space.xl),
            const Divider(),
            const SizedBox(height: Space.lg),
            _HeatmapSection(counterId: counterId, unit: counter.unit),
            const SizedBox(height: Space.xl),
            const Divider(),
            const SizedBox(height: Space.lg),
            _HistorySection(counterId: counterId),
          ],
        ),
      ),
    );
  }

  void _onMenu(BuildContext context, WidgetRef ref, String action,
      CounterSummary summary) {
    final repo = ref.read(counterRepositoryProvider);
    switch (action) {
      case 'archive':
        repo.setArchived(summary.counter.id, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已归档「${summary.counter.name}」'),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () => repo.setArchived(summary.counter.id, false),
            ),
          ),
        );
        Navigator.of(context).pop();
      case 'delete':
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('删除计数器？'),
            content: Text('「${summary.counter.name}」及其全部记录将被删除，无法恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: context.appColors.danger),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  repo.deleteCounter(summary.counter.id);
                  Navigator.of(context).pop();
                },
                child: const Text('删除'),
              ),
            ],
          ),
        );
    }
  }
}

/// 顶部：emoji + 大数字 + 步进操作。
/// 设置了背景图时，整块压在圆角图片横幅上。
class _Header extends ConsumerWidget {
  final CounterSummary summary;

  const _Header({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final counter = summary.counter;
    final bgPath = counter.bgImagePath;
    final hasBg = bgPath != null && bgPath.isNotEmpty;

    final inkStrong = hasBg ? Colors.white : colors.ink;
    final inkSoft = hasBg ? Colors.white.withValues(alpha: .82) : colors.inkSub;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(counter.emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: Space.md),
        BumpOnChange(
          trigger: summary.total,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${summary.total}',
                  style: AppTypography.numDisplay(size: 64, color: inkStrong)),
              const SizedBox(width: Space.sm),
              Text(counter.unit,
                  style: AppTypography.title(color: inkSoft)),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Row(
          children: [
            _BigPlusButton(
              step: counter.stepSize,
              onTap: () async {
                HapticFeedback.lightImpact();
                final repo = ref.read(counterRepositoryProvider);
                final entry = await repo.addEntry(
                  counterId: counter.id,
                  delta: counter.stepSize,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(
                        '已记一笔 ${counter.name} +${entry.delta}${counter.unit}'),
                    action: SnackBarAction(
                      label: '撤销',
                      onPressed: () => repo.deleteEntry(entry),
                    ),
                  ));
              },
            ),
            const SizedBox(width: Space.md),
            OutlinedButton(
              onPressed: () {
                if (summary.total <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已经是 0 了')),
                  );
                  return;
                }
                ref
                    .read(counterRepositoryProvider)
                    .addEntry(counterId: counter.id, delta: -1);
              },
              style: hasBg
                  ? OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: .6)),
                    )
                  : null,
              child: const Text('-1'),
            ),
            const SizedBox(width: Space.sm),
            TextButton(
              onPressed: () => _showAdjustDialog(context, ref),
              style: hasBg
                  ? TextButton.styleFrom(foregroundColor: Colors.white)
                  : null,
              child: const Text('手动调整'),
            ),
          ],
        ),
      ],
    );

    if (!hasBg) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusToken.card),
      child: Stack(
        children: [
          // 图片与渐变铺满内容实际撑开的大小
          Positioned.fill(
            child: Image.file(
              File(bgPath),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => ColoredBox(color: colors.surfaceAlt),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.4, 1],
                  colors: [
                    Colors.black.withValues(alpha: .2),
                    Colors.black.withValues(alpha: .12),
                    Colors.black.withValues(alpha: .55),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: content,
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: '${summary.total}');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('调整为指定数值'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '输入当前总数'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value == null || value < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入不小于 0 的数字')),
                );
                return;
              }
              final delta = value - summary.total;
              Navigator.pop(dialogContext);
              if (delta != 0) {
                ref.read(counterRepositoryProvider).addEntry(
                      counterId: summary.counter.id,
                      delta: delta,
                    );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _BigPlusButton extends StatefulWidget {
  final int step;
  final VoidCallback onTap;

  const _BigPlusButton({required this.step, required this.onTap});

  @override
  State<_BigPlusButton> createState() => _BigPlusButtonState();
}

class _BigPlusButtonState extends State<_BigPlusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: Motion.fast,
        curve: Motion.easeOut,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            '+${widget.step}',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 22,
              color: colors.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// 统计条：今日 / 本周 / 本月 / 累计 / 连续。
class _StatsStrip extends StatelessWidget {
  final CounterSummary summary;

  const _StatsStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final unit = summary.counter.unit;
    final items = [
      ('今日', '${summary.today}'),
      ('本周', '${summary.week}'),
      ('本月', '${summary.month}'),
      ('累计', '${summary.total}'),
      ('连续', '${summary.streak}'),
    ];
    final units = [unit, unit, unit, unit, '天'];
    return Row(
      children: [
        for (final (i, (label, value)) in items.indexed)
          Expanded(
            child: Container(
              margin:
                  EdgeInsets.only(right: i == items.length - 1 ? 0 : Space.sm),
              padding: const EdgeInsets.symmetric(
                  vertical: Space.md, horizontal: Space.xs),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(RadiusToken.field),
              ),
              child: Column(
                children: [
                  Text(label,
                      style: AppTypography.caption(color: colors.inkFaint)),
                  const SizedBox(height: Space.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontVariations: const [FontVariation('wght', 800)],
                          fontSize: 17,
                          color: colors.ink,
                        ),
                      ),
                      Text(' ${units[i]}',
                          style: AppTypography.caption(color: colors.inkFaint)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 趋势图区段：7/30/90 天切换。
enum _Range { d7, d30, d90 }

extension _RangeX on _Range {
  int get days => switch (this) {
        _Range.d7 => 7,
        _Range.d30 => 30,
        _Range.d90 => 90,
      };
  String get label => switch (this) {
        _Range.d7 => '近 7 天',
        _Range.d30 => '近 30 天',
        _Range.d90 => '近 90 天',
      };
}

class _TrendSection extends ConsumerStatefulWidget {
  final String counterId;

  const _TrendSection({required this.counterId});

  @override
  ConsumerState<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends ConsumerState<_TrendSection> {
  _Range _range = _Range.d7;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entries =
        ref.watch(counterEntriesProvider(widget.counterId)).value ?? const [];
    final chartStyle = ref.watch(
      settingsProvider.select((s) => s.trendChartStyle),
    );
    final data = dailyCounts(
      entries.map((e) => (e.occurredAt, e.delta)).toList(),
      DateTime.now(),
      _range.days,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('趋势',
                  style: AppTypography.headline(color: colors.ink)
                      .copyWith(fontSize: 18)),
            ),
            SegmentedButton<_Range>(
              segments: [
                for (final r in _Range.values)
                  ButtonSegment(value: r, label: Text(r.label)),
              ],
              selected: {_range},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _range = s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        SizedBox(
          height: 160,
          child: chartStyle == TrendChartStyle.line
              ? _LineChart(data: data, colors: colors)
              : _TrendChart(data: data, colors: colors),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<(DateTime, int)> data;
  final AppColors colors;

  const _TrendChart({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<int>(0, (m, d) => d.$2 > m ? d.$2 : m);
    final maxY = (maxVal < 4 ? 4 : maxVal) * 1.15;
    final labelEvery = (data.length / 6).ceil();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${DateFormat('M月d日').format(data[group.x].$1)}\n${rod.toY.round()} 次',
              AppTypography.caption(color: colors.paper),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                if (i != data.length - 1 && i % labelEvery != 0) {
                  return const SizedBox.shrink();
                }
                final d = data[i].$1;
                return Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(
                    i == data.length - 1
                        ? '今天'
                        : DateFormat('M/d').format(d),
                    style: AppTypography.caption(color: colors.inkFaint)
                        .copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: colors.outline.withValues(alpha: .5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (final (i, (_, count)) in data.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  width: _barWidth,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3)),
                  color: count <= 0
                      ? colors.accent.withValues(alpha: .18)
                      : i == data.length - 1
                          ? colors.accent
                          : colors.accent.withValues(alpha: .45),
                ),
              ],
            ),
        ],
      ),
    );
  }

  double get _barWidth => switch (data.length) {
        <= 7 => 22,
        <= 30 => 8,
        _ => 4,
      };
}

/// 折线趋势图（设置里可切换）。
class _LineChart extends StatelessWidget {
  final List<(DateTime, int)> data;
  final AppColors colors;

  const _LineChart({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<int>(0, (m, d) => d.$2 > m ? d.$2 : m);
    final maxY = (maxVal < 4 ? 4 : maxVal) * 1.15;
    final labelEvery = (data.length / 6).ceil();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                if (s.x >= 0 && s.x < data.length)
                  LineTooltipItem(
                    '${DateFormat('M月d日').format(data[s.x.toInt()].$1)}\n${s.y.round()} 次',
                    AppTypography.caption(color: colors.paper),
                  ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                if (i != data.length - 1 && i % labelEvery != 0) {
                  return const SizedBox.shrink();
                }
                final d = data[i].$1;
                return Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(
                    i == data.length - 1
                        ? '今天'
                        : DateFormat('M/d').format(d),
                    style: AppTypography.caption(color: colors.inkFaint)
                        .copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: colors.outline.withValues(alpha: .5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final (i, (_, count)) in data.indexed)
                FlSpot(i.toDouble(), count.toDouble()),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 3,
            color: colors.accent,
            dotData: FlDotData(
              show: data.length <= 31,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: spot.x == data.length - 1 ? 4 : 2.5,
                color: spot.x == data.length - 1
                    ? colors.accent
                    : colors.accent.withValues(alpha: .45),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.accent.withValues(alpha: .22),
                  colors.accent.withValues(alpha: .02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 本月热力图：每天一格，颜色越深计数越多。
class _HeatmapSection extends ConsumerWidget {
  final String counterId;
  final String unit;

  const _HeatmapSection({required this.counterId, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final entries =
        ref.watch(counterEntriesProvider(counterId)).value ?? const [];

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // 按天聚合（只统计本月、正增量）
    final counts = List<int>.filled(daysInMonth, 0);
    for (final e in entries) {
      if (e.delta <= 0) continue;
      final d = e.occurredAt;
      if (d.year == now.year && d.month == now.month) {
        counts[d.day - 1] += e.delta;
      }
    }
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);

    // 周一起始的空位偏移
    final leading = (firstDay.weekday + 6) % 7;
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    final screenPadding = Space.xl * 2;
    const gap = 4.0;
    final cell = (MediaQuery.sizeOf(context).width - screenPadding - gap * 6) / 7;

    Widget dayCell(int day) {
      // 网格按整周补齐：负数是月初空位，超出是月末补位
      if (day < 0 || day >= daysInMonth) {
        return Expanded(child: SizedBox(height: cell));
      }
      final count = counts[day];
      final t = maxCount == 0 ? 0.0 : count / maxCount;
      final date = DateTime(now.year, now.month, day + 1);
      final isToday = date.day == now.day;
      return Expanded(
        child: Tooltip(
          triggerMode: TooltipTriggerMode.longPress,
          message: '${date.month}月${date.day}日 · $count $unit',
          child: Container(
            height: cell,
            margin: const EdgeInsets.all(gap / 2),
            decoration: BoxDecoration(
              color: count == 0
                  ? colors.surfaceAlt
                  : colors.accent.withValues(alpha: .25 + .65 * t),
              borderRadius: BorderRadius.circular(cell * 0.28),
              border: isToday
                  ? Border.all(color: colors.accent, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day + 1}',
              style: AppTypography.caption(
                color: count == 0
                    ? colors.inkFaint
                    : (t > .55 ? Colors.white : colors.accentDeep),
              ).copyWith(fontSize: cell > 40 ? 11 : 9),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本月热力',
            style:
                AppTypography.headline(color: colors.ink).copyWith(fontSize: 18)),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(w,
                      style: AppTypography.caption(color: colors.inkFaint)
                          .copyWith(fontSize: 10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        for (var row = 0; row < (leading + daysInMonth + 6) ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                dayCell(row * 7 + col - leading),
            ],
          ),
        const SizedBox(height: Space.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('少',
                style:
                    AppTypography.caption(color: colors.inkFaint).copyWith(fontSize: 10)),
            const SizedBox(width: Space.xs),
            for (final a in [.15, .35, .55, .75, .95])
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: a),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: Space.xs),
            Text('多',
                style:
                    AppTypography.caption(color: colors.inkFaint).copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

/// 历史列表：按日分组，滑动删除 + Undo。
class _HistorySection extends ConsumerWidget {
  final String counterId;

  const _HistorySection({required this.counterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final entriesAsync = ref.watch(counterEntriesProvider(counterId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('历史',
            style:
                AppTypography.headline(color: colors.ink).copyWith(fontSize: 18)),
        const SizedBox(height: Space.md),
        entriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Space.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('加载失败：$e',
              style: AppTypography.body(color: colors.danger)),
          data: (entries) {
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xxl),
                child: Center(
                  child: Text('还没有记录，点上面 + 开始',
                      style: AppTypography.body(color: colors.inkFaint)),
                ),
              );
            }
            final now = DateTime.now();
            final today = startOfDay(now);
            final yesterday = addDays(today, -1);

            return Column(
              children: [
                for (final (i, entry) in entries.indexed) ...[
                  if (i == 0 ||
                      !isSameDay(entries[i - 1].occurredAt, entry.occurredAt))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: i == 0 ? 0 : Space.lg, bottom: Space.xs),
                        child: Text(
                          _dayLabel(entry.occurredAt, today, yesterday),
                          style:
                              AppTypography.caption(color: colors.inkFaint),
                        ),
                      ),
                    ),
                  _EntryTile(entry: entry),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _dayLabel(DateTime d, DateTime today, DateTime yesterday) {
    if (isSameDay(d, today)) return '今天';
    if (isSameDay(d, yesterday)) return '昨天';
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${DateFormat('M月d日').format(d)} 周${weekdays[d.weekday - 1]}';
  }
}

class _EntryTile extends ConsumerWidget {
  final Entry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final positive = entry.delta > 0;
    final deltaText = positive ? '+${entry.delta}' : '${entry.delta}';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.xl),
        decoration: BoxDecoration(
          color: colors.danger.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(RadiusToken.field),
        ),
        child: Icon(Icons.delete_outline, color: colors.danger),
      ),
      onDismissed: (_) {
        ref.read(counterRepositoryProvider).deleteEntry(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除一条记录（$deltaText）'),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () =>
                  ref.read(counterRepositoryProvider).restoreEntry(entry),
            ),
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // 长按弹出操作菜单：编辑 / 删除
        onLongPress: () => _showEntryActions(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(RadiusToken.field),
                ),
                alignment: Alignment.center,
                child: Text(
                  DateFormat('HH:mm').format(entry.occurredAt),
                  style: AppTypography.caption(color: colors.inkSub)
                      .copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  '$deltaText  ·  记到 ${entry.valueAfter}',
                  style: AppTypography.body(color: colors.ink),
                ),
              ),
              Text(
                deltaText,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontVariations: const [FontVariation('wght', 800)],
                  fontSize: 15,
                  color: positive ? colors.success : colors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 长按菜单：编辑 / 删除。
  void _showEntryActions(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final deltaText = entry.delta > 0 ? '+${entry.delta}' : '${entry.delta}';
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('编辑记录',
                  style: AppTypography.body(color: colors.ink)),
              subtitle: Text('$deltaText · ${DateFormat('M月d日 HH:mm').format(entry.occurredAt)}',
                  style: AppTypography.caption(color: colors.inkFaint)),
              onTap: () {
                Navigator.pop(sheetContext);
                _editEntry(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text('删除', style: TextStyle(color: colors.danger)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    );
  }

  /// 编辑记录：可修改数量与发生时间。
  Future<void> _editEntry(BuildContext context, WidgetRef ref) async {
    final colors = context.appColors;
    final deltaText = entry.delta > 0 ? '+${entry.delta}' : '${entry.delta}';
    final controller = TextEditingController(text: '${entry.delta}');
    var at = entry.occurredAt;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('编辑记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  labelText: '变化量（正负均可）',
                  helperText: '当前 $deltaText，总数 = 全部记录之和',
                ),
              ),
              const SizedBox(height: Space.lg),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: at,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !dialogContext.mounted) return;
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay.fromDateTime(at),
                  );
                  if (time == null) return;
                  setDialogState(() {
                    at = DateTime(
                        date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
                icon: const Icon(Icons.schedule_outlined, size: 18),
                label: Text(DateFormat('M月d日 HH:mm').format(at)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style:
                  FilledButton.styleFrom(backgroundColor: colors.accent),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;

    final newDelta = int.tryParse(controller.text.trim());
    if (newDelta == null || newDelta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('变化量要是非 0 的整数')),
      );
      return;
    }
    final changedDelta = newDelta != entry.delta;
    final changedAt = !at.isAtSameMomentAs(entry.occurredAt);
    if (!changedDelta && !changedAt) return;

    await ref.read(counterRepositoryProvider).updateEntry(
          entry,
          delta: changedDelta ? newDelta : null,
          occurredAt: changedAt ? at : null,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已更新为 '
            '${newDelta > 0 ? '+' : ''}$newDelta · ${DateFormat('M月d日 HH:mm').format(at)}'),
      ),
    );
  }

  /// 删除：先弹确认框，确认后才真正删除（带撤销）。
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final colors = context.appColors;
    final deltaText = entry.delta > 0 ? '+${entry.delta}' : '${entry.delta}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: Text('$deltaText · 记到 ${entry.valueAfter}，删除后计数回退。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(counterRepositoryProvider).deleteEntry(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除一条记录（$deltaText）'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () =>
              ref.read(counterRepositoryProvider).restoreEntry(entry),
        ),
      ),
    );
  }
}
