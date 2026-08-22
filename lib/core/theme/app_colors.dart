import 'package:flutter/material.dart';

/// 计数器卡片的 8 色色板。
/// 每色四档：container（卡片底）、onContainer（卡上文字/数字）、
/// base（按钮底）、onBase（按钮上的图形）。
class CardPalette {
  final String label;
  final Color container;
  final Color onContainer;
  final Color base;
  final Color onBase;

  const CardPalette({
    required this.label,
    required this.container,
    required this.onContainer,
    required this.base,
    required this.onBase,
  });
}

/// 浅色模式卡片色板（OKLCH 设计后转 sRGB 锁定）。
const List<CardPalette> kCardPaletteLight = [
  // coral 珊瑚
  CardPalette(label: '珊瑚', container: Color(0xFFFFDBCE), onContainer: Color(0xFF851900), base: Color(0xFFEE8266), onBase: Color(0xFF851900)),
  // tangerine 蜜橘
  CardPalette(label: '蜜橘', container: Color(0xFFFFEBC9), onContainer: Color(0xFF833700), base: Color(0xFFEA9941), onBase: Color(0xFF833700)),
  // lime 青柠
  CardPalette(label: '青柠', container: Color(0xFFF2FFD7), onContainer: Color(0xFF456500), base: Color(0xFFA2C758), onBase: Color(0xFF456500)),
  // mint 薄荷
  CardPalette(label: '薄荷', container: Color(0xFFDAFFEF), onContainer: Color(0xFF006547), base: Color(0xFF67C7A4), onBase: Color(0xFF006547)),
  // sky 天蓝
  CardPalette(label: '天蓝', container: Color(0xFFD6F4FF), onContainer: Color(0xFF00547B), base: Color(0xFF6BB5DE), onBase: Color(0xFF00547B)),
  // lavender 薰衣草
  CardPalette(label: '薰衣草', container: Color(0xFFE9DEFF), onContainer: Color(0xFF4F3379), base: Color(0xFFAC91DC), onBase: Color(0xFF4F3379)),
  // rose 玫粉
  CardPalette(label: '玫粉', container: Color(0xFFFFD6E0), onContainer: Color(0xFF7B173B), base: Color(0xFFE47D97), onBase: Color(0xFF7B173B)),
  // sand 暖灰
  CardPalette(label: '暖灰', container: Color(0xFFF2EEE8), onContainer: Color(0xFF544C3F), base: Color(0xFFB2AA9C), onBase: Color(0xFF544C3F)),
];

/// 深色模式卡片色板：底为同色相暗调，文字/数字用亮 base 保证对比。
const List<CardPalette> kCardPaletteDark = [
  CardPalette(label: '珊瑚', container: Color(0xFF440F03), onContainer: Color(0xFFEE8266), base: Color(0xFFEE8266), onBase: Color(0xFF440F03)),
  CardPalette(label: '蜜橘', container: Color(0xFF462000), onContainer: Color(0xFFEA9941), base: Color(0xFFEA9941), onBase: Color(0xFF462000)),
  CardPalette(label: '青柠', container: Color(0xFF293A00), onContainer: Color(0xFFA2C758), base: Color(0xFFA2C758), onBase: Color(0xFF293A00)),
  CardPalette(label: '薄荷', container: Color(0xFF003828), onContainer: Color(0xFF67C7A4), base: Color(0xFF67C7A4), onBase: Color(0xFF003828)),
  CardPalette(label: '天蓝', container: Color(0xFF032D41), onContainer: Color(0xFF6BB5DE), base: Color(0xFF6BB5DE), onBase: Color(0xFF032D41)),
  CardPalette(label: '薰衣草', container: Color(0xFF27193C), onContainer: Color(0xFFAC91DC), base: Color(0xFFAC91DC), onBase: Color(0xFF27193C)),
  CardPalette(label: '玫粉', container: Color(0xFF3E0C1D), onContainer: Color(0xFFE47D97), base: Color(0xFFE47D97), onBase: Color(0xFF3E0C1D)),
  CardPalette(label: '暖灰', container: Color(0xFF2C2822), onContainer: Color(0xFFB2AA9C), base: Color(0xFFB2AA9C), onBase: Color(0xFF2C2822)),
];

/// 全局语义色 token（等价于 hallmark 的 tokens.css :root 块）。
class AppColors {
  final Color paper; // 页面底
  final Color surface; // 卡片/面板底
  final Color surfaceAlt; // 输入框、次级面
  final Color ink; // 主文字
  final Color inkSub; // 次级文字
  final Color inkFaint; // 弱化文字
  final Color accent; // 品牌蜜橘（按钮、强调）
  final Color onAccent; // 品牌色上的文字
  final Color accentSoft; // 品牌浅底
  final Color accentDeep; // 品牌深色文字
  final Color outline; // 描边/分隔
  final Color danger; // 破坏性操作
  final Color success; // 正向增量
  final List<CardPalette> cardPalette;

  const AppColors({
    required this.paper,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSub,
    required this.inkFaint,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.accentDeep,
    required this.outline,
    required this.danger,
    required this.success,
    required this.cardPalette,
  });

  static const AppColors light = AppColors(
    paper: Color(0xFFF9F5EE),
    surface: Color(0xFFFFFDF9),
    surfaceAlt: Color(0xFFF2ECE3),
    ink: Color(0xFF2D241E),
    inkSub: Color(0xFF645850),
    inkFaint: Color(0xFF8D847B),
    accent: Color(0xFFD36B2D),
    onAccent: Color(0xFFFFFDF9),
    accentSoft: Color(0xFFFFDCC2),
    accentDeep: Color(0xFF7D2800),
    outline: Color(0xFFDFD8CE),
    danger: Color(0xFFB3261E),
    success: Color(0xFF456500),
    cardPalette: kCardPaletteLight,
  );

  static const AppColors dark = AppColors(
    paper: Color(0xFF1F1B17),
    surface: Color(0xFF2A2520),
    surfaceAlt: Color(0xFF37302B),
    ink: Color(0xFFEAE6DC),
    inkSub: Color(0xFFABA39A),
    inkFaint: Color(0xFF7A736C),
    accent: Color(0xFFF4A055),
    onAccent: Color(0xFF462000),
    accentSoft: Color(0xFF522D17),
    accentDeep: Color(0xFFFFC48A),
    outline: Color(0xFF49413A),
    danger: Color(0xFFFFB4AB),
    success: Color(0xFFA2C758),
    cardPalette: kCardPaletteDark,
  );
}

/// 在 MaterialApp.builder 注入，任意位置 `context.appColors` 取 token。
class AppColorsScope extends InheritedWidget {
  final AppColors colors;

  const AppColorsScope({
    super.key,
    required this.colors,
    required super.child,
  });

  @override
  bool updateShouldNotify(AppColorsScope oldWidget) =>
      oldWidget.colors != colors;

  static AppColors of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppColorsScope>()!.colors;
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => AppColorsScope.of(this);

  List<CardPalette> get cardPalette => AppColorsScope.of(this).cardPalette;
}
