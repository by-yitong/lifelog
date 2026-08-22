import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_typography.dart';
import '../../app_state.dart';

/// 设置：主题、默认排序、数据导出、关于。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final settingsController = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          _SectionLabel('外观'),
          const SizedBox(height: Space.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settingsController.setThemeMode(s.first),
          ),

          const SizedBox(height: Space.xxl),
          _SectionLabel('首页排序'),
          const SizedBox(height: Space.sm),
          SegmentedButton<SortMode>(
            segments: [
              for (final m in SortMode.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {settings.sortMode},
            onSelectionChanged: (s) => settingsController.setSortMode(s.first),
          ),

          const SizedBox(height: Space.xxl),
          _SectionLabel('分类排序'),
          const SizedBox(height: Space.sm),
          const _TagOrderEditor(),

          const SizedBox(height: Space.xxl),
          _SectionLabel('趋势图样式'),
          const SizedBox(height: Space.sm),
          SegmentedButton<TrendChartStyle>(
            segments: [
              for (final s in TrendChartStyle.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {settings.trendChartStyle},
            onSelectionChanged: (s) =>
                settingsController.setTrendChartStyle(s.first),
          ),

          const SizedBox(height: Space.xxl),
          _SectionLabel('数据'),
          const SizedBox(height: Space.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(RadiusToken.field),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('导出 CSV'),
                  subtitle: Text('用表格软件打开', style: AppTypography.caption(color: colors.inkFaint)),
                  onTap: () => _export(context, ref, ExportFormat.csv),
                ),
                Divider(height: 1, color: colors.outline),
                ListTile(
                  leading: const Icon(Icons.data_object_outlined),
                  title: const Text('导出 JSON'),
                  subtitle: Text('完整备份，含全部记录', style: AppTypography.caption(color: colors.inkFaint)),
                  onTap: () => _export(context, ref, ExportFormat.json),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xxl),
          _SectionLabel('关于'),
          const SizedBox(height: Space.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(RadiusToken.field),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('数一数 v1.0.0',
                    style: AppTypography.title(color: colors.ink)),
                const SizedBox(height: Space.xs),
                Text('记录一件事情做了多少次。所有数据只保存在这台手机上。',
                    style: AppTypography.body(color: colors.inkSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, ExportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);
      final counters = await db.select(db.counters).get();
      final entries = await db.select(db.entries).get();
      final totals = <String, int>{};
      for (final e in entries) {
        totals[e.counterId] = (totals[e.counterId] ?? 0) + e.delta;
      }

      late String content;
      late String mime;
      switch (format) {
        case ExportFormat.csv:
          final buf = StringBuffer('计数器,单位,总数,时间,变化,操作后数值\n');
          final nameOf = {for (final c in counters) c.id: c};
          for (final e in entries) {
            final c = nameOf[e.counterId];
            buf.writeln(
                '${_csv(c?.name)},${_csv(c?.unit)},${totals[e.counterId] ?? 0},${e.occurredAt.toIso8601String()},${e.delta},${e.valueAfter}');
          }
          content = buf.toString();
          mime = 'text/csv';
        case ExportFormat.json:
          content = const JsonEncoder.withIndent('  ').convert({
            'app': '数一数',
            'exportedAt': DateTime.now().toIso8601String(),
            'counters': [
              for (final c in counters)
                {
                  'id': c.id,
                  'name': c.name,
                  'emoji': c.emoji,
                  'colorIndex': c.colorIndex,
                  'unit': c.unit,
                  'stepSize': c.stepSize,
                  'dailyTarget': c.dailyTarget,
                  'pinned': c.pinned,
                  'archived': c.archived,
                  'createdAt': c.createdAt.toIso8601String(),
                },
            ],
            'entries': [
              for (final e in entries)
                {
                  'id': e.id,
                  'counterId': e.counterId,
                  'delta': e.delta,
                  'valueAfter': e.valueAfter,
                  'occurredAt': e.occurredAt.toIso8601String(),
                },
            ],
          });
          mime = 'application/json';
      }

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file =
          File('${dir.path}/数一数-$stamp.${format == ExportFormat.csv ? 'csv' : 'json'}');
      await file.writeAsString(content);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: mime)], text: '数一数 数据导出'),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }
}

enum ExportFormat { csv, json }

String _csv(String? s) => '"${(s ?? '').replaceAll('"', '""')}"';

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.caption(color: context.appColors.inkSub));
  }
}

/// 底部 Tab（分类）顺序编辑：拖动调整，新分类默认排在最后。
class _TagOrderEditor extends ConsumerWidget {
  const _TagOrderEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tags = ref.watch(tagListProvider);
    final summaries =
        ref.watch(countersSummaryProvider).value ?? const <CounterSummary>[];
    final countOf = <String, int>{};
    for (final s in summaries) {
      final t = s.counter.tag;
      if (t.isNotEmpty) countOf[t] = (countOf[t] ?? 0) + 1;
    }

    if (tags.isEmpty) {
      return Text('还没有分类，新建计数器时填写分类后会出现在这里。',
          style: AppTypography.body(color: colors.inkFaint));
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RadiusToken.field),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: true,
            padding: EdgeInsets.zero,
            itemCount: tags.length,
            onReorderItem: (oldIndex, newIndex) {
              final next = [...tags];
              final tag = next.removeAt(oldIndex);
              next.insert(newIndex, tag);
              ref.read(tagOrderProvider.notifier).setOrder(next);
            },
            itemBuilder: (context, i) {
              final tag = tags[i];
              return ListTile(
                key: ValueKey(tag),
                leading: Icon(Icons.drag_indicator, color: colors.inkFaint),
                title: Text(tag),
                subtitle: Text(
                  '${countOf[tag] ?? 0} 个计数器',
                  style: AppTypography.caption(color: colors.inkFaint),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.md),
            child: Text(
              '按住拖动可调整底部 Tab 顺序，新建的分类会排在最后。',
              style: AppTypography.caption(color: colors.inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}
