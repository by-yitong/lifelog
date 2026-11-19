import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/database.dart';
import '../../core/utils/stats.dart';
import '../../core/utils/stream_utils.dart';
import 'counters/data/counter_repository.dart';

/// ---------- 基础设施 ----------

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('在 main() 中 override'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final counterRepositoryProvider = Provider<CounterRepository>(
  (ref) => CounterRepository(ref.watch(databaseProvider)),
);

/// ---------- 设置（主题 / 排序 / 图表，本地持久化）----------

enum SortMode { recent, name, created }

extension SortModeLabel on SortMode {
  String get label => switch (this) {
        SortMode.recent => '最近',
        SortMode.name => '名称',
        SortMode.created => '创建',
      };
}

/// 详情页趋势图的样式。
enum TrendChartStyle { bar, line }

extension TrendChartStyleX on TrendChartStyle {
  String get label => switch (this) {
        TrendChartStyle.bar => '柱状图',
        TrendChartStyle.line => '折线图',
      };
}

class SettingsState {
  final ThemeMode themeMode;
  final SortMode sortMode;
  final TrendChartStyle trendChartStyle;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.sortMode = SortMode.recent,
    this.trendChartStyle = TrendChartStyle.bar,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    SortMode? sortMode,
    TrendChartStyle? trendChartStyle,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        sortMode: sortMode ?? this.sortMode,
        trendChartStyle: trendChartStyle ?? this.trendChartStyle,
      );
}

class SettingsController extends Notifier<SettingsState> {
  static const _kThemeMode = 'theme_mode';
  static const _kSortMode = 'sort_mode';
  static const _kTrendChartStyle = 'trend_chart_style';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final prefs = _prefs;
    return SettingsState(
      themeMode:
          ThemeMode.values[prefs.getInt(_kThemeMode) ?? ThemeMode.system.index],
      sortMode:
          SortMode.values[prefs.getInt(_kSortMode) ?? SortMode.recent.index],
      trendChartStyle: TrendChartStyle
          .values[prefs.getInt(_kTrendChartStyle) ?? TrendChartStyle.bar.index],
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setInt(_kThemeMode, mode.index);
  }

  void setSortMode(SortMode mode) {
    state = state.copyWith(sortMode: mode);
    _prefs.setInt(_kSortMode, mode.index);
  }

  void setTrendChartStyle(TrendChartStyle style) {
    state = state.copyWith(trendChartStyle: style);
    _prefs.setInt(_kTrendChartStyle, style.index);
  }
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

/// ---------- 计数器汇总 ----------

/// 一个计数器行 + 它的统计快照。
class CounterSummary {
  final Counter counter;
  final int total;
  final int today;
  final int week;
  final int month;
  final int streak;

  const CounterSummary({
    required this.counter,
    required this.total,
    required this.today,
    required this.week,
    required this.month,
    required this.streak,
  });
}

// 「最近使用」排序的顺序快照：+1 只更新 lastTouchedAt，计数器集合没变，
// 若每次都重排，卡片会在点击瞬间跳到最前面，体验很差。
// 这里按"集合签名"（id + 置顶状态）缓存显示顺序，
// 只有增删/归档/置顶/切换排序方式时才重新排序。
String? _recentOrderSig;
List<String>? _recentOrderIds;

final countersSummaryProvider = StreamProvider<List<CounterSummary>>((ref) {
  final repo = ref.watch(counterRepositoryProvider);
  final sortMode = ref.watch(
    settingsProvider.select((s) => s.sortMode),
  );

  return combineLatest2(
    repo.watchCounters(),
    repo.watchAllEntries(),
    (List<Counter> counters, List<Entry> entries) {
      // 初始值记录计入总数，但不计入每日/每周/每月/连续统计。
      final byCounter = <String, List<(DateTime, int)>>{};
      final countableBy = <String, List<(DateTime, int)>>{};
      for (final e in entries) {
        (byCounter[e.counterId] ??= []).add((e.occurredAt, e.delta));
        if (!e.isInitial) {
          (countableBy[e.counterId] ??= []).add((e.occurredAt, e.delta));
        }
      }

      final now = DateTime.now();
      final summaries = counters.map((c) {
        final list = byCounter[c.id] ?? const <(DateTime, int)>[];
        final countable = countableBy[c.id] ?? const <(DateTime, int)>[];
        return CounterSummary(
          counter: c,
          total: sumDeltas(list),
          today: countToday(countable, now),
          week: countThisWeek(countable, now),
          month: countThisMonth(countable, now),
          streak: streakDays(countable, now),
        );
      }).toList();

      int compare(CounterSummary a, CounterSummary b) {
        if (a.counter.pinned != b.counter.pinned) {
          return b.counter.pinned ? 1 : -1;
        }
        return switch (sortMode) {
          SortMode.recent => (b.counter.lastTouchedAt ?? b.counter.createdAt)
              .compareTo(a.counter.lastTouchedAt ?? a.counter.createdAt),
          SortMode.name => a.counter.name.compareTo(b.counter.name),
          SortMode.created =>
            b.counter.createdAt.compareTo(a.counter.createdAt),
        };
      }

      // 集合没变且仍是"最近使用"排序 → 沿用上一次的顺序
      final sig =
          '${sortMode.name}|${summaries.map((s) => '${s.counter.id}:${s.counter.pinned ? 1 : 0}').join(',')}';
      if (sortMode == SortMode.recent &&
          sig == _recentOrderSig &&
          _recentOrderIds != null) {
        final pos = {
          for (final (i, id) in _recentOrderIds!.indexed) id: i,
        };
        summaries.sort((a, b) =>
            (pos[a.counter.id] ?? 1 << 30) - (pos[b.counter.id] ?? 1 << 30));
        return summaries;
      }

      summaries.sort(compare);
      _recentOrderSig = sig;
      _recentOrderIds = [for (final s in summaries) s.counter.id];
      return summaries;
    },
  );
});

/// ---------- 分类（底部 Tab）顺序 ----------
///
/// Tab 采用固定顺序：按这里存的顺序显示，新建分类自动追加到最后。
/// 用户可在「设置 → 分类排序」里拖动调整。

class TagOrderController extends Notifier<List<String>> {
  static const _kTagOrder = 'tag_order';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<String> build() => _prefs.getStringList(_kTagOrder) ?? const <String>[];

  void _save(List<String> order) {
    state = List.unmodifiable(order);
    _prefs.setStringList(_kTagOrder, order);
  }

  /// 整体重设（设置页拖动排序后调用）。
  void setOrder(List<String> order) => _save(order);

  /// 新出现的分类追加到末尾（首页构建时调用，保证"新建的排最后"）。
  void ensureContains(Iterable<String> tags) {
    final known = state.toSet();
    final missing = tags.where((t) => t.isNotEmpty && !known.contains(t));
    if (missing.isEmpty) return;
    _save([...state, ...missing]);
  }
}

final tagOrderProvider =
    NotifierProvider<TagOrderController, List<String>>(TagOrderController.new);

/// 某计数器的全部记录（新→旧）。
final counterEntriesProvider =
    StreamProvider.autoDispose.family<List<Entry>, String>((ref, counterId) {
  return ref.watch(counterRepositoryProvider).watchEntriesOf(counterId);
});

/// 全部记录（新→旧），供全局统计页使用。
final allEntriesProvider = StreamProvider<List<Entry>>((ref) async* {
  await for (final entries
      in ref.watch(counterRepositoryProvider).watchAllEntries()) {
    final sorted = [...entries]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    yield sorted;
  }
});

/// 全部标签（底部 Tab 顺序）：已定序的按用户顺序，新分类追加在最后。
final tagListProvider = Provider<List<String>>((ref) {
  final summaries =
      ref.watch(countersSummaryProvider).value ?? const <CounterSummary>[];
  final order = ref.watch(tagOrderProvider);
  final counts = <String, int>{};
  for (final s in summaries) {
    final t = s.counter.tag;
    if (t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
  }
  // 存储序中已失效的（分类被删光）跳过；还没入库的新分类按数量降序排在最后，
  // 随后由首页 ensureContains 固化进存储，之后顺序不再变化。
  final ordered = [for (final t in order) if (counts.containsKey(t)) t];
  final unseen = counts.keys.where((t) => !order.contains(t)).toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return [...ordered, ...unseen];
});
