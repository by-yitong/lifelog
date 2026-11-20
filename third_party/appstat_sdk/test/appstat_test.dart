import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appstat_sdk/appstat_sdk.dart';

const uuidPattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

final fakeDevice = <String, Object?>{
  'device_id': 'd-1',
  'platform': 'android',
  'os_version': '14',
  'device_model': 'Pixel 8',
  'app_version': '1.0.0',
  'channel': 'official',
  'sdk_version': '0.1.0',
};

Future<Directory> newCacheDir() => Directory.systemTemp.createTemp('appstat_sdk_test');

List<Map<String, Object?>> readEvents(List<http.Request> requests, [int? index]) {
  final request = requests[index ?? requests.length - 1];
  final payload = jsonDecode(request.body) as Map<String, Object?>;
  return (payload['events'] as List<Object?>).cast<Map<String, Object?>>();
}

Future<void> initWithMock({
  required List<http.Request> requests,
  Directory? cacheDir,
  bool enablePageView = true,
}) async {
  cacheDir ??= await newCacheDir();
  await AppStat.init(
    appKey: '0123456789abcdef',
    serverUrl: 'http://server.local',
    client: MockClient((request) async {
      requests.add(request);
      return http.Response(
        '{"code":0,"message":"ok","data":{"accepted":1,"dropped":0}}',
        200,
      );
    }),
    resolveCacheDir: () async => cacheDir!,
    deviceInfo: () async => fakeDevice,
    enablePageView: enablePageView,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() => AppStat.resetForTest());

  test('init reports app_launch with contract payload', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/api/v1/collect');
    expect(requests.single.headers['X-App-Key'], '0123456789abcdef');

    final payload = jsonDecode(requests.single.body) as Map<String, Object?>;
    expect(payload['device'], fakeDevice);
    final events = readEvents(requests);
    expect(events, hasLength(1));
    expect(events.single['name'], 'app_launch');
    expect(RegExp(uuidPattern).hasMatch(events.single['event_id'] as String), isTrue);
    expect(RegExp(uuidPattern).hasMatch(events.single['session_id'] as String), isTrue);
    expect(events.single['ts'], greaterThan(0));
    expect(events.single['params'], <String, Object?>{});
  });

  test('track keeps the same session id and serializes custom params', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    AppStat.track('buy_click', <String, Object?>{'amount': 6});
    AppStat.track('custom_event');
    await AppStat.flush();

    final launch = (readEvents(requests, 0)).single;
    final batch = readEvents(requests, 1);
    expect(batch, hasLength(2));
    expect(batch[0]['name'], 'buy_click');
    expect(batch[0]['params'], <String, Object?>{'amount': 6});
    expect(batch[1]['name'], 'custom_event');
    expect(batch[0]['session_id'], launch['session_id']);
  });

  test('flushes batch of 20 via threshold', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    for (var i = 0; i < 19; i++) {
      AppStat.track('step', <String, Object?>{'i': i});
    }
    await Future<void>.delayed(Duration.zero);
    expect(requests, hasLength(1));

    AppStat.track('step', <String, Object?>{'i': 19});
    await AppStat.flush();

    expect(requests, hasLength(2));
    final events = readEvents(requests);
    expect(events, hasLength(20));
    expect(AppStat.queueLength.value, 0);
  });

  test('lifecycle background reports session_end, resume rotates session', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    final launch = (readEvents(requests, 0)).single;
    final observer = AppStat.debugLifecycleObserver!;

    observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await AppStat.flush();
    final batch = readEvents(requests);
    expect(batch.single['name'], 'session_end');
    expect((batch.single['params'] as Map<String, Object?>)['duration'], isA<int>());
    expect(batch.single['session_id'], launch['session_id']);

    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    AppStat.track('after_resume');
    await AppStat.flush();
    final afterResume = (readEvents(requests)).single;
    expect(afterResume['session_id'], isNot(launch['session_id']));

    final allLaunches = <Map<String, Object?>>[];
    for (final request in requests) {
      final events = readEvents(requests, requests.indexOf(request));
      allLaunches.addAll(events.where((event) => event['name'] == 'app_launch'));
    }
    expect(allLaunches, hasLength(1));
  });

  test('observer reports page_view with route name or runtimeType', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    final observer = AppStatObserver();
    observer.didPush(
      PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox.shrink(), settings: const RouteSettings(name: '/detail')),
      null,
    );
    observer.didPush(PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox.shrink()), null);
    await AppStat.flush();

    final events = readEvents(requests);
    expect(events, hasLength(2));
    expect(events[0]['name'], 'page_view');
    expect(events[0]['params'], <String, Object?>{'path': '/detail'});
    expect(events[1]['params'], <String, Object?>{'path': 'PageRouteBuilder<void>'});
  });

  test('page_view is skipped when disabled', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests, enablePageView: false);

    final observer = AppStatObserver();
    observer.didPush(
      PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox.shrink(), settings: const RouteSettings(name: '/detail')),
      null,
    );
    await AppStat.flush();

    final events = readEvents(requests);
    expect(events, hasLength(1));
    expect(events.single['name'], 'app_launch');
  });

  test('native crash forwarded through channel becomes crash event', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'appstat_sdk',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('nativeCrash', <String, String>{
          'type': 'android-java',
          'exception': 'java.lang.RuntimeException: boom',
          'stack': 'at com.appstat.Main.main(Main.kt:1)',
        }),
      ),
      (data) {},
    );
    await AppStat.flush();

    final events = readEvents(requests);
    final crash = events.last;
    final crashParams = crash['params'] as Map<String, Object?>;
    expect(crash['name'], 'crash');
    expect(crashParams['type'], 'android-java');
    expect(crashParams['exception'], 'java.lang.RuntimeException: boom');
    expect(crashParams['stack'], contains('Main.kt'));
  });

  test('flutter framework error becomes crash event through installed hooks', () async {
    final requests = <http.Request>[];
    await initWithMock(requests: requests);

    final previous = FlutterError.onError!;
    FlutterError.onError!(FlutterErrorDetails(
      exception: FormatException('bad input\nwhile parsing'),
      stack: StackTrace.current,
      library: 'test',
    ));
    await AppStat.flush();
    FlutterError.onError = previous;

    final events = readEvents(requests);
    final crash = events.last;
    final crashParams = crash['params'] as Map<String, Object?>;
    expect(crash['name'], 'crash');
    expect(crashParams['type'], 'flutter');
    expect(crashParams['exception'], contains('bad input'));
    expect(crashParams['exception'], isNot(contains('while parsing')));
    expect(crashParams['stack'] as String, isNotEmpty);
  });

  test('cached events are merged into the first report after init', () async {
    final cacheDir = await newCacheDir();
    final file = File('${cacheDir.path}/appstat_pending.jsonl');
    await file.writeAsString(
      '${jsonEncode(<String, Object?>{
        'event_id': 'cached-1',
        'name': 'buy_click',
        'ts': 1737280000000,
        'session_id': 'old-session',
        'params': <String, Object?>{'amount': 6},
      })}\n',
    );

    final requests = <http.Request>[];
    await initWithMock(requests: requests, cacheDir: cacheDir);

    expect(requests, hasLength(1));
    final events = readEvents(requests);
    expect(events, hasLength(2));
    expect(events[0]['event_id'], 'cached-1');
    expect(events[1]['name'], 'app_launch');
    expect(await file.exists(), isFalse);
  });

  test('failed flush writes cache file and reports failure', () async {
    final cacheDir = await newCacheDir();
    await AppStat.init(
      appKey: '0123456789abcdef',
      serverUrl: 'http://server.local',
      client: MockClient((request) async => http.Response('down', 500)),
      resolveCacheDir: () async => cacheDir,
      deviceInfo: () async => fakeDevice,
    );

    expect(AppStat.lastReport.value, contains('HTTP 500'));
    final file = File('${cacheDir.path}/appstat_pending.jsonl');
    expect(await file.exists(), isTrue);
    final lines = await file.readAsLines();
    expect(lines, hasLength(1));
    expect((jsonDecode(lines.single) as Map<String, Object?>)['name'], 'app_launch');
  });
}
