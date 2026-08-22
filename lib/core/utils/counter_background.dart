import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 卡片背景图的本地文件管理。
///
/// 相册选图拿到的是临时缓存路径，随时可能被系统清掉，
/// 所以保存时统一拷贝进应用私有目录 `counter_bg/`；
/// 更换 / 移除背景时把旧文件一并清理，避免垃圾堆积。
abstract final class CounterBackgroundStore {
  static const String _dirName = 'counter_bg';
  static final RegExp _safeExt = RegExp(r'^[a-z0-9]{1,5}$');

  /// 把临时图片拷贝为常驻文件，返回新路径。
  ///
  /// [oldPath] 是该计数器原来的背景图，拷贝成功后删除。
  static Future<String?> saveFromTemp(
    String tempPath, {
    String? oldPath,
  }) async {
    try {
      final dir = await _ensureDir();
      final dot = tempPath.lastIndexOf('.');
      final rawExt = dot < 0 ? '' : tempPath.substring(dot + 1).toLowerCase();
      final ext = _safeExt.hasMatch(rawExt) ? rawExt : 'jpg';
      final target = File(
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await File(tempPath).copy(target.path);
      await delete(oldPath);
      return target.path;
    } on FileSystemException {
      return null;
    }
  }

  /// 删除背景图文件（不存在或失败都静默处理）。
  static Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // 文件可能已被系统清理，忽略即可。
    }
  }

  static Future<Directory> _ensureDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
