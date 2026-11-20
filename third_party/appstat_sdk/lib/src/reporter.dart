import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Reporter {
  Reporter({
    required this.appKey,
    required this.serverUrl,
    required this.client,
    required Future<Directory> Function() cacheDirResolver,
    this.batchThreshold = 20,
    this.flushInterval = const Duration(seconds: 30),
    this.maxCacheBytes = 2 * 1024 * 1024,
  }) : _resolveCacheDir = cacheDirResolver;

  static const String _cacheFileName = 'appstat_pending.jsonl';

  final String appKey;
  final String serverUrl;
  final http.Client client;
  final Future<Directory> Function() _resolveCacheDir;
  final int batchThreshold;
  final Duration flushInterval;
  final int maxCacheBytes;

  final ValueNotifier<int> queueLength = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastReport = ValueNotifier<String?>(null);

  final List<Map<String, Object?>> _queue = <Map<String, Object?>>[];
  Map<String, Object?>? _device;
  Future<void> _tail = Future<void>.value();
  Timer? _timer;

  void setDevice(Map<String, Object?> device) {
    _device = device;
  }

  void enqueue(Map<String, Object?> event) {
    _queue.add(event);
    queueLength.value = _queue.length;
    if (_queue.length >= batchThreshold) {
      unawaited(flush());
    }
  }

  void startPeriodicFlush() {
    _timer ??= Timer.periodic(flushInterval, (_) => unawaited(flush()));
  }

  Future<void> dispose() {
    _timer?.cancel();
    _timer = null;
    return Future<void>.value();
  }

  Future<void> clearCache() async {
    _queue.clear();
    queueLength.value = 0;
    try {
      final file = await _cacheFile();
      if (await file.exists()) await file.delete();
    } on Exception {
      return;
    }
  }

  Future<void> flush() {
    final task = _tail.then((_) => _drain());
    _tail = task.then<void>((_) {}, onError: (Object error) {});
    return task;
  }

  Future<void> loadCachedEvents() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final content = await file.readAsString();
      await file.delete();
      for (final line in content.split('\n')) {
        final decoded = _tryDecodeEvent(line);
        if (decoded != null) _queue.add(decoded);
      }
      queueLength.value = _queue.length;
    } on Exception {
      return;
    }
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      await _postBatch(_queue.sublist(0));
    }
  }

  Future<void> _postBatch(List<Map<String, Object?>> batch) async {
    final count = batch.length;
    String summary;
    try {
      final response = await client.post(
        Uri.parse('$serverUrl/api/v1/collect'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-App-Key': appKey,
        },
        body: jsonEncode(<String, Object?>{'device': _device, 'events': batch}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        summary = _successSummary(response);
      } else {
        final cached = await _cacheEvents(batch);
        summary = cached
            ? 'HTTP ${response.statusCode}, events cached'
            : 'HTTP ${response.statusCode}';
      }
    } catch (error) {
      final cached = await _cacheEvents(batch);
      summary = cached
          ? 'flush failed: $error, events cached'
          : 'flush failed: $error';
    }
    _queue.removeRange(0, count);
    queueLength.value = _queue.length;
    lastReport.value = summary;
  }

  Future<bool> _cacheEvents(List<Map<String, Object?>> events) async {
    try {
      final file = await _cacheFile();
      final existing =
          await file.exists() ? await file.readAsLines() : <String>[];
      final lines = <String>[
        ...existing.where((line) => line.trim().isNotEmpty),
        ...events.map(jsonEncode),
      ];
      var size = lines.fold<int>(0, (total, line) => total + line.length + 1);
      while (size > maxCacheBytes && lines.isNotEmpty) {
        size -= lines.removeAt(0).length + 1;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(lines.isEmpty ? '' : '${lines.join('\n')}\n');
      return true;
    } on Exception {
      return false;
    }
  }

  Future<File> _cacheFile() async {
    final dir = await _resolveCacheDir();
    return File('${dir.path}${Platform.pathSeparator}$_cacheFileName');
  }

  Map<String, Object?>? _tryDecodeEvent(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  String _successSummary(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final data = decoded['data'];
        if (data is Map && data['accepted'] is num) {
          return 'ok: ${data['accepted']} accepted (HTTP ${response.statusCode})';
        }
      }
    } on FormatException {
      return 'ok (HTTP ${response.statusCode})';
    }
    return 'ok (HTTP ${response.statusCode})';
  }
}
