import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/counter_background.dart';
import '../../app_state.dart';

/// 新建 / 编辑计数器的底部抽屉。
Future<void> showEditSheet(BuildContext context,
    {Counter? existing, String initialTag = ''}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EditSheet(existing: existing, initialTag: initialTag),
  );
}

const _kEmojiChoices = [
  '✨', '💧', '☕', '🍵', '💊', '🦷', '🍎', '🥗',
  '🏃', '💪', '🧘', '😴', '📚', '📝', '💻', '📖',
  '📺', '🎬', '🎧', '🎮', '🎸', '🎨', '🧹', '🍳',
  '🌱', '💰', '📞', '🐾', '🚌', '🛁', '🧴', '🚭',
];

const _kUnitPresets = ['次', '杯', '集', '页', '个', '分钟'];

class _EditSheet extends ConsumerStatefulWidget {
  final Counter? existing;
  final String initialTag;

  const _EditSheet({this.existing, this.initialTag = ''});

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.existing?.unit ?? '次');
  late final TextEditingController _target = TextEditingController(
      text: widget.existing?.dailyTarget?.toString() ?? '');
  late final TextEditingController _tag =
      TextEditingController(text: widget.existing?.tag ?? widget.initialTag);
  late String _emoji = widget.existing?.emoji ?? '✨';

  /// 新建时随机挑一个颜色；编辑时沿用原有颜色。
  late int _colorIndex = widget.existing?.colorIndex ??
      Random().nextInt(kCardPaletteLight.length);
  late int _stepSize = widget.existing?.stepSize ?? 1;
  late bool _hasTarget = widget.existing?.dailyTarget != null;

  /// 背景图：编辑中持有的是相册临时路径或已有常驻路径，
  /// 保存时才真正拷贝进应用目录。
  late String? _bgPath = widget.existing?.bgImagePath;
  bool _saving = false;

  void _rerollColor() =>
      setState(() => _colorIndex = Random().nextInt(kCardPaletteLight.length));

  Future<void> _pickBackground() async {
    final picker = ImagePicker();
    final XFile? image;
    try {
      image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
    } catch (_) {
      return; // 用户取消或系统相册不可用。
    }
    if (image == null) return;
    final picked = image.path;
    setState(() => _bgPath = picked);
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _target.dispose();
    _tag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl,
            Space.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? '新建计数器' : '编辑计数器',
              style: AppTypography.headline(color: colors.ink),
            ),
            const SizedBox(height: Space.xxl),

            // 名称
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              maxLength: 30,
              style: AppTypography.body(color: colors.ink),
              decoration: const InputDecoration(hintText: '叫什么？如：喝水、看动漫'),
            ),
            const SizedBox(height: Space.sm),

            // 标签
            Text('标签（分类，可选）',
                style: AppTypography.caption(color: colors.inkSub)),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _tag,
              maxLength: 10,
              autofillHints: const [],
              style: AppTypography.body(color: colors.ink),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '如：动漫、生活、健康',
              ),
            ),
            const SizedBox(height: Space.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _tag,
              builder: (context, value, _) => Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  ChoiceChip(
                    label: const Text('不分类'),
                    selected: value.text.trim().isEmpty,
                    onSelected: (_) => setState(() => _tag.clear()),
                  ),
                  for (final t in ref.watch(tagListProvider))
                    if (t != value.text.trim())
                      ChoiceChip(
                        label: Text(t),
                        selected: false,
                        onSelected: (_) =>
                            setState(() => _tag.text = t),
                      ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),

            // 图标
            Text('图标', style: AppTypography.caption(color: colors.inkSub)),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final e in _kEmojiChoices)
                  InkWell(
                    borderRadius: BorderRadius.circular(Space.md),
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: e == _emoji ? colors.accentSoft : colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(Space.md),
                        border: e == _emoji
                            ? Border.all(color: colors.accent, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),

            // 颜色
            Row(
              children: [
                Text('颜色', style: AppTypography.caption(color: colors.inkSub)),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(Space.sm),
                  onTap: _rerollColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.sm, vertical: Space.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino_outlined,
                            size: 15, color: colors.accent),
                        const SizedBox(width: Space.xs),
                        Text('随机',
                            style: AppTypography.caption(
                                color: colors.accent)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < colors.cardPalette.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.cardPalette[i].base,
                        shape: BoxShape.circle,
                        border: i == _colorIndex
                            ? Border.all(
                                width: 3, color: colors.cardPalette[i].onContainer)
                            : null,
                      ),
                      child: i == _colorIndex
                          ? Icon(Icons.check,
                              size: 16, color: colors.cardPalette[i].onContainer)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),

            // 背景图（可选）
            _BackgroundPicker(
              path: _bgPath,
              fallbackColor: colors.cardPalette[
                  _colorIndex % colors.cardPalette.length].container,
              onPick: _pickBackground,
              onRemove: () => setState(() => _bgPath = null),
            ),
            const SizedBox(height: Space.lg),

            // 单位
            Text('单位（每次计的量）',
                style: AppTypography.caption(color: colors.inkSub)),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _unit,
              maxLength: 6,
              style: AppTypography.body(color: colors.ink),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '如：次、杯、集、页',
              ),
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              children: [
                for (final u in _kUnitPresets)
                  ChoiceChip(
                    label: Text(u),
                    selected: _unit.text == u,
                    onSelected: (_) => setState(() => _unit.text = u),
                  ),
              ],
            ),

            const SizedBox(height: Space.md),
            Text('每次 + 按钮加多少',
                style: AppTypography.caption(color: colors.inkSub)),
            const SizedBox(height: Space.sm),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('+1')),
                ButtonSegment(value: 2, label: Text('+2')),
                ButtonSegment(value: 5, label: Text('+5')),
                ButtonSegment(value: 10, label: Text('+10')),
              ],
              selected: {_stepSize},
              onSelectionChanged: (s) => setState(() => _stepSize = s.first),
            ),

            const SizedBox(height: Space.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('每日目标', style: AppTypography.title(color: colors.ink)),
              subtitle: Text('首页卡片上显示今日进度',
                  style: AppTypography.caption(color: colors.inkSub)),
              value: _hasTarget,
              onChanged: (v) => setState(() => _hasTarget = v),
            ),
            if (_hasTarget)
              TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTypography.body(color: colors.ink),
                decoration: const InputDecoration(
                    hintText: '每天想达到多少？如：8'),
              ),

            const SizedBox(height: Space.xxl),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.existing == null ? '创建' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final colors = context.appColors;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先给它起个名字吧')),
      );
      return;
    }
    int? target;
    if (_hasTarget) {
      target = int.tryParse(_target.text);
      if (target == null || target <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('每日目标要是一个大于 0 的数字')),
        );
        return;
      }
    }
    setState(() => _saving = true);

    // 背景图落盘：新选的相册临时图拷进应用目录；
    // 被移除的旧图直接删除；未改动的保持原路径。
    final originalBg = widget.existing?.bgImagePath;
    String? finalBg = _bgPath;
    if (finalBg != null && finalBg != originalBg) {
      finalBg = await CounterBackgroundStore.saveFromTemp(
        finalBg,
        oldPath: originalBg,
      );
    } else if (finalBg == null && originalBg != null) {
      await CounterBackgroundStore.delete(originalBg);
    }

    final repo = ref.read(counterRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repo.createCounter(
        CountersCompanion.insert(
          id: const Uuid().v4(),
          name: name,
          emoji: Value(_emoji),
          colorIndex: Value(_colorIndex % colors.cardPalette.length),
          bgImagePath: Value(finalBg),
          unit: Value(_unit.text.trim().isEmpty ? '次' : _unit.text.trim()),
          stepSize: Value(_stepSize),
          dailyTarget: Value(target),
          tag: Value(_tag.text.trim()),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await repo.updateCounter(
        CountersCompanion(
          id: Value(existing.id),
          name: Value(name),
          emoji: Value(_emoji),
          colorIndex: Value(_colorIndex % colors.cardPalette.length),
          bgImagePath: Value(finalBg),
          unit: Value(_unit.text.trim().isEmpty ? '次' : _unit.text.trim()),
          stepSize: Value(_stepSize),
          dailyTarget: Value(target),
          tag: Value(_tag.text.trim()),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

/// 背景图选择区：未设置时是一个虚线占位卡，
/// 已设置时显示预览 + 更换 / 移除。
class _BackgroundPicker extends StatelessWidget {
  final String? path;
  final Color fallbackColor;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _BackgroundPicker({
    required this.path,
    required this.fallbackColor,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasImage = path != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('背景图（可选，比如喜欢的动漫图）',
            style: AppTypography.caption(color: colors.inkSub)),
        const SizedBox(height: Space.sm),
        GestureDetector(
          onTap: onPick,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadiusToken.field),
            child: Container(
              height: hasImage ? 132 : 84,
              width: double.infinity,
              color: hasImage ? null : colors.surfaceAlt,
              foregroundDecoration: hasImage
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(RadiusToken.field),
                      border: Border.all(
                        color: colors.outline,
                        width: 1.2,
                      ),
                    ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(path!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => ColoredBox(
                              color: fallbackColor),
                        ),
                        // 底部渐变让按钮在任何图上都可读
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.45, 1],
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                        Positioned(
                          right: Space.sm,
                          bottom: Space.sm,
                          child: Row(
                            children: [
                              _PickerAction(
                                icon: Icons.auto_awesome_mosaic_outlined,
                                label: '更换',
                                onTap: onPick,
                              ),
                              const SizedBox(width: Space.sm),
                              _PickerAction(
                                icon: Icons.close,
                                label: '移除',
                                onTap: onRemove,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 20, color: colors.inkFaint),
                          const SizedBox(width: Space.sm),
                          Text('从相册选一张图做卡片背景',
                              style:
                                  AppTypography.caption(color: colors.inkFaint)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 背景图预览上的半透明小按钮。
class _PickerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.md, vertical: Space.sm),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .38),
          borderRadius: BorderRadius.circular(Space.lg),
          border: Border.all(
            color: Colors.white.withValues(alpha: .35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: Space.xs),
            Text(label,
                style: AppTypography.caption(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
