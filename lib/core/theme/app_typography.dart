import 'package:flutter/material.dart';

/// 字体体系：数字用 Baloo 2（可变字体，wght 800）做展示字重，
/// 中文正文走系统 Noto Sans CJK，不做多余声明。
abstract final class AppTypography {
  static const String displayFamily = 'Baloo2';

  /// 大号计数数字（卡片、详情页主数字）。
  static TextStyle numDisplay({
    double size = 40,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: const [FontVariation('wght', 800)],
      fontSize: size,
      height: 1.05,
      letterSpacing: -0.5,
      color: color,
    );
  }

  /// 页面大标题。
  static TextStyle headline({required Color color}) => TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      );

  /// 卡片/列表标题。
  static TextStyle title({required Color color}) => TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 正文。
  static TextStyle body({required Color color}) => TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// 辅助说明。
  static TextStyle caption({required Color color}) => TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
