import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Bangumi（bgm.tv）上的一条动漫条目，附封面图地址。
class BangumiSubject {
  final String id;
  final String name;
  final String originName;
  final String coverUrl;

  const BangumiSubject({
    required this.id,
    required this.name,
    required this.originName,
    required this.coverUrl,
  });
}

/// 解析 /search/subject 的响应体（{"results":n,"list":[...]}），可独立单测。
List<BangumiSubject> parseBangumiSearch(String body) {
  final raw = jsonDecode(body);
  if (raw is! Map<String, dynamic>) return const [];
  final list = raw['list'];
  if (list is! List) return const [];

  final subjects = <BangumiSubject>[];
  for (final item in list) {
    if (item is! Map<String, dynamic>) continue;
    final id = item['id'];
    if (id is! String && id is! int) continue;
    final images = item['images'];
    // 优先原图 large：medium 只有 100px 宽，铺卡片背景会糊
    final cover = images is Map<String, dynamic>
        ? (images['large'] ??
              images['common'] ??
              images['medium'] ??
              images['small'])
        : null;
    if (cover is! String || cover.isEmpty) continue;

    final origin = (item['name'] as String?)?.trim() ?? '';
    final cn = (item['name_cn'] as String?)?.trim() ?? '';
    subjects.add(BangumiSubject(
      id: '$id',
      name: cn.isNotEmpty ? cn : origin,
      originName: origin,
      // 老接口给的是 http:// 明文链接，Android 禁明文，统一升级 https
      coverUrl: cover.replaceFirst('http://', 'https://'),
    ));
  }
  return subjects;
}

/// Bangumi 开放接口：搜索动漫条目、下载封面图。
abstract final class BangumiApi {
  /// Bangumi 希望调用方带可识别的 User-Agent。
  /// 注意必须是纯 ASCII：HTTP 头不允许中文，否则 dart:io 直接抛 FormatException。
  static const _ua = 'lifelog/1.2.0 (Android; dev.lifelog.lifelog)';

  /// 按关键词搜动漫（type 2 = 动画），返回带封面的条目。
  ///
  /// 用老版 /search/subject 接口：v0 搜索对中文标题的匹配很差，
  /// 搜「完美世界」连本体都搜不到，老接口则是精确命中排最前。
  static Future<List<BangumiSubject>> searchAnime(
    String keyword, {
    int limit = 24,
    HttpClient? client,
  }) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return const [];
    // 关键词手动编码一次后用 Uri.parse（Uri.https 会把已编码的 %XX 再转义一遍）
    final uri = Uri.parse(
        'https://api.bgm.tv/search/subject/${Uri.encodeComponent(kw)}'
        '?type=2&max_results=$limit');
    final ownClient = client ??
        HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await ownClient.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _ua);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Bangumi 搜索失败：HTTP ${response.statusCode}');
      }
      return parseBangumiSearch(body);
    } finally {
      if (client == null) ownClient.close(force: true);
    }
  }

  /// 下载封面图原始字节（medium 规格，约 800px 宽）。
  static Future<Uint8List> downloadCover(
    String url, {
    HttpClient? client,
  }) async {
    final ownClient = client ??
        HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await ownClient.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, _ua);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('封面下载失败：HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      if (client == null) ownClient.close(force: true);
    }
  }
}
