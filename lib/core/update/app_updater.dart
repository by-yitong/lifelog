/// 应用内更新：检查 GitHub Releases → 下载对应 ABI 的 APK → 拉起系统安装。
///
/// 发布约定：每个 Release 的资产里带上
/// app-arm64-v8a-release.apk / app-armeabi-v7a-release.apk / app-x86_64-release.apk，
/// tag 形如 v1.2.3，正文即更新日志。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _repo = 'by-yitong/lifelog';
const _installerChannel = MethodChannel('dev.lifelog.lifelog/installer');

class ReleaseInfo {
  final String version; // 去掉 v 前缀的语义版本，如 1.2.3
  final String notes;
  final String apkUrl;
  final int apkSizeBytes;
  final String apkName;

  const ReleaseInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.apkSizeBytes,
    required this.apkName,
  });
}

/// ---------- 版本与资产选择（纯函数，便于单测） ----------

/// a 比 b 新则返回 true。按点分数字逐段比较，缺段补 0；解析失败按 0 处理。
bool isVersionNewer(String remote, String local) {
  List<int> parse(String v) => v
      .replaceFirst(RegExp(r'^v'), '')
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((s) => int.tryParse(s) ?? 0)
      .toList();
  final a = parse(remote);
  final b = parse(local);
  final n = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// 从 release 资产里挑出匹配设备 ABI 的 APK。
/// 优先级：arm64-v8a > armeabi-v7a > x86_64。
String? pickApkAsset(Map<String, String> nameByUrl, List<String> abis) {
  const priority = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
  for (final abi in priority) {
    if (!abis.any((a) => a.contains(abi))) continue;
    for (final entry in nameByUrl.entries) {
      if (entry.key.endsWith('-release.apk') && entry.key.contains(abi)) {
        return entry.value;
      }
    }
  }
  return null;
}

/// ---------- GitHub API 与下载 ----------

Future<ReleaseInfo?> fetchLatestRelease({HttpClient? client}) async {
  final ownClient = client ?? HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await ownClient.getUrl(
      Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close();
    if (response.statusCode != 200) return null;
    final body = jsonDecode(await response.transform(utf8.decoder).join())
        as Map<String, dynamic>;
    final assets = (body['assets'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final abis = await deviceAbis;
    final url = pickApkAsset(
      {for (final a in assets) (a['name'] as String? ?? ''): a['browser_download_url'] as String? ?? ''},
      abis,
    );
    if (url == null) return null;
    final match = assets.firstWhere((a) => a['browser_download_url'] == url);

    return ReleaseInfo(
      version: (body['tag_name'] as String? ?? '').trim(),
      notes: body['body'] as String? ?? '',
      apkUrl: url,
      apkSizeBytes: (match['size'] as num?)?.toInt() ?? 0,
      apkName: match['name'] as String? ?? 'update.apk',
    );
  } finally {
    if (client == null) ownClient.close(force: true);
  }
}

Future<String> downloadApk(
  String url,
  void Function(int received, int total)? onProgress,
) async {
  final dir = await getTemporaryDirectory();
  final updatesDir = Directory('${dir.path}/updates');
  if (!updatesDir.existsSync()) updatesDir.createSync(recursive: true);
  final file = File('${updatesDir.path}/lifelog-update.apk');

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('下载失败：HTTP ${response.statusCode}');
    }
    final total = response.contentLength;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in response) {
      received += chunk.length;
      sink.add(chunk);
      onProgress?.call(received, total > 0 ? total : received);
    }
    await sink.flush();
    await sink.close();
    return file.path;
  } finally {
    client.close(force: true);
  }
}

Future<List<String>> get deviceAbis async {
  try {
    final abis = await _installerChannel.invokeListMethod<String>('supportedAbis');
    return abis ?? const ['arm64-v8a'];
  } on PlatformException {
    return const ['arm64-v8a'];
  }
}

/// ---------- 安装权限与拉起安装器 ----------

Future<bool> canRequestInstall() async {
  try {
    return await _installerChannel.invokeMethod<bool>('canRequestInstall') ?? true;
  } on PlatformException {
    return true;
  }
}

Future<void> openInstallPermissionSettings() async {
  try {
    await _installerChannel.invokeMethod('openInstallPermissionSettings');
  } on PlatformException catch (_) {}
}

Future<void> installApk(String path) async {
  await _installerChannel.invokeMethod('installApk', {'path': path});
}

/// 当前安装包的版本名（如 1.1.0），取自 PackageManager。
Future<String> currentAppVersion() async {
  try {
    return await _installerChannel.invokeMethod<String>('appVersion') ?? '0.0.0';
  } catch (_) {
    return '0.0.0';
  }
}

/// 打开系统文件选择器挑一个备份文件，返回其文本内容；取消返回 null。
Future<String?> pickBackupFileText() async {
  try {
    return await _installerChannel.invokeMethod<String>('pickBackupFile');
  } on PlatformException {
    return null;
  }
}
