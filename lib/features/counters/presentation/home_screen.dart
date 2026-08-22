import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/update/update_flow.dart';
import '../../../shared/widgets/frosted_tag_bar.dart';
import '../../../shared/widgets/motion.dart';
import '../../app_state.dart';
import '../../counter_detail/presentation/detail_screen.dart';
import '../../counter_edit/presentation/edit_sheet.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import 'widgets/counter_card.dart';
import 'widgets/empty_state.dart';

/// 首页：问候 + 今日汇总 + 搜索/排序 +
/// 按标签分页的计数器网格（左右滑动切换）+ 底部悬浮毛玻璃标签栏。
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _query = '';
  int _page = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // 启动后静默检查应用内更新（最多 24 小时一次）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeAutoCheckUpdate(context, ref);
    });
  }

  // ---------- 顶栏/底栏随滚动隐藏 ----------
  // controller: 1 = 显示，0 = 隐藏
  late final AnimationController _chromeController = AnimationController(
    vsync: this,
    duration: Motion.normal,
    value: 1,
  );
  late final Animation<double> _chromeFade =
      CurvedAnimation(parent: _chromeController, curve: Motion.easeInOut);
  bool _chromeHidden = false;

  // 双击返回退出
  DateTime? _lastBackAt;

  void _hideChrome() {
    if (_chromeHidden) return;
    setState(() => _chromeHidden = true);
    _chromeController.reverse();
  }

  void _showChrome() {
    if (!_chromeHidden) return;
    setState(() => _chromeHidden = false);
    _chromeController.forward();
  }

  bool _onScrollNotification(ScrollNotification n) {
    // 只响应竖直滚动（PageView 翻页是横向的，天然被过滤掉）。
    // 注意不能检查 depth：网格在 PageView 内层，depth 恒 ≥ 1。
    if (n.metrics.axis != Axis.vertical) return false;
    // 上滑（往列表深处看）→ 收起；下滑（往回翻）→ 立刻展开
    if (n is ScrollUpdateNotification && (n.scrollDelta ?? 0) != 0) {
      if (n.scrollDelta! > 0) {
        _hideChrome();
      } else {
        _showChrome();
      }
    }
    return false;
  }

  // 点击 +1：记一笔并可撤销
  Future<void> _increment(CounterSummary s) async {
    HapticFeedback.lightImpact();
    final repo = ref.read(counterRepositoryProvider);
    final entry = await repo.addEntry(
      counterId: s.counter.id,
      delta: s.counter.stepSize,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('已记一笔 ${s.counter.name} +${entry.delta}${s.counter.unit}'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => repo.deleteEntry(entry),
        ),
      ));
  }

  @override
  void dispose() {
    _chromeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final summariesAsync = ref.watch(countersSummaryProvider);
    final tags = ref.watch(tagListProvider);
    final pages = ['全部', ...tags];

    // 标签列表变化时，防止当前页越界。
    if (_page >= pages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.jumpToPage(0);
        setState(() => _page = 0);
      });
    }

    final allSummaries = summariesAsync.value ?? const <CounterSummary>[];
    final todayTotal =
        allSummaries.fold<int>(0, (acc, s) => acc + s.today);

    // 新出现的分类固化到 Tab 顺序末尾（"新建的分类排在最后"）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tagOrderProvider.notifier).ensureContains(tags);
    });

    // 首页拦截系统返回：第一次提示“再按一次退出”，2 秒内再按才真正退出。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_chromeHidden) {
          _showChrome(); // 界面藏着时先唤出顶栏底栏
          return;
        }
        final now = DateTime.now();
        if (_lastBackAt == null ||
            now.difference(_lastBackAt!) > const Duration(seconds: 2)) {
          _lastBackAt = now;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('再按一次返回键退出'),
            duration: Duration(milliseconds: 1600),
          ));
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部问候 + 搜索：上滑隐藏、下拉唤出
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _chromeFade,
                  alignment: Alignment.bottomCenter,
                  child: FadeTransition(
                    opacity: _chromeFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(colors, todayTotal,
                            summariesAsync.hasValue),
                        _buildSearchSortRow(colors),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: summariesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('出错了：$e',
                          style: AppTypography.body(color: colors.danger)),
                    ),
                    data: (_) => Stack(
                      children: [
                        Positioned.fill(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: pages.length,
                            onPageChanged: (i) =>
                                setState(() => _page = i),
                            itemBuilder: (context, i) => _buildPage(
                                pages[i], i == 0, allSummaries),
                          ),
                        ),
                        Positioned(
                          left: Space.xl,
                          right: Space.xl,
                          bottom: Space.lg,
                          height: 64,
                          // 底栏跟随顶栏一起隐藏/唤出
                          child: IgnorePointer(
                            ignoring: _chromeHidden,
                            child: AnimatedBuilder(
                              animation: _chromeFade,
                              builder: (context, _) {
                                final hidden = 1 - _chromeFade.value;
                                return Opacity(
                                  opacity: _chromeFade.value,
                                  child: Transform.translate(
                                    offset: Offset(0, hidden * 120),
                                    child: FrostedTagBar(
                                      pages: pages,
                                      selectedIndex:
                                          _page.clamp(0, pages.length - 1),
                                      onSelect: (i) {
                                        setState(() => _page = i);
                                        _pageController.animateToPage(
                                          i,
                                          duration: Motion.normal,
                                          curve: Motion.easeInOut,
                                        );
                                      },
                                      onAdd: () => showEditSheet(
                                        context,
                                        initialTag:
                                            _page == 0 ? '' : pages[_page],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部问候区（日期 + 今日汇总 + 设置入口）。
  Widget _buildHeader(AppColors colors, int todayTotal, bool hasValue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xs, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
                  style: AppTypography.caption(color: colors.inkFaint),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  hasValue
                      ? (todayTotal > 0 ? '今天已记 $todayTotal 次' : '今天想记点什么？')
                      : '',
                  style: AppTypography.headline(color: colors.ink),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '统计',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
            icon: Icon(Icons.insights, color: colors.inkSub),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: Icon(Icons.tune, color: colors.inkSub),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(String tag, bool isAll, List<CounterSummary> summaries) {
    final filtered = summaries.where((s) {
      if (!isAll && s.counter.tag != tag) return false;
      if (_query.isNotEmpty &&
          !s.counter.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      // 搜索无结果
      if (_query.isNotEmpty) {
        return Center(
          child: Text('没有匹配「$_query」的计数器',
              style: AppTypography.body(color: context.appColors.inkSub)),
        );
      }
      if (isAll) {
        return EmptyState(
          onCreatePreset: (p) => _createPreset(p),
          onCreateCustom: () => showEditSheet(context),
        );
      }
      // 该分类为空
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📂', style: TextStyle(fontSize: 48)),
            const SizedBox(height: Space.md),
            Text('「$tag」还没有计数器',
                style: AppTypography.title(color: context.appColors.inkSub)),
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: () => showEditSheet(context, initialTag: tag),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建到这个分类'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Space.md,
        crossAxisSpacing: Space.md,
        childAspectRatio: 0.82,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final s = filtered[i];
        return StaggerIn(
          index: i,
          child: CounterCard(
            summary: s,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailScreen(counterId: s.counter.id),
              ),
            ),
            onLongPress: () => _showCardMenu(s),
            onIncrement: () => _increment(s),
          ),
        );
      },
    );
  }

  Widget _buildSearchSortRow(AppColors colors) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              // 关闭系统自动填充，避免 Android 14+ 的字段橙色描边
              autofillHints: const [],
              decoration: InputDecoration(
                hintText: '搜索计数器',
                prefixIcon: Icon(Icons.search, color: colors.inkFaint),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          IconButton(
            tooltip: '排序方式',
            onPressed: _showSortSheet,
            icon: Icon(Icons.swap_vert, color: colors.inkSub),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    final current = ref.read(settingsProvider).sortMode;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.sm),
              child: Text('排序方式',
                  style: AppTypography.title(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            for (final mode in SortMode.values)
              ListTile(
                title: Text(mode.label),
                trailing: mode == current
                    ? Icon(Icons.check, color: context.appColors.accent)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setSortMode(mode);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    );
  }

  void _showCardMenu(CounterSummary s) {
    final colors = context.appColors;
    final repo = ref.read(counterRepositoryProvider);
    final counter = s.counter;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(counter.pinned ? '取消置顶' : '置顶'),
              onTap: () {
                Navigator.pop(sheetContext);
                repo.setPinned(counter.id, !counter.pinned);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(sheetContext);
                showEditSheet(context, existing: counter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('归档（从首页隐藏）'),
              onTap: () {
                Navigator.pop(sheetContext);
                repo.setArchived(counter.id, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已归档「${counter.name}」'),
                    action: SnackBarAction(
                      label: '撤销',
                      onPressed: () => repo.setArchived(counter.id, false),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text('删除', style: TextStyle(color: colors.danger)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(counter);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Counter counter) {
    final colors = context.appColors;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除计数器？'),
        content: Text('「${counter.name}」及其全部记录将被删除，无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(counterRepositoryProvider).deleteCounter(counter.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPreset(PresetCounter p) async {
    await ref.read(counterRepositoryProvider).createCounter(
          CountersCompanion.insert(
            id: const Uuid().v4(),
            name: p.name,
            emoji: Value(p.emoji),
            colorIndex: Value(p.colorIndex),
            unit: Value(p.unit),
            dailyTarget: Value(p.dailyTarget),
            tag: Value(p.tag),
            createdAt: DateTime.now(),
          ),
        );
  }
}
