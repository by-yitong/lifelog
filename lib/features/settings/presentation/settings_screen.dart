import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Constant, InsertMode, Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/update/app_updater.dart'
    show currentAppVersion, pickBackupFileText;
import '../../../core/update/update_flow.dart';
import '../../app_state.dart';

/// 设置：主题、排序、数据备份导入、检查更新、关于。
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
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('备份数据'),
                  subtitle: Text('导出 JSON 备份，含全部计数器与记录',
                      style: AppTypography.caption(color: colors.inkFaint)),
                  onTap: () => _export(context, ref, ExportFormat.json),
                ),
                Divider(height: 1, color: colors.outline),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('从备份导入'),
                  subtitle: Text('支持合并或覆盖现有数据（背景图片不含在内）',
                      style: AppTypography.caption(color: colors.inkFaint)),
                  onTap: () => _importBackup(context, ref),
                ),
                Divider(height: 1, color: colors.outline),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('导出 CSV'),
                  subtitle: Text('用表格软件打开', style: AppTypography.caption(color: colors.inkFaint)),
                  onTap: () => _export(context, ref, ExportFormat.csv),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xxl),
          _SectionLabel('通用'),
          const SizedBox(height: Space.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(RadiusToken.field),
            ),
            clipBehavior: Clip.antiAlias,
            child: const _UpdateCheckTile(),
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
                FutureBuilder<String>(
                  future: currentAppVersion(),
                  builder: (context, snap) => Text(
                    '数一数 v${snap.data ?? "…"}',
                    style: AppTypography.title(color: colors.ink),
                  ),
                ),
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
                  'tag': c.tag,
                  'bgImagePath': c.bgImagePath,
                  'lastTouchedAt': c.lastTouchedAt?.toIso8601String(),
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

/// ---------- 从备份导入 ----------

class _BackupData {
  final List<CountersCompanion> counters;
  final List<EntriesCompanion> entries;

  const _BackupData({required this.counters, required this.entries});
}

Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final text = await pickBackupFileText();
    if (text == null || !context.mounted) return; // 用户取消

    final raw = jsonDecode(text);
    if (raw is! Map<String, dynamic> ||
        raw['counters'] is! List ||
        raw['entries'] is! List) {
      messenger.showSnackBar(const SnackBar(content: Text('文件格式不对，不是「数一数」的备份文件')));
      return;
    }

    final data = _parseBackup(raw);

    if (!context.mounted) return;
    final mode = await _pickImportMode(context, data.counters.length,
        data.entries.length);
    if (mode == null || !context.mounted) return;

    final db = ref.read(databaseProvider);
    var nCounters = 0;
    var nEntries = 0;
    await db.transaction(() async {
      if (mode == 'replace') {
        // 覆盖：先清空（先删记录再删计数器，满足外键），再整批写入
        await db.batch((b) {
          b.deleteWhere(db.entries, (_) => const Constant(true));
          b.deleteWhere(db.counters, (_) => const Constant(true));
          b.insertAll(db.counters, data.counters);
          b.insertAll(db.entries, data.entries);
        });
        nCounters = data.counters.length;
        nEntries = data.entries.length;
      } else {
        // 合并：跳过已存在的 id；引用不存在计数器的记录丢弃
        final existingCounterIds = <String>{};
        for (final row in await db.select(db.counters).get()) {
          existingCounterIds.add(row.id);
        }
        final importedCounterIds =
            data.counters.map((c) => c.id.value).toSet();
        final existingEntryIds = <String>{
          for (final row in await db.select(db.entries).get()) row.id
        };
        final freshEntries = data.entries
            .where((e) => importedCounterIds.contains(e.counterId.value))
            .where((e) => !existingEntryIds.contains(e.id.value))
            .toList();
        final freshCounters = data.counters
            .where((c) => !existingCounterIds.contains(c.id.value))
            .toList();

        await db.batch((b) {
          b.insertAll(db.counters, freshCounters,
              mode: InsertMode.insertOrIgnore);
          b.insertAll(db.entries, freshEntries,
              mode: InsertMode.insertOrIgnore);
        });
        nCounters = freshCounters.length;
        nEntries = freshEntries.length;
      }
    });

    messenger.showSnackBar(SnackBar(
      content: Text(mode == 'replace'
          ? '已覆盖导入 ${data.counters.length} 个计数器、${data.entries.length} 条记录'
          : '合并完成：新增 $nCounters 个计数器、$nEntries 条记录'),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('导入失败：$e')));
  }
}

Future<String?> _pickImportMode(
  BuildContext context,
  int counterCount,
  int entryCount,
) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      return AlertDialog(
        title: const Text('导入这份备份？'),
        content: Text(
          '包含 $counterCount 个计数器、$entryCount 条记录。\n\n'
          '· 合并导入：保留现有数据，相同的编号自动跳过\n'
          '· 覆盖导入：清空现有全部数据后写入',
          style: AppTypography.body(color: colors.inkSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'merge'),
            child: const Text('合并导入'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () => Navigator.pop(dialogContext, 'replace'),
            child: const Text('覆盖导入'),
          ),
        ],
      );
    },
  );
}

_BackupData _parseBackup(Map<String, dynamic> raw) {
  final counters = <CountersCompanion>[];
  for (final item in raw['counters'] as List) {
    if (item is! Map<String, dynamic>) continue;
    final id = item['id'];
    if (id is! String || id.isEmpty) continue;
    counters.add(_counterFromJson(item));
  }
  final counterIds = counters.map((c) => c.id.value).toSet();
  final entries = <EntriesCompanion>[];
  for (final item in raw['entries'] as List) {
    if (item is! Map<String, dynamic>) continue;
    final id = item['id'];
    final counterId = item['counterId'];
    if (id is! String || id.isEmpty) continue;
    if (counterId is! String || !counterIds.contains(counterId)) continue;
    entries.add(_entryFromJson(item));
  }
  return _BackupData(counters: counters, entries: entries);
}

CountersCompanion _counterFromJson(Map<String, dynamic> j) {
  DateTime? parseDate(String key) =>
      DateTime.tryParse(j[key] as String? ?? '');
  return CountersCompanion.insert(
    id: j['id'] as String,
    name: ((j['name'] as String?) ?? '').trim().isEmpty
        ? '未命名'
        : j['name'] as String,
    emoji: Value((j['emoji'] as String?) ?? '✨'),
    colorIndex: Value((j['colorIndex'] as num?)?.toInt() ?? 0),
    bgImagePath: Value(j['bgImagePath'] as String?),
    unit: Value(((j['unit'] as String?) ?? '').isEmpty
        ? '次'
        : j['unit'] as String),
    tag: Value((j['tag'] as String?) ?? ''),
    stepSize: Value(((j['stepSize'] as num?)?.toInt() ?? 1) < 1
        ? 1
        : (j['stepSize'] as num).toInt()),
    dailyTarget: Value((j['dailyTarget'] as num?)?.toInt()),
    pinned: Value((j['pinned'] as bool?) ?? false),
    archived: Value((j['archived'] as bool?) ?? false),
    lastTouchedAt: Value(parseDate('lastTouchedAt')),
    createdAt: parseDate('createdAt') ?? DateTime.now(),
  );
}

EntriesCompanion _entryFromJson(Map<String, dynamic> j) {
  return EntriesCompanion.insert(
    id: j['id'] as String,
    counterId: j['counterId'] as String,
    delta: (j['delta'] as num?)?.toInt() ?? 0,
    valueAfter: (j['valueAfter'] as num?)?.toInt() ?? 0,
    occurredAt:
        DateTime.tryParse(j['occurredAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.caption(color: context.appColors.inkSub));
  }
}

/// 检查更新入口：显示当前版本，点击去 GitHub Releases 比对。
class _UpdateCheckTile extends ConsumerWidget {
  const _UpdateCheckTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return ListTile(
      leading: const Icon(Icons.cloud_download_outlined),
      title: const Text('检查更新'),
      subtitle: FutureBuilder<String>(
        future: currentAppVersion(),
        builder: (context, snap) => Text(
          '当前版本 v${snap.data ?? "…"} · 通过 GitHub 分发',
          style: AppTypography.caption(color: colors.inkFaint),
        ),
      ),
      onTap: () => checkForUpdate(context, ref, silent: false),
    );
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
