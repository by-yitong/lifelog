/// 更新流程的 UI：检查 → 更新弹窗（含下载进度）→ 拉起安装。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_typography.dart';
import '../../features/app_state.dart';
import 'app_updater.dart';

const _kLastCheckKey = 'last_update_check_at';

/// 手动检查（设置页入口）。[silent] 为 false 时失败/最新都有提示。
Future<void> checkForUpdate(
  BuildContext context,
  WidgetRef ref, {
  required bool silent,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final localVersion = await currentAppVersion();
    final release = await fetchLatestRelease();
    if (release == null || !isVersionNewer(release.version, localVersion)) {
      if (!silent) {
        messenger.showSnackBar(SnackBar(
          content: Text('已是最新版本 v$localVersion'),
        ));
      }
      return;
    }
    if (!context.mounted) return;
    await showUpdateDialog(context, ref, release);
  } catch (_) {
    if (!silent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检查更新失败，请检查网络后重试')),
      );
    }
  }
}

/// 启动时静默检查：最多每 24 小时联网一次，发现新版弹 SnackBar。
Future<void> maybeAutoCheckUpdate(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final last = prefs.getInt(_kLastCheckKey) ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (now - last < const Duration(hours: 24).inMilliseconds) return;

  try {
    await prefs.setInt(_kLastCheckKey, now);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final localVersion = await currentAppVersion();
    final release = await fetchLatestRelease();
    if (release == null || !isVersionNewer(release.version, localVersion)) {
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text('发现新版本 v${release.version}，点击查看'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: '查看',
        onPressed: () {
          if (context.mounted) showUpdateDialog(context, ref, release);
        },
      ),
    ));
  } catch (_) {}
}

Future<void> showUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  ReleaseInfo release,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UpdateDialog(release: release),
  );
}

class _UpdateDialog extends StatefulWidget {
  final ReleaseInfo release;

  const _UpdateDialog({required this.release});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _downloadAndInstall() async {
    final messenger = ScaffoldMessenger.of(context);
    // 先确认有「安装未知应用」权限，没有就带用户去开
    if (!await canRequestInstall()) {
      await openInstallPermissionSettings();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('请先允许「安装未知应用」，再回来点一次「下载并安装」'),
        duration: Duration(seconds: 4),
      ));
      return;
    }

    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    try {
      final path = await downloadApk(widget.release.apkUrl, (received, total) {
        if (mounted) setState(() => _progress = received / total);
      });
      await installApk(path);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('下载完成，请在系统弹窗里确认安装'),
      ));
    } on SocketException catch (_) {
      _fail('网络连接失败，请重试');
    } catch (_) {
      _fail('下载失败，请重试');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _error = message;
    });
  }

  String get _sizeText {
    final mb = widget.release.apkSizeBytes / (1024 * 1024);
    return mb > 0 ? '${mb.toStringAsFixed(1)} MB' : '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: Text('发现新版本 ${widget.release.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sizeText.isNotEmpty)
            Text('安装包 $_sizeText',
                style: AppTypography.caption(color: colors.inkFaint)),
          const SizedBox(height: Space.sm),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                widget.release.notes.trim().isEmpty
                    ? '本次更新包含体验优化与问题修复。'
                    : widget.release.notes.trim(),
                style: AppTypography.body(color: colors.inkSub),
              ),
            ),
          ),
          if (_downloading) ...[
            const SizedBox(height: Space.lg),
            LinearProgressIndicator(value: _progress.clamp(0, 1)),
            const SizedBox(height: Space.xs),
            Text('${(_progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.caption(color: colors.inkSub)),
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            Text(_error!, style: AppTypography.body(color: colors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('稍后'),
        ),
        FilledButton(
          onPressed: _downloading ? null : _downloadAndInstall,
          child: Text(_downloading ? '下载中…' : '下载并安装'),
        ),
      ],
    );
  }
}
