import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_typography.dart';

/// 首页底部的悬浮毛玻璃标签栏：左侧标签 chips（可横滑），右侧固定 + 按钮。
///
/// 真·iOS 液态玻璃质感的关键（缺一样就会"看着像实心色块"）：
/// 1. BackdropFilter 模糊 + 饱和度提升（compose 两个 ImageFilter）；
/// 2. 面板填充必须够透（~45%），让模糊后的内容透出来；
/// 3. 白色发丝描边 + 顶部 1px 高光，模拟玻璃边缘的镜面反光。
///
/// 选中态是一枚会"滑动跟随"的高亮胶囊：切换标签时从旧位置平滑滑到新位置，
/// 而不是原地变色。胶囊放在滚动内容坐标系里，横滑列表时始终贴着自己的标签。
class FrostedTagBar extends StatefulWidget {
  final List<String> pages; // ['全部', tag1, ...]
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const FrostedTagBar({
    super.key,
    required this.pages,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  State<FrostedTagBar> createState() => _FrostedTagBarState();
}

class _FrostedTagBarState extends State<FrostedTagBar> {
  final ScrollController _scrollController = ScrollController();

  /// 滚动内容层（Stack）的 key：测量 chip 时作为参照祖先，
  /// 这样拿到的是内容坐标系里的位置，与屏幕位置和滚动偏移都无关。
  final GlobalKey _contentKey = GlobalKey();
  final Map<int, GlobalKey> _chipKeys = {};
  Map<int, Rect> _chipRects = {};
  int? _pressedChip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChips());
  }

  @override
  void didUpdateWidget(covariant FrostedTagBar old) {
    super.didUpdateWidget(old);
    // 标签集合变化（增删分类 / 重命名）后重新测量各 chip 的几何信息
    if (!listEquals(old.pages, widget.pages)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureChips());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 测量每个 chip 相对滚动内容层（Stack）的矩形，供滑动胶囊定位。
  void _measureChips() {
    if (!mounted) return;
    final contentCtx = _contentKey.currentContext;
    if (contentCtx == null) return;
    final contentBox = contentCtx.findRenderObject();
    if (contentBox is! RenderBox) return;

    final rects = <int, Rect>{};
    for (var i = 0; i < widget.pages.length; i++) {
      final ctx = _chipKeys[i]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      // 直接取相对内容层的坐标，天然排除屏幕位置与滚动偏移
      final topLeft = box.localToGlobal(Offset.zero, ancestor: contentBox);
      rects[i] = topLeft & box.size;
    }
    if (rects.isEmpty) return;
    setState(() => _chipRects = rects);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Apple 液态玻璃：着色器真折射（边缘弯折背景）+ 镜面高光。
    // 模糊必须很小（重度磨砂会把折射的边缘弯折糊掉，看起来就只是磨砂），
    // 折射带宽 + 色散才有演示里那种"玻璃边"。
    return LiquidGlassLens(
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(cornerRadius: 24),
        blur: 3,
        saturation: 1.2,
        refractionIndex: 1.18,
        refractionWidth: 22,
        dispersion: 0.5,
        color: isDark
            ? Colors.white.withValues(alpha: .05)
            : Colors.white.withValues(alpha: .16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildChips(colors)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: _AddButton(onAdd: widget.onAdd),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(AppColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Stack(
        key: _contentKey,
        children: [
          // 滑动高亮胶囊：染色玻璃（半透品牌色 + 发丝描边），不是实心色块
          if (_chipRects.containsKey(widget.selectedIndex))
            AnimatedPositioned(
              key: ValueKey('pill-${widget.pages.length}'),
              duration: Motion.normal,
              curve: Motion.easeInOut,
              left: _chipRects[widget.selectedIndex]!.left,
              top: _chipRects[widget.selectedIndex]!.top,
              width: _chipRects[widget.selectedIndex]!.width,
              height: _chipRects[widget.selectedIndex]!.height,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: isDark ? .40 : .28),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .30),
                    width: .8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: .22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          // chips 本体
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.pages.length; i++)
                _buildChip(colors, i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(AppColors colors, int i) {
    final selected = i == widget.selectedIndex;
    final pressed = _pressedChip == i;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 每个 chip 一个 key，用于测量自身几何给滑动胶囊用
    _chipKeys[i] ??= GlobalKey();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressedChip = i),
      onTapCancel: () => setState(() => _pressedChip = null),
      onTapUp: (_) {
        setState(() => _pressedChip = null);
        widget.onSelect(i);
      },
      onTap: () {},
      child: AnimatedScale(
        scale: pressed ? .94 : 1,
        duration: Motion.fast,
        curve: Motion.easeOut,
        child: Padding(
          key: _chipKeys[i],
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: AnimatedDefaultTextStyle(
            duration: Motion.normal,
            curve: Motion.easeOut,
            style: AppTypography.title(
              color: selected
                  ? (isDark ? Colors.white : colors.accentDeep)
                  : colors.inkSub,
            ).copyWith(fontSize: 13),
            child: Text(widget.pages[i]),
          ),
        ),
      ),
    );
  }
}

/// 右侧 + 按钮：品牌色渐变圆 + 同色柔光，按压有弹性。
class _AddButton extends StatefulWidget {
  final VoidCallback onAdd;

  const _AddButton({required this.onAdd});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onAdd,
      child: AnimatedScale(
        scale: _pressed ? .88 : 1,
        duration: Motion.fast,
        curve: Motion.easeOut,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.accent.withValues(alpha: .92),
                colors.accent,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .30),
              width: .8,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: .35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.add, color: colors.onAccent, size: 19),
        ),
      ),
    );
  }
}
