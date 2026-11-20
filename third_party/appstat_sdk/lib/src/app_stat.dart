import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'crash_hooks.dart';
import 'device_info_collector.dart';
import 'event.dart';
import 'native_crash_channel.dart';
import 'reporter.dart';
import 'session_tracker.dart';

class AppStat {
  AppStat._();

  static Reporter? _reporter;
  static SessionTracker? _sessions;
  static WidgetsBindingObserver? _lifecycleObserver;
  static CrashHooks? _crashHooks;
  static bool _pageViewEnabled = true;
  static bool _crashEnabled = true;

  static ValueListenable<int> get queueLength =>
      _reporter?.queueLength ?? ValueNotifier<int>(0);

  static ValueListenable<String?> get lastReport =>
      _reporter?.lastReport ?? ValueNotifier<String?>(null);

  static Future<void> init({
    required String appKey,
    String serverUrl = 'http://stat.phpcurl.cn',
    String channel = 'official',
    bool enablePageView = true,
    bool enableCrash = true,
    @visibleForTesting http.Client? client,
    @visibleForTesting Future<Directory> Function()? resolveCacheDir,
    @visibleForTesting Future<Map<String, Object?>> Function()? deviceInfo,
  }) async {
    if (_reporter != null) return;
    _pageViewEnabled = enablePageView;
    _crashEnabled = enableCrash;

    final reporter = Reporter(
      appKey: appKey,
      serverUrl: serverUrl,
      client: client ?? http.Client(),
      cacheDirResolver: resolveCacheDir ?? getApplicationDocumentsDirectory,
    );
    _reporter = reporter;

    await reporter.loadCachedEvents();
    reporter.setDevice(
      await (deviceInfo?.call() ?? DeviceInfoCollector.collect(channel: channel)),
    );

    _sessions = SessionTracker(sessionEndHandler: _enqueueSessionEnd);
    _track('app_launch');

    if (enableCrash) {
      NativeCrashChannel.onCrash = _enqueueCrash;
      NativeCrashChannel.ensureListening();
      _crashHooks = CrashHooks(onCrash: _enqueueCrash)..install();
    }

    _lifecycleObserver = _AppStatLifecycleObserver(_sessions!.handleLifecycle);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    reporter.startPeriodicFlush();
    await reporter.flush();
  }

  static void track(String name, [Map<String, Object?>? params]) {
    _track(name, params);
  }

  static Future<void> flush() => _reporter?.flush() ?? Future<void>.value();

  @visibleForTesting
  static WidgetsBindingObserver? get debugLifecycleObserver => _lifecycleObserver;

  @visibleForTesting
  @visibleForTesting
  static Future<void> resetForTest() => disable();

  /// 停止采集并清除待上报数据；再次 init 可重新开启。
  static Future<void> disable() async {
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    _crashHooks?.uninstall();
    NativeCrashChannel.onCrash = null;
    NativeCrashChannel.resetForTest();
    await _reporter?.clearCache();
    await _reporter?.dispose();
    _reporter = null;
    _sessions = null;
    _lifecycleObserver = null;
    _crashHooks = null;
  }

  static void _track(String name, [Map<String, Object?>? params]) {
    final sessions = _sessions;
    final reporter = _reporter;
    if (sessions == null || reporter == null) return;
    if (name == 'page_view' && !_pageViewEnabled) return;
    reporter.enqueue(
      StatEvent(
        name: name,
        params: params ?? const <String, Object?>{},
        sessionId: sessions.sessionId,
      ).toJson(),
    );
  }

  static void _enqueueSessionEnd(int durationSeconds) {
    final sessions = _sessions;
    final reporter = _reporter;
    if (sessions == null || reporter == null) return;
    reporter.enqueue(
      StatEvent(
        name: 'session_end',
        params: <String, Object?>{'duration': durationSeconds},
        sessionId: sessions.sessionId,
      ).toJson(),
    );
  }

  static void _enqueueCrash({
    required String type,
    required String exception,
    required String stack,
  }) {
    final reporter = _reporter;
    if (reporter == null || !_crashEnabled) return;
    reporter.enqueue(
      StatEvent(
        name: 'crash',
        params: <String, Object?>{
          'type': type,
          'exception': exception,
          'stack': stack,
        },
        sessionId: _sessions?.sessionId ?? '',
      ).toJson(),
    );
    unawaited(reporter.flush());
  }
}

class _AppStatLifecycleObserver extends WidgetsBindingObserver {
  _AppStatLifecycleObserver(this.onStateChanged);

  final void Function(AppLifecycleState state) onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
