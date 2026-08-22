import 'package:flutter/material.dart';

import '../../core/theme/app_metrics.dart';

/// 包裹任意子树：当 [trigger] 变化时播放一次 scale 弹跳。
/// 用于 +1 时数字的反馈；尊重系统"减弱动态效果"。
class BumpOnChange extends StatefulWidget {
  final int trigger;
  final Widget child;

  const BumpOnChange({super.key, required this.trigger, required this.child});

  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void didUpdateWidget(covariant BumpOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      final disabled = MediaQuery.disableAnimationsOf(context);
      disabled ? null : _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Motion.countBump.evaluate(_controller);
        return Transform.scale(scale: t, alignment: Alignment.centerLeft, child: child);
      },
      child: widget.child,
    );
  }
}

/// 首次构建时按 [index] 错峰淡入上移，之后不再动画。
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggerIn({super.key, required this.index, required this.child});

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Motion.easeOut,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(
        Duration(milliseconds: 40 * widget.index.clamp(0, 8)),
        () {
          if (mounted) _controller.forward();
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_fade),
        child: widget.child,
      ),
    );
  }
}
