import 'package:flutter/animation.dart';

/// 4pt 间距刻度 + 圆角 + 动效时长/曲线。
/// UI 里不写魔法数，一律从这里取。
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class RadiusToken {
  static const double card = 20;
  static const double sheet = 28;
  static const double field = 14;
  static const double chip = 10;
  static const double button = 14;
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// 数字 +1 弹跳：scale 1 → 1.12 → 1。
  static final TweenSequence<double> countBump = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.12, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 60,
    ),
  ]);
}
