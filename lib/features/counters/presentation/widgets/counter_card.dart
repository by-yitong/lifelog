import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/motion.dart';
import '../../../app_state.dart';

/// 首页计数器卡片：emoji + 名称 + 大号数字 + 今日进度 + 右下角快速 + 按钮。
/// 设置了背景图时，图铺满卡片，文字压在暗部渐变上保证可读。
class CounterCard extends StatefulWidget {
  final CounterSummary summary;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onIncrement;

  const CounterCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onLongPress,
    required this.onIncrement,
  });

  @override
  State<CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<CounterCard> {
  @override
  Widget build(BuildContext context) {
    final counter = widget.summary.counter;
    final palette =
        context.cardPalette[counter.colorIndex % context.cardPalette.length];
    final target = counter.dailyTarget;
    final today = widget.summary.today;
    final progress =
        target != null && target > 0 ? (today / target).clamp(0.0, 1.0) : null;

    final bgPath = counter.bgImagePath;
    final hasBg = bgPath != null && bgPath.isNotEmpty;

    // 有背景图时文字一律用白系 + 轻投影，压得住任何画面。
    final inkStrong = hasBg ? Colors.white : palette.onContainer;
    final inkSoft = hasBg
        ? Colors.white.withValues(alpha: .85)
        : palette.onContainer.withValues(alpha: .65);
    final pinColor = hasBg
        ? Colors.white.withValues(alpha: .85)
        : palette.onContainer.withValues(alpha: .55);
    final artShadow = hasBg
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: .55),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ]
        : null;

    return BumpOnChange(
      trigger: widget.summary.total,
      child: Material(
        color: palette.container,
        borderRadius: BorderRadius.circular(RadiusToken.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(RadiusToken.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasBg)
                Image.file(
                  File(bgPath),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              if (hasBg)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.34, 1],
                      colors: [
                        Colors.black.withValues(alpha: .38),
                        Colors.black.withValues(alpha: .22),
                        Colors.black.withValues(alpha: .66),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶行顶对齐，让 tag 更贴近卡片上缘
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(counter.emoji,
                            style: const TextStyle(fontSize: 24)),
                        if (counter.pinned) ...[
                          const SizedBox(width: Space.sm),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child:
                                Icon(Icons.push_pin, size: 13, color: pinColor),
                          ),
                        ],
                        const Spacer(),
                        // 右上角分类标签
                        if (counter.tag.isNotEmpty)
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(top: 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Space.sm + 2, vertical: 3),
                              decoration: BoxDecoration(
                                color: inkStrong.withValues(alpha: .16),
                                borderRadius:
                                    BorderRadius.circular(Space.xl),
                              ),
                              child: Text(
                                counter.tag,
                                style: AppTypography.caption(color: inkSoft)
                                    .copyWith(
                                        fontSize: 11, shadows: artShadow),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      counter.name,
                      style: AppTypography.title(color: inkStrong)
                          .copyWith(shadows: artShadow),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        BumpOnChange(
                          key: ValueKey('num-${counter.id}'),
                          trigger: today,
                          child: Text('${widget.summary.total}',
                              style: AppTypography.numDisplay(
                                      size: 36, color: inkStrong)
                                  .copyWith(shadows: artShadow)),
                        ),
                        const SizedBox(width: Space.xs),
                        Text(counter.unit,
                            style: AppTypography.caption(color: inkSoft)
                                .copyWith(shadows: artShadow)),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    // 右侧给 + 按钮留位，进度条不穿到按钮下面
                    Padding(
                      padding: const EdgeInsets.only(right: 52),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (progress != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Space.xs),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: Motion.normal,
                                curve: Motion.easeOut,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor:
                                      inkStrong.withValues(alpha: .15),
                                  valueColor: AlwaysStoppedAnimation(inkStrong),
                                ),
                              ),
                            ),
                          if (progress != null)
                            const SizedBox(height: Space.xs),
                          Text(
                            progress != null
                                ? '今日 $today/$target'
                                : (today > 0 ? '今日 +$today' : '今天还没记'),
                            style: AppTypography.caption(color: inkSoft)
                                .copyWith(shadows: artShadow),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: Space.md,
                bottom: Space.md,
                child: _PlusButton(
                  base: hasBg
                      ? Colors.white.withValues(alpha: .22)
                      : palette.base,
                  onBase: hasBg ? Colors.white : palette.onBase,
                  outlined: hasBg,
                  step: counter.stepSize,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onIncrement();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusButton extends StatefulWidget {
  final Color base;
  final Color onBase;
  final bool outlined;
  final int step;
  final VoidCallback onPressed;

  const _PlusButton({
    required this.base,
    required this.onBase,
    this.outlined = false,
    required this.step,
    required this.onPressed,
  });

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: Motion.fast,
        curve: Motion.easeOut,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.base,
            shape: BoxShape.circle,
            border: widget.outlined
                ? Border.all(
                    color: Colors.white.withValues(alpha: .5), width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              '+${widget.step}',
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: widget.step > 1 ? 14 : 22,
                height: 1,
                color: widget.onBase,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
