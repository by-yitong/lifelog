import 'package:flutter/material.dart';

import '../../../../core/theme/app_metrics.dart';
import '../../../../core/theme/app_typography.dart';

/// 首页空状态：说明 + 建议快捷创建。
class EmptyState extends StatelessWidget {
  final void Function(PresetCounter preset) onCreatePreset;
  final VoidCallback onCreateCustom;

  const EmptyState({
    super.key,
    required this.onCreatePreset,
    required this.onCreateCustom,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Space.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧮', style: TextStyle(fontSize: 56)),
            const SizedBox(height: Space.lg),
            Text('还没有计数器', style: AppTypography.headline(color: colors.onSurface)),
            const SizedBox(height: Space.sm),
            Text(
              '记录一件事情做了多少次，\n点一下就算一次。',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: Space.xxl),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final p in PresetCounter.presets)
                  ActionChip(
                    label: Text('${p.emoji} ${p.name}'),
                    onPressed: () => onCreatePreset(p),
                  ),
              ],
            ),
            const SizedBox(height: Space.xl),
            TextButton.icon(
              onPressed: onCreateCustom,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('自定义新建'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 建议预设：一键生成一个计数器。
class PresetCounter {
  final String name;
  final String emoji;
  final int colorIndex;
  final String unit;
  final int? dailyTarget;
  final String tag;

  const PresetCounter(this.name, this.emoji, this.colorIndex,
      {this.unit = '次', this.dailyTarget, this.tag = ''});

  static const presets = [
    PresetCounter('喝水', '💧', 4, unit: '杯', dailyTarget: 8, tag: '生活'),
    PresetCounter('看动漫', '📺', 5, unit: '集', tag: '动漫'),
    PresetCounter('扫地', '🧹', 3, tag: '生活'),
    PresetCounter('喝咖啡', '☕', 1, unit: '杯', dailyTarget: 2, tag: '生活'),
    PresetCounter('运动', '🏃', 2, tag: '健康'),
  ];
}
